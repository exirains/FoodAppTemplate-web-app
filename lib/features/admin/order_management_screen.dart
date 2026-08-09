import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/role_guard.dart';
import 'admin_provider.dart';

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

    return RoleGuard(
      allowedRoles: const ['admin', 'staff'],
      child: Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(
          title: const Text('Order Management'),
          bottom: _CustomTabBar(
            tabController: _tabController,
            orders: ordersAsync.value ?? [],
          ),
        ),
        body: ordersAsync.when(
          data: (orders) => TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(orders.where((o) => o.status == OrderStatus.pending).toList()),
              _buildOrderList(orders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing).toList()),
              _buildOrderList(orders.where((o) => o.status == OrderStatus.ready).toList()),
              _buildOrderList(orders.where((o) => o.status == OrderStatus.outForDelivery).toList()),
              _buildOrderList(orders.where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled).toList()),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders in this status'));
    }

    final lang = ref.watch(localeProvider).languageCode;

    return ListView.separated(
      padding: const EdgeInsets.all(SangakDimens.spacing24),
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

  const _CustomTabBar({required this.tabController, required this.orders});

  @override
  Widget build(BuildContext context) {
    final newCount = orders.where((o) => o.status == OrderStatus.pending).length;
    final prepCount = orders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing).length;
    final readyCount = orders.where((o) => o.status == OrderStatus.ready).length;
    final shippingCount = orders.where((o) => o.status == OrderStatus.outForDelivery).length;

    return TabBar(
      controller: tabController,
      isScrollable: true,
      labelColor: SangakColors.primary,
      unselectedLabelColor: SangakColors.inkLight,
      indicatorColor: SangakColors.primary,
      tabs: [
        Tab(text: 'New ($newCount)'),
        Tab(text: 'Preparing ($prepCount)'),
        Tab(text: 'Ready ($readyCount)'),
        Tab(text: 'Shipping ($shippingCount)'),
        const Tab(text: 'Done'),
      ],
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
    final customerName = order.userProfile?['full_name'] ?? 'User';
    final itemsCount = order.items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () => context.push('/admin/orders/${order.id}'),
      borderRadius: BorderRadius.circular(SangakDimens.radiusL),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SangakColors.surface,
          borderRadius: BorderRadius.circular(SangakDimens.radiusL),
          boxShadow: SangakDimens.shadowLow,
          border: Border.all(color: SangakColors.border),
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
                          style: SangakTypography.title(context).copyWith(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: SangakColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.itemsCount(itemsCount),
                          style: SangakTypography.caption(context).copyWith(
                            color: SangakColors.primary,
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
            Text(customerName, style: SangakTypography.h3(context).copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              SangakNumberFormatter.formatCurrency(order.totalPrice, lang),
              style: SangakTypography.bodySmall(context).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: SangakColors.inkLight),
                const SizedBox(width: 4),
                Text(
                  _formatDate(order.createdAt),
                  style: SangakTypography.caption(context),
                ),
                if (order.assignedDeliveryPerson != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.delivery_dining_outlined, size: 14, color: SangakColors.primary),
                  const SizedBox(width: 4),
                  Text('Assigned', style: SangakTypography.caption(context).copyWith(color: SangakColors.primary)),
                ],
                const Spacer(),
                Text('View Details', style: SangakTypography.button(context).copyWith(fontSize: 12, color: SangakColors.primary)),
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
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = SangakColors.warning;
        label = 'NEW';
        break;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        color = SangakColors.info;
        label = 'PREPARING';
        break;
      case OrderStatus.ready:
        color = SangakColors.accent;
        label = 'READY';
        break;
      case OrderStatus.outForDelivery:
        color = SangakColors.primary;
        label = 'SHIPPING';
        break;
      case OrderStatus.delivered:
        color = SangakColors.success;
        label = 'DELIVERED';
        break;
      case OrderStatus.cancelled:
        color = SangakColors.error;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: SangakTypography.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
