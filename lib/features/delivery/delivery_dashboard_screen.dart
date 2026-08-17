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
import '../../shared/widgets/sangak_empty_states.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';
import '../auth/profile_provider.dart';
import '../admin/admin_provider.dart';
import '../../shared/widgets/sangak_back_handler.dart';

final availableOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  ref.watch(authProvider);
  final repo = ref.read(sangakOrderRepositoryProvider);
  return repo.watchAvailableOrders().handleError((error) {
    debugPrint('🚨 Realtime Available Orders Error: $error');
    if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
      Future.delayed(const Duration(seconds: 2), () => ref.invalidateSelf());
    }
  });
});

final myActiveDeliveriesProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value([]);
  final repo = ref.read(sangakOrderRepositoryProvider);
  return repo.watchDriverOrders(user.id).handleError((error) {
    debugPrint('🚨 Realtime Active Deliveries Error: $error');
    if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
      Future.delayed(const Duration(seconds: 2), () => ref.invalidateSelf());
    }
  });
});

final deliveryOrderDetailProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  ref.watch(authProvider);
  final repo = ref.read(sangakOrderRepositoryProvider);
  return SupabaseService.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .asyncMap((_) async => await repo.getOrderById(orderId))
      .handleError((error) {
        debugPrint('🚨 Realtime Order Detail Error: $error');
        if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
          Future.delayed(const Duration(seconds: 2), () => ref.invalidateSelf());
        }
      });
});

final incomingOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  ref.watch(authProvider);
  final repo = ref.read(sangakOrderRepositoryProvider);
  return repo.watchIncomingOrders().handleError((error) {
    debugPrint('🚨 Realtime Incoming Orders Error: $error');
    if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
      Future.delayed(const Duration(seconds: 2), () => ref.invalidateSelf());
    }
  });
});

final myDeliveryHistoryProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value([]);
  final repo = ref.read(sangakOrderRepositoryProvider);
  return repo.watchDriverHistory(user.id).handleError((error) {
    debugPrint('🚨 Realtime Delivery History Error: $error');
    if (error.toString().contains('InvalidJWTToken') || error.toString().contains('expired')) {
      Future.delayed(const Duration(seconds: 2), () => ref.invalidateSelf());
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final availableCount = ref.watch(availableOrdersProvider).value?.length ?? 0;
    final incomingCount = ref.watch(incomingOrdersProvider).value?.length ?? 0;
    final activeCount = ref.watch(myActiveDeliveriesProvider).value?.length ?? 0;

    return RoleGuard(
      allowedRoles: const ['admin', 'delivery'],
      child: SangakBackHandler(
        child: Scaffold(
          backgroundColor: SangakColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 80,
                backgroundColor: SangakColors.background,
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
                title: Text(l10n.deliveryPanel, style: SangakTypography.h2(context)),
                actions: [
                  IconButton(
                    onPressed: () {
                      final userProfile = ref.read(userProfileProvider).asData?.value;
                      if (userProfile != null) RoleSwitcher.show(context, userProfile.role);
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, color: SangakColors.ink),
                  ),
                  IconButton(
                    onPressed: () => context.push('/delivery/history'),
                    icon: const Icon(Icons.history_rounded, color: SangakColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: SangakColors.border, width: 1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelColor: SangakColors.primary,
                      unselectedLabelColor: SangakColors.inkLight,
                      indicatorColor: SangakColors.primary,
                      indicatorWeight: 3,
                      labelStyle: SangakTypography.title(context).copyWith(fontSize: 13),
                      tabs: [
                        _buildTab(l10n.available, availableCount),
                        _buildTab(l10n.statusPreparing, incomingCount),
                        _buildTab(l10n.myTasks, activeCount),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPoolTab(availableOrdersProvider, l10n.noOrdersForPickup),
                _buildPoolTab(incomingOrdersProvider, l10n.noOrdersToPrepare, isPool: false, showOnly: true),
                _buildPoolTab(myActiveDeliveriesProvider, l10n.noActiveDeliveries, isPool: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: SangakColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: SangakColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPoolTab(ProviderBase<AsyncValue<List<OrderModel>>> provider, String emptyMsg, {bool isPool = true, bool showOnly = false}) {
    final ordersAsync = ref.watch(provider);
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      color: SangakColors.primary,
      child: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.infinity,
                  child: Center(
                    child: SangakEmptyState(title: l10n.allCaughtUp, message: emptyMsg, icon: Icons.delivery_dining_outlined),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _DeliveryOrderCard(order: orders[index], isPool: isPool, showOnly: showOnly),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorOccurred)),
      ),
    );
  }
}

class _DeliveryOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final bool isPool;
  final bool showOnly;
  const _DeliveryOrderCard({required this.order, required this.isPool, this.showOnly = false});

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
        final success = await ref.read(sangakOrderRepositoryProvider).assignDeliveryPerson(widget.order.id, user.id, ifUnassigned: true);
        if (!success) {
          if (mounted) SangakToast.show(context, l10n.orderAlreadyAssigned);
          ref.invalidate(availableOrdersProvider);
          return;
        }
      }
      await ref.read(sangakOrderRepositoryProvider).updateOrderStatus(orderId: widget.order.id, status: newStatus, changedBy: user.id);
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(myActiveDeliveriesProvider);
      if (mounted) {
        SangakToast.show(context, '${l10n.status}: ${newStatus.localizedLabel(l10n)}');
        if (widget.isPool) context.push('/delivery/${widget.order.id}');
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
        if (await canLaunchUrl(webUrl)) await launchUrl(webUrl);
      }
    } else if (mounted) {
      SangakToast.show(context, AppLocalizations.of(context).locationError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addr = widget.order.addressSnapshot;
    final itemsCount = widget.order.items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
    final statusColor = _getStatusColor(widget.order.status);

    return Container(
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        boxShadow: SangakDimens.shadowLow,
        border: Border.all(color: SangakColors.border.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        child: Column(
          children: [
            Container(height: 4, color: statusColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.order.orderNumber, style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: SangakColors.inkLight)),
                      _StatusChip(status: widget.order.status, l10n: l10n),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.location_on_rounded, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${addr['district']}, ${addr['city']}', style: SangakTypography.h3(context).copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(addr['address'] ?? '', style: SangakTypography.bodySmall(context).copyWith(height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetaItem(context, Icons.shopping_bag_outlined, l10n.itemsCount(itemsCount)),
                      const SizedBox(width: 16),
                      _buildMetaItem(context, Icons.payments_outlined, widget.order.paymentMethod.toUpperCase()),
                      const Spacer(),
                      Text(SangakNumberFormatter.formatCurrency(widget.order.totalPrice, ref.watch(localeProvider).languageCode), style: SangakTypography.title(context).copyWith(color: SangakColors.primary, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  if (addr['delivery_note'] != null && addr['delivery_note'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: SangakColors.warning.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: SangakColors.warning.withValues(alpha: 0.1))),
                      child: Row(
                        children: [
                          const Icon(Icons.sticky_note_2_outlined, size: 14, color: SangakColors.warning),
                          const SizedBox(width: 8),
                          Expanded(child: Text(addr['delivery_note'], style: SangakTypography.caption(context).copyWith(color: SangakColors.secondary, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: widget.showOnly
                            ? SangakButton.outlined(label: l10n.openDetails, onPressed: () => context.push('/delivery/${widget.order.id}'))
                            : widget.isPool 
                                ? SangakButton.primary(
                                    label: l10n.pickupOrder, 
                                    onPressed: () => SangakConfirmDialog.show(context, title: l10n.confirmPickup, message: l10n.confirmPickupMessage, confirmLabel: l10n.pickupOrder, cancelLabel: l10n.cancel, onConfirm: () => _updateStatus(OrderStatus.outForDelivery)), 
                                    isLoading: _isUpdating)
                                : SangakButton.primary(label: l10n.openDetails, onPressed: () => context.push('/delivery/${widget.order.id}')),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(color: SangakColors.surface, borderRadius: BorderRadius.circular(SangakDimens.radiusM), border: Border.all(color: SangakColors.border), boxShadow: SangakDimens.shadowLow),
                        child: IconButton(onPressed: _openNavigation, icon: const Icon(Icons.map_rounded, color: SangakColors.primary), visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: SangakColors.inkLight),
        const SizedBox(width: 4),
        Text(label, style: SangakTypography.caption(context).copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ready: return SangakColors.info;
      case OrderStatus.outForDelivery: return SangakColors.primary;
      case OrderStatus.delivered: return SangakColors.success;
      case OrderStatus.preparing:
      case OrderStatus.confirmed: return SangakColors.accent;
      default: return SangakColors.inkLight;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  final AppLocalizations l10n;
  const _StatusChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(SangakDimens.radiusPill), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(status.localizedLabel(l10n).toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ready: return SangakColors.info;
      case OrderStatus.outForDelivery: return SangakColors.primary;
      case OrderStatus.delivered: return SangakColors.success;
      case OrderStatus.preparing:
      case OrderStatus.confirmed: return SangakColors.accent;
      default: return SangakColors.inkLight;
    }
  }
}
