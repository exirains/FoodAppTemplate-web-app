import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/role_switcher.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/sangak_dialogs.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';
import '../auth/profile_provider.dart';
import '../admin/admin_provider.dart';

final availableOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  // Watch auth state to automatically refresh the stream when the session changes
  ref.watch(authProvider);
  
  final repo = ref.read(orderRepositoryProvider);
  return repo.watchAvailableOrders().handleError((error) {
    debugPrint('🚨 Realtime Available Orders Error: $error');
    if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
      // Force a tiny delay then refresh the whole provider state
      Future.delayed(const Duration(seconds: 2), () {
        ref.invalidateSelf();
      });
    }
  });
});

final myActiveDeliveriesProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value([]);
  
  final repo = ref.read(orderRepositoryProvider);
  return repo.watchDriverOrders(user.id).handleError((error) {
    debugPrint('🚨 Realtime Active Deliveries Error: $error');
    if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
      Future.delayed(const Duration(seconds: 2), () {
        ref.invalidateSelf();
      });
    }
  });
});

final deliveryOrderDetailProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  // Ensure we have a fresh session
  ref.watch(authProvider);
  
  final repo = ref.read(orderRepositoryProvider);
  return SupabaseService.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .asyncMap((_) async => await repo.getOrderById(orderId))
      .handleError((error) {
        debugPrint('🚨 Realtime Order Detail Error: $error');
        if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
          Future.delayed(const Duration(seconds: 2), () {
            ref.invalidateSelf();
          });
        }
      });
});

class DeliveryDashboardScreen extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends ConsumerState<DeliveryDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch profile to keep stream active and roles synced
    ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin', 'delivery'],
      child: Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(
          title: Text(l10n.deliveryPanel),
          actions: [
            IconButton(
              onPressed: () {
                final l10n = AppLocalizations.of(context);
                final userProfile = ref.read(userProfileProvider).asData?.value;
                if (userProfile != null) {
                  RoleSwitcher.show(context, userProfile.role);
                } else {
                  SangakToast.show(context, l10n.syncingPermissions);
                  // Invalidate to force a fresh fetch if null
                  ref.invalidate(userProfileProvider);
                }
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            IconButton(
              onPressed: () {
                ref.invalidate(availableOrdersProvider);
                ref.invalidate(myActiveDeliveriesProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.available),
              Tab(text: l10n.myTasks),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAvailablePool(l10n),
            _buildMyTasks(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePool(AppLocalizations l10n) {
    final ordersAsync = ref.watch(availableOrdersProvider);
    return ordersAsync.when(
      data: (orders) => orders.isEmpty 
          ? _buildEmptyState(l10n.noOrdersForPickup)
          : ListView.separated(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) => _DeliveryOrderCard(order: orders[index], isPool: true),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMyTasks(AppLocalizations l10n) {
    final ordersAsync = ref.watch(myActiveDeliveriesProvider);
    return ordersAsync.when(
      data: (orders) => orders.isEmpty 
          ? _buildEmptyState(l10n.noActiveDeliveries)
          : ListView.separated(
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) => _DeliveryOrderCard(order: orders[index], isPool: false),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delivery_dining_outlined, size: 64, color: SangakColors.border),
          const SizedBox(height: 16),
          Text(message, style: SangakTypography.bodySmall(context)),
        ],
      ),
    );
  }
}

class _DeliveryOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final bool isPool;
  const _DeliveryOrderCard({required this.order, required this.isPool});

  @override
  ConsumerState<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends ConsumerState<_DeliveryOrderCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _isUpdating = true);
    try {
      if (widget.isPool) {
        // Driver takes the order from the pool. Use atomic check to prevent race conditions.
        final success = await ref.read(orderRepositoryProvider).assignDeliveryPerson(
          widget.order.id, 
          user.id, 
          ifUnassigned: true,
        );

        if (!success) {
          if (mounted) SangakToast.show(context, l10n.orderAlreadyAssigned);
          ref.invalidate(availableOrdersProvider);
          return;
        }
      }

      await ref.read(orderRepositoryProvider).updateOrderStatus(
        orderId: widget.order.id,
        status: newStatus,
        changedBy: user.id,
      );
      
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(myActiveDeliveriesProvider);
      
      if (mounted) {
        SangakToast.show(context, '${l10n.status}: ${newStatus.localizedLabel(l10n)}');
        if (widget.isPool) {
           // If just picked up, automatically open details
           context.push('/delivery/${widget.order.id}');
        }
      }
    } catch (e) {
      if (mounted) SangakToast.show(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _openNavigation() async {
    final addr = widget.order.addressSnapshot;
    final double? lat = addr['latitude'];
    final double? lon = addr['longitude'];

    if (lat != null && lon != null) {
      final url = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl);
        }
      }
    } else {
      if (mounted) SangakToast.show(context, AppLocalizations.of(context).locationError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addr = widget.order.addressSnapshot;
    final itemsCount = widget.order.items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(widget.order.orderNumber, style: SangakTypography.h3(context)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.itemsCount(itemsCount),
                          style: SangakTypography.title(context).copyWith(
                            color: SangakColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openNavigation,
                    icon: const Icon(Icons.directions_outlined, color: SangakColors.info, size: 32),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: SangakColors.inkLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${addr['district']}, ${addr['city']}',
                          style: SangakTypography.title(context).copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      '${addr['street']}, No:${addr['building_number']}',
                      style: SangakTypography.bodySmall(context),
                    ),
                  ),
                  if (addr['delivery_note'] != null && addr['delivery_note'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SangakColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${l10n.noteLabel}${addr['delivery_note']}',
                        style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.secondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: widget.isPool 
                  ? SangakButton.primary(
                      label: AppLocalizations.of(context).pickupOrder,
                      backgroundColor: SangakColors.primary,
                      onPressed: () {
                        final l10n = AppLocalizations.of(context);
                        SangakConfirmDialog.show(
                          context,
                          title: l10n.confirmPickup,
                          message: l10n.confirmPickupMessage,
                          confirmLabel: l10n.pickupOrder,
                          cancelLabel: l10n.cancel,
                          onConfirm: () => _updateStatus(OrderStatus.outForDelivery),
                        );
                      },
                      isLoading: _isUpdating,
                    )
                  : SangakButton.outlined(
                      label: AppLocalizations.of(context).openDetails,
                      onPressed: () => context.push('/delivery/${widget.order.id}'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
