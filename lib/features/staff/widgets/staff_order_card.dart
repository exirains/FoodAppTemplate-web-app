import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../models/order.dart';
import '../../../shared/widgets/sangak_button.dart';
import '../../../shared/utils/sangak_toast.dart';
import '../../../shared/widgets/cancel_order_dialog.dart';
import '../../auth/auth_provider.dart';
import '../../admin/admin_provider.dart';

class StaffOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final bool isNew;

  const StaffOrderCard({
    super.key,
    required this.order,
    this.isNew = false,
  });

  @override
  ConsumerState<StaffOrderCard> createState() => _StaffOrderCardState();
}

class _StaffOrderCardState extends ConsumerState<StaffOrderCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;
    
    // Guardrail: Staff can only set these specific statuses
    final allowedStatuses = [
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.cancelled,
    ];

    if (!allowedStatuses.contains(newStatus)) {
      if (mounted) SangakToast.show(context, 'Unauthorized status change', icon: Icons.error_outline);
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final l10n = AppLocalizations.of(context);
      await ref.read(sangakOrderRepositoryProvider).updateOrderStatus(
            orderId: widget.order.id,
            status: newStatus,
            changedBy: user.id,
            role: 'staff',
          );
      
      if (mounted) {
        SangakToast.show(context, '${l10n.status}: ${newStatus.localizedLabel(l10n)}');
      }
    } catch (e) {
      if (mounted) SangakToast.show(context, 'Error updating status', icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = widget.order.items ?? [];
    final isWide = MediaQuery.of(context).size.width > 600;
    
    // Responsive Dimensions
    final padding = isWide ? 20.0 : 24.0;
    final actionHeight = isWide ? 64.0 : 72.0;
    final titleSize = isWide ? 20.0 : 24.0;
    final itemTitleSize = isWide ? 18.0 : 22.0;

    Widget card = Container(
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowMedium,
        border: Border.all(
          color: widget.isNew ? SangakColors.warning : SangakColors.border,
          width: widget.isNew ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.orderNumber,
                      style: SangakTypography.h2(context).copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: titleSize,
                      ),
                    ),
                    if (widget.isNew)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SangakColors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.newLabel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  _formatTime(widget.order.createdAt, l10n),
                  style: SangakTypography.h3(context).copyWith(
                    color: SangakColors.primary,
                    fontSize: isWide ? 16 : 20,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Items
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: SangakColors.ink.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: SangakTypography.title(context).copyWith(
                            color: SangakColors.ink,
                            fontWeight: FontWeight.bold,
                            fontSize: isWide ? 14 : 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.nameSnapshot,
                          style: SangakTypography.h3(context).copyWith(
                            fontSize: itemTitleSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Actions
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                // Quick Cancel
                SizedBox(
                  width: actionHeight,
                  height: actionHeight,
                  child: SangakButton.outlined(
                    label: '',
                    icon: Icons.close_rounded,
                    foregroundColor: SangakColors.error,
                    borderColor: SangakColors.error,
                    onPressed: () => CancelOrderDialog.show(
                      context,
                      onConfirm: (reason) => _updateStatus(OrderStatus.cancelled),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Primary Action
                Expanded(
                  child: SizedBox(
                    height: actionHeight,
                    child: _buildActionButton(l10n),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isNew) {
      return card.animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).shimmer(
        duration: 2.seconds,
        // ignore: deprecated_member_use
        color: SangakColors.warning.withOpacity(0.1),
      ).scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.01, 1.01),
        duration: 1.seconds,
        curve: Curves.easeInOut,
      );
    }

    return card;
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return SangakButton.primary(
          label: l10n.acceptOrder.toUpperCase(),
          onPressed: () => _updateStatus(OrderStatus.confirmed),
          isLoading: _isUpdating,
        );
      case OrderStatus.confirmed:
        return SangakButton.primary(
          label: l10n.startPreparing.toUpperCase(),
          backgroundColor: SangakColors.info,
          onPressed: () => _updateStatus(OrderStatus.preparing),
          isLoading: _isUpdating,
        );
      case OrderStatus.preparing:
        return SangakButton.primary(
          label: l10n.markReady.toUpperCase(),
          backgroundColor: SangakColors.success,
          onPressed: () => _updateStatus(OrderStatus.ready),
          isLoading: _isUpdating,
        );
      case OrderStatus.ready:
        return SangakButton.outlined(
          label: l10n.waitingForPickup.toUpperCase(),
          onPressed: null,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${l10n.minutesShort} ${l10n.ago}';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
