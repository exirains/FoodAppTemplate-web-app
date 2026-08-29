import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:babka/l10n/app_localizations.dart';
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
import '../auth/profile_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/widgets/sangak_back_handler.dart';
import 'delivery_provider.dart';

class DeliveryDashboardScreen extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends ConsumerState<DeliveryDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(deliveryDashboardProvider);
    final availableCount = state.availableOrders.length;
    final myTasksCount = state.myTasks.length;

    return RoleGuard(
      allowedRoles: const ['admin', 'delivery'],
      child: SangakBackHandler(
        child: Scaffold(
          backgroundColor: BabkaColors.background,
          body: Column(
            children: [
              // Custom Top App Bar
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Text(l10n.deliveryPanel, style: BabkaTypography.h2(context)),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          final userProfile = ref.read(userProfileProvider).asData?.value;
                          if (userProfile != null) RoleSwitcher.show(context, userProfile.role);
                        },
                        icon: const Icon(Icons.swap_horiz_rounded),
                      ),
                      IconButton(
                        onPressed: () => context.push('/delivery/history'),
                        icon: const Icon(Icons.history_rounded, color: BabkaColors.primary),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Alert Bar
              if (availableCount > 0)
                GestureDetector(
                  onTap: () {
                    _tabController.animateTo(0);
                    _scrollToTop();
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: BabkaColors.primary,
                      borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
                      boxShadow: BabkaDimens.shadowMedium,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${l10n.newLabel.toUpperCase()} ($availableCount)',
                          style: BabkaTypography.title(context).copyWith(color: Colors.white, fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

              // Tabs
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: BabkaColors.border, width: 1)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: BabkaColors.primary,
                  unselectedLabelColor: BabkaColors.inkLight,
                  indicatorColor: BabkaColors.primary,
                  indicatorWeight: 3,
                  labelStyle: BabkaTypography.title(context).copyWith(fontSize: 14),
                  tabs: [
                    _buildTab(l10n.available.toUpperCase(), availableCount),
                    _buildTab(l10n.myTasks.toUpperCase(), myTasksCount),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(state.availableOrders, l10n.noOrdersForPickup, isPool: true),
                    _buildOrderList(state.myTasks, l10n.noActiveDeliveries, isPool: false),
                  ],
                ),
              ),
            ],
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: BabkaColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BabkaColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, String emptyMsg, {required bool isPool}) {
    final state = ref.watch(deliveryDashboardProvider);
    final l10n = AppLocalizations.of(context);

    if (state.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return Center(
        child: SangakEmptyState(
          title: l10n.allCaughtUp, 
          message: emptyMsg, 
          icon: Icons.delivery_dining_outlined,
        ),
      );
    }

    return ListView.separated(
      controller: isPool ? _scrollController : null,
      padding: const EdgeInsets.all(24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _DeliveryOrderCard(order: orders[index], isPool: isPool),
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

  Future<void> _handlePickup() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isUpdating = true);
    try {
      await ref.read(deliveryDashboardProvider.notifier).pickupOrder(widget.order.id);
      if (mounted) {
        BabkaToast.show(context, l10n.invitationCodeApplied); // Reusing a toast or just success
        context.push('/delivery/${widget.order.id}');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('orderAlreadyAssigned')) {
          msg = l10n.orderAlreadyAssigned;
        }
        BabkaToast.show(context, msg);
      }
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
      BabkaToast.show(context, AppLocalizations.of(context).locationError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userId = ref.watch(authProvider).value?.id;
    final isAssignedToMe = widget.order.assignedDeliveryPerson == userId && userId != null;
    final showAssignedBadge = isAssignedToMe && widget.order.status == OrderStatus.ready;
    final showPickedUpBadge = isAssignedToMe && widget.order.status == OrderStatus.outForDelivery;

    final addr = widget.order.addressSnapshot;
    final itemsCount = widget.order.items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
    final statusColor = _getStatusColor(widget.order.status);

    return Container(
      decoration: BoxDecoration(
        color: BabkaColors.surface,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        boxShadow: BabkaDimens.shadowLow,
        border: Border.all(color: BabkaColors.border.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        child: Column(
          children: [
            Container(height: 4, color: statusColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAssignedBadge || showPickedUpBadge) ...[
                    Row(
                      children: [
                        Icon(
                          showPickedUpBadge ? Icons.inventory_2_rounded : Icons.local_shipping_rounded,
                          size: 16,
                          color: showPickedUpBadge ? BabkaColors.primary : BabkaColors.info,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (showPickedUpBadge ? l10n.pickedUp : l10n.assignedToYou).toUpperCase(),
                          style: BabkaTypography.caption(context).copyWith(
                            color: showPickedUpBadge ? BabkaColors.primary : BabkaColors.info,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.order.orderNumber, style: BabkaTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: BabkaColors.inkLight)),
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
                        child: Icon(
                          widget.isPool ? Icons.inventory_2_outlined : Icons.location_on_rounded, 
                          color: statusColor, 
                          size: 24
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${addr['district']}, ${addr['city']}', style: BabkaTypography.h3(context).copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(addr['address'] ?? '', style: BabkaTypography.bodySmall(context).copyWith(height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetaItem(context, Icons.shopping_bag_outlined, l10n.itemsCount(itemsCount)),
                      const Spacer(),
                      Text(
                        SangakNumberFormatter.formatCurrency(widget.order.totalPrice, ref.watch(localeProvider).languageCode), 
                        style: BabkaTypography.title(context).copyWith(color: BabkaColors.primary, fontWeight: FontWeight.w900)
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: widget.isPool 
                          ? BabkaButton.primary(
                              label: l10n.pickupOrder, 
                              onPressed: () => BabkaConfirmDialog.show(
                                context, 
                                title: l10n.confirmPickup, 
                                message: l10n.confirmPickupMessage, 
                                confirmLabel: l10n.pickupOrder, 
                                cancelLabel: l10n.cancel, 
                                onConfirm: _handlePickup,
                              ), 
                              isLoading: _isUpdating,
                            )
                          : BabkaButton.primary(
                              label: l10n.openDetails, 
                              onPressed: () => context.push('/delivery/${widget.order.id}'),
                            ),
                      ),
                      if (!widget.isPool) ...[
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(color: BabkaColors.surface, borderRadius: BorderRadius.circular(BabkaDimens.radiusM), border: Border.all(color: BabkaColors.border), boxShadow: BabkaDimens.shadowLow),
                          child: IconButton(onPressed: _openNavigation, icon: const Icon(Icons.map_rounded, color: BabkaColors.primary), visualDensity: VisualDensity.compact),
                        ),
                      ],
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
        Icon(icon, size: 14, color: BabkaColors.inkLight),
        const SizedBox(width: 4),
        Text(label, style: BabkaTypography.caption(context).copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ready: return BabkaColors.info;
      case OrderStatus.outForDelivery: return BabkaColors.primary;
      case OrderStatus.delivered: return BabkaColors.success;
      default: return BabkaColors.inkLight;
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BabkaDimens.radiusPill), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(status.localizedLabel(l10n).toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ready: return BabkaColors.info;
      case OrderStatus.outForDelivery: return BabkaColors.primary;
      case OrderStatus.delivered: return BabkaColors.success;
      default: return BabkaColors.inkLight;
    }
  }
}
