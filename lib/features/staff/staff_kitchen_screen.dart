import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/role_switcher.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/reject_order_dialog.dart';
import '../auth/auth_provider.dart';
import '../auth/profile_provider.dart';
import '../admin/admin_provider.dart';

class StaffKitchenScreen extends ConsumerWidget {
  const StaffKitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    // Watch profile to keep stream active and roles synced
    ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin', 'staff'],
      child: Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(
          title: Text(l10n.kitchenPanel),
          actions: [
            IconButton(
              onPressed: () {
                final userProfile = ref.read(userProfileProvider).asData?.value;
                if (userProfile != null) {
                  RoleSwitcher.show(context, userProfile.role);
                } else {
                  SangakToast.show(context, 'Syncing permissions...');
                  ref.invalidate(userProfileProvider);
                }
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            IconButton(
              onPressed: () {
                ref.invalidate(adminOrdersProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: ordersAsync.when(
          data: (orders) {
            final kitchenOrders = orders.where((o) => 
              o.status == OrderStatus.pending || 
              o.status == OrderStatus.confirmed || 
              o.status == OrderStatus.preparing
            ).toList();
  
            if (kitchenOrders.isEmpty) {
              return _buildEmptyState(context, l10n);
            }
  
            return ListView.separated(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              itemCount: kitchenOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                return _KitchenOrderCard(order: kitchenOrders[index], l10n: l10n);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bakery_dining_outlined, size: 64, color: SangakColors.border),
          const SizedBox(height: 16),
          Text(l10n.allCaughtUp, style: SangakTypography.h3(context)),
          Text(l10n.noOrdersToPrepare, style: SangakTypography.bodySmall(context)),
        ],
      ),
    );
  }
}

class _KitchenOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final AppLocalizations l10n;
  const _KitchenOrderCard({required this.order, required this.l10n});

  @override
  ConsumerState<_KitchenOrderCard> createState() => _KitchenOrderCardState();
}

class _KitchenOrderCardState extends ConsumerState<_KitchenOrderCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
        orderId: widget.order.id,
        status: newStatus,
        changedBy: user.id,
      );
      // Force UI refresh
      ref.invalidate(adminOrdersProvider);
      if (mounted) {
        SangakToast.show(context, '${widget.l10n.status}: ${newStatus.label}');
      }
    } catch (e) {
      if (mounted) SangakToast.show(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.items ?? [];

    return Container(
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowMedium,
        border: Border.all(
          color: widget.order.status == OrderStatus.pending 
              ? SangakColors.warning.withValues(alpha: 0.5) 
              : SangakColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.order.orderNumber, style: SangakTypography.h3(context)),
                Text(
                  _formatTime(widget.order.createdAt),
                  style: SangakTypography.title(context).copyWith(color: SangakColors.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Items
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SangakColors.ink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: SangakTypography.title(context).copyWith(fontSize: 18, color: SangakColors.ink),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.nameSnapshot,
                          style: SangakTypography.h3(context).copyWith(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: widget.order.status == OrderStatus.pending
                ? Row(
                    children: [
                      // 30% REJECT
                      SizedBox(
                        width: 100,
                        child: SangakButton.outlined(
                          label: widget.l10n.reject,
                          foregroundColor: SangakColors.error,
                          borderColor: SangakColors.error.withValues(alpha: 0.3),
                          onPressed: () => RejectOrderDialog.show(
                            context, 
                            onConfirm: () => _updateStatus(OrderStatus.cancelled),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 70% ACCEPT
                      Expanded(
                        child: SangakButton.primary(
                          label: widget.l10n.acceptAndConfirm,
                          onPressed: () => _updateStatus(OrderStatus.confirmed),
                          isLoading: _isUpdating,
                        ),
                      ),
                    ],
                  )
                : widget.order.status == OrderStatus.confirmed
                    ? SangakButton.primary(
                        label: widget.l10n.startPreparing,
                        backgroundColor: SangakColors.info,
                        onPressed: () => _updateStatus(OrderStatus.preparing),
                        isLoading: _isUpdating,
                      )
                    : SangakButton.primary(
                        label: widget.l10n.markAsReady,
                        backgroundColor: SangakColors.success,
                        onPressed: () => _updateStatus(OrderStatus.ready),
                        isLoading: _isUpdating,
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
