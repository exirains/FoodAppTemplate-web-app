import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/sangak_button.dart';
import 'admin_provider.dart';

final _timeFilterProvider = StateProvider<bool>((ref) => false); // false = All Time (User Preference)

class OrderManagementScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const OrderManagementScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final isTodayOnly = ref.watch(_timeFilterProvider);
    final l10n = AppLocalizations.of(context);

    return RoleGuard(
      allowedRoles: const ['admin', 'staff'],
      child: Scaffold(
        backgroundColor: BabkaColors.background,
        appBar: AppBar(
          title: Text(l10n.manageOrders),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<bool>(
                value: isTodayOnly,
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, color: BabkaColors.primary),
                items: [
                  DropdownMenuItem(value: true, child: Text(l10n.today)),
                  DropdownMenuItem(value: false, child: Text(l10n.allTime)),
                ],
                onChanged: (val) {
                  if (val != null) ref.read(_timeFilterProvider.notifier).state = val;
                },
              ),
            ),
          ],
          bottom: _CustomTabBar(
            tabController: _tabController,
            orders: ordersAsync.value ?? [],
            isTodayOnly: isTodayOnly,
          ),
        ),
        body: ordersAsync.when(
          data: (allOrders) {
            final orders = isTodayOnly 
                ? allOrders.where((o) {
                    final now = DateTime.now();
                    final localCreated = o.createdAt.toLocal();
                    return localCreated.year == now.year && 
                           localCreated.month == now.month && 
                           localCreated.day == now.day;
                  }).toList()
                : allOrders;

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(orders.where((o) => o.status == OrderStatus.pending).toList()),
                _buildOrderList(orders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing).toList()),
                _buildOrderList(orders.where((o) => o.status == OrderStatus.ready).toList()),
                _buildOrderList(orders.where((o) => o.status == OrderStatus.outForDelivery).toList()),
                _buildOrderList(orders.where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled).toList()),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: BabkaColors.error),
                  const SizedBox(height: 16),
                  Text('Error loading orders: $e', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  BabkaButton.primary(
                    label: 'Retry', 
                    width: 150,
                    onPressed: () => ref.invalidate(adminOrdersProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    final l10n = AppLocalizations.of(context);
    if (orders.isEmpty) {
      return Center(child: Text(l10n.noOrdersInStatus));
    }

    final lang = ref.watch(localeProvider).languageCode;

    return ListView.separated(
      padding: const EdgeInsets.all(BabkaDimens.spacing24),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order, lang: lang);
      },
    );
  }
}

class _CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<OrderModel> orders;
  final bool isTodayOnly;

  const _CustomTabBar({required this.tabController, required this.orders, required this.isTodayOnly});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final filteredOrders = isTodayOnly 
        ? orders.where((o) {
            final now = DateTime.now();
            final localCreated = o.createdAt.toLocal();
            return localCreated.year == now.year && 
                   localCreated.month == now.month && 
                   localCreated.day == now.day;
          }).toList()
        : orders;

    final newCount = filteredOrders.where((o) => o.status == OrderStatus.pending).length;
    final prepCount = filteredOrders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing).length;
    final readyCount = filteredOrders.where((o) => o.status == OrderStatus.ready).length;
    final shippingCount = filteredOrders.where((o) => o.status == OrderStatus.outForDelivery).length;
    final doneCount = filteredOrders.where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled).length;

    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: BabkaColors.primary,
      unselectedLabelColor: BabkaColors.inkLight,
      indicatorColor: BabkaColors.primary,
      indicatorWeight: 3,
      labelStyle: BabkaTypography.title(context).copyWith(fontSize: 13),
      tabs: [
        _buildTab(l10n.statusPending, newCount),
        _buildTab(l10n.statusPreparing, prepCount),
        _buildTab(l10n.statusReady, readyCount),
        _buildTab(l10n.outForDelivery, shippingCount),
        _buildTab(l10n.statusDone, doneCount),
      ],
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
                color: BabkaColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 9, 
                  fontWeight: FontWeight.w900,
                  color: BabkaColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String lang;

  const _OrderCard({required this.order, required this.lang});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customerName = order.userProfile?['full_name'] ?? l10n.guest;
    final courierName = order.deliveryProfile?['full_name'] ?? l10n.unassigned;
    final itemsCount = order.items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;

    return InkWell(
      onTap: () => context.push('/admin/orders/${order.id}'),
      borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BabkaColors.surface,
          borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
          boxShadow: BabkaDimens.shadowLow,
          border: Border.all(color: BabkaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          order.orderNumber, 
                          style: BabkaTypography.title(context).copyWith(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: BabkaColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.itemsCount(itemsCount),
                          style: BabkaTypography.caption(context).copyWith(
                            color: BabkaColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(customerName, style: BabkaTypography.h3(context).copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              BabkaNumberFormatter.formatCurrency(order.totalPrice, lang),
              style: BabkaTypography.bodySmall(context).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: BabkaColors.inkLight),
                const SizedBox(width: 4),
                Text(
                  _formatDate(order.createdAt),
                  style: BabkaTypography.caption(context),
                ),
                if (order.assignedDeliveryPerson != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.delivery_dining_outlined, size: 14, color: BabkaColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    courierName, 
                    style: BabkaTypography.caption(context).copyWith(
                      color: BabkaColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const Spacer(),
                Text(l10n.openDetails, style: BabkaTypography.button(context).copyWith(fontSize: 12, color: BabkaColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color color;
    String badgeLabel;

    switch (status) {
      case OrderStatus.pending:
        color = BabkaColors.warning;
        badgeLabel = l10n.statusPending.toUpperCase();
        break;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        color = BabkaColors.info;
        badgeLabel = l10n.statusPreparing.toUpperCase();
        break;
      case OrderStatus.ready:
        color = BabkaColors.accent;
        badgeLabel = l10n.statusReady.toUpperCase();
        break;
      case OrderStatus.outForDelivery:
        color = BabkaColors.primary;
        badgeLabel = l10n.outForDelivery.toUpperCase();
        break;
      case OrderStatus.delivered:
        color = BabkaColors.success;
        badgeLabel = l10n.statusDelivered.toUpperCase();
        break;
      case OrderStatus.cancelled:
        color = BabkaColors.error;
        badgeLabel = l10n.statusCancelled.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        badgeLabel,
        style: BabkaTypography.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
