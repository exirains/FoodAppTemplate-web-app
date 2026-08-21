import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/sangak_text_field.dart';
import '../../shared/widgets/sangak_empty_states.dart';
import '../admin/admin_provider.dart';
import '../auth/auth_provider.dart';

enum HistoryStatusFilter { all, delivered, cancelled }
enum HistorySortOrder { newest, oldest, priceHigh, priceLow }

class HistoryFilterState {
  final String query;
  final HistoryStatusFilter status;
  final HistorySortOrder sort;
  final DateTimeRange? dateRange;

  HistoryFilterState({
    this.query = '',
    this.status = HistoryStatusFilter.all,
    this.sort = HistorySortOrder.newest,
    this.dateRange,
  });

  HistoryFilterState copyWith({
    String? query,
    HistoryStatusFilter? status,
    HistorySortOrder? sort,
    DateTimeRange? dateRange,
  }) {
    return HistoryFilterState(
      query: query ?? this.query,
      status: status ?? this.status,
      sort: sort ?? this.sort,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

final historyFilterProvider = StateProvider<HistoryFilterState>((ref) => HistoryFilterState());

final deliveryHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return [];

  final filters = ref.watch(historyFilterProvider);
  final repo = ref.read(sangakOrderRepositoryProvider);

  OrderStatus? dbStatus;
  if (filters.status == HistoryStatusFilter.delivered) dbStatus = OrderStatus.delivered;
  if (filters.status == HistoryStatusFilter.cancelled) dbStatus = OrderStatus.cancelled;

  var orders = await repo.getDriverHistory(
    user.id,
    status: dbStatus,
    query: filters.query,
    startDate: filters.dateRange?.start,
    endDate: filters.dateRange?.end,
  );

  // Apply sorting
  switch (filters.sort) {
    case HistorySortOrder.newest:
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case HistorySortOrder.oldest:
      orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case HistorySortOrder.priceHigh:
      orders.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
      break;
    case HistorySortOrder.priceLow:
      orders.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
      break;
  }

  return orders;
});

class DeliveryHistoryScreen extends ConsumerWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(deliveryHistoryProvider);
    final filters = ref.watch(historyFilterProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: SangakColors.background,
      appBar: AppBar(
        title: Text(l10n.history),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(deliveryHistoryProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(context, ref, filters, l10n),
          Expanded(
            child: historyAsync.when(
              data: (orders) => orders.isEmpty
                  ? SangakEmptyState(
                      title: l10n.noOrdersYet,
                      message: filters.query.isNotEmpty || filters.dateRange != null
                          ? l10n.adjustFilters
                          : l10n.noOrdersYet,
                      icon: Icons.history_rounded,
                    )
                  : Column(
                      children: [
                        _buildSummaryHeader(context, orders, lang, l10n),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: orders.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) => _HistoryOrderCard(order: orders[index], lang: lang, l10n: l10n),
                          ),
                        ),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('${l10n.errorOccurred}: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, List<OrderModel> orders, String lang, AppLocalizations l10n) {
    final deliveredOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();
    final totalEarnings = deliveredOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SangakColors.ink,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        boxShadow: SangakDimens.shadowMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalEarnings.toUpperCase(),
                  style: SangakTypography.caption(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SangakNumberFormatter.formatCurrency(totalEarnings, lang),
                  style: SangakTypography.h2(context).copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
            ),
            child: Column(
              children: [
                Text(
                  deliveredOrders.length.toString(),
                  style: SangakTypography.h3(context).copyWith(color: SangakColors.primary),
                ),
                Text(
                  l10n.statusDelivered.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref, HistoryFilterState filters, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SangakTextField(
                  label: l10n.explore,
                  hintText: l10n.searchPlaceholder,
                  leadingIcon: Icons.search_rounded,
                  onChanged: (v) => ref.read(historyFilterProvider.notifier).state = filters.copyWith(query: v),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24), // Align with textfield center
                child: IconButton(
                  onPressed: () {
                    ref.read(historyFilterProvider.notifier).state = HistoryFilterState();
                  },
                  icon: const Icon(Icons.filter_alt_off_rounded, color: SangakColors.error),
                  tooltip: l10n.resetFilters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.filterAll,
                  isSelected: filters.status == HistoryStatusFilter.all,
                  onTap: () => ref.read(historyFilterProvider.notifier).state = filters.copyWith(status: HistoryStatusFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.filterDelivered,
                  isSelected: filters.status == HistoryStatusFilter.delivered,
                  onTap: () => ref.read(historyFilterProvider.notifier).state = filters.copyWith(status: HistoryStatusFilter.delivered),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.filterCancelled,
                  isSelected: filters.status == HistoryStatusFilter.cancelled,
                  onTap: () => ref.read(historyFilterProvider.notifier).state = filters.copyWith(status: HistoryStatusFilter.cancelled),
                ),
                const SizedBox(width: 16),
                const VerticalDivider(width: 1),
                const SizedBox(width: 16),
                _ActionChip(
                  label: filters.dateRange == null 
                      ? l10n.selectDate 
                      : '${DateFormat('MMM d').format(filters.dateRange!.start)} - ${DateFormat('MMM d').format(filters.dateRange!.end)}',
                  icon: Icons.calendar_today_rounded,
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: SangakColors.primary,
                              onPrimary: Colors.white,
                              surface: SangakColors.surface,
                              onSurface: SangakColors.ink,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      ref.read(historyFilterProvider.notifier).state = filters.copyWith(dateRange: picked);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: _getSortLabel(filters.sort, l10n),
                  icon: Icons.sort_rounded,
                  onTap: () => _showSortPicker(context, ref, filters, l10n),
                ),
                const SizedBox(width: 8),
                if (filters.dateRange != null)
                  IconButton(
                    onPressed: () => ref.read(historyFilterProvider.notifier).state = filters.copyWith(dateRange: null),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(HistorySortOrder sort, AppLocalizations l10n) {
    switch (sort) {
      case HistorySortOrder.newest: return l10n.newestFirst;
      case HistorySortOrder.oldest: return l10n.oldestFirst;
      case HistorySortOrder.priceHigh: return l10n.priceHighToLow;
      case HistorySortOrder.priceLow: return l10n.priceLowToHigh;
    }
  }

  void _showSortPicker(BuildContext context, WidgetRef ref, HistoryFilterState filters, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(l10n.sortBy, style: SangakTypography.h3(context)),
          const SizedBox(height: 8),
          _buildSortTile(context, ref, filters, HistorySortOrder.newest, l10n.newestFirst),
          _buildSortTile(context, ref, filters, HistorySortOrder.oldest, l10n.oldestFirst),
          _buildSortTile(context, ref, filters, HistorySortOrder.priceHigh, l10n.priceHighToLow),
          _buildSortTile(context, ref, filters, HistorySortOrder.priceLow, l10n.priceLowToHigh),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSortTile(BuildContext context, WidgetRef ref, HistoryFilterState filters, HistorySortOrder sort, String label) {
    final isSelected = filters.sort == sort;
    return ListTile(
      title: Text(label, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? SangakColors.primary : SangakColors.ink,
      )),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: SangakColors.primary) : null,
      onTap: () {
        ref.read(historyFilterProvider.notifier).state = filters.copyWith(sort: sort);
        Navigator.pop(context);
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SangakColors.primary : SangakColors.surface,
          borderRadius: BorderRadius.circular( SangakDimens.radiusPill),
          border: Border.all(color: isSelected ? SangakColors.primary : SangakColors.border),
        ),
        child: Text(
          label,
          style: SangakTypography.caption(context).copyWith(
            color: isSelected ? Colors.white : SangakColors.ink,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: SangakColors.background,
          borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
          border: Border.all(color: SangakColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: SangakColors.primary),
            const SizedBox(width: 6),
            Text(label, style: SangakTypography.caption(context)),
          ],
        ),
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  final OrderModel order;
  final String lang;
  final AppLocalizations l10n;
  const _HistoryOrderCard({required this.order, required this.lang, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status == OrderStatus.delivered ? SangakColors.success : SangakColors.error;
    final dateStr = DateFormat('MMM dd, yyyy • HH:mm').format(order.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        border: Border.all(color: SangakColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              order.status == OrderStatus.delivered ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.orderNumber, style: SangakTypography.title(context).copyWith(fontSize: 14)),
                    Text(
                      SangakNumberFormatter.formatCurrency(order.totalPrice, lang),
                      style: SangakTypography.title(context).copyWith(color: SangakColors.primary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.userProfile?['full_name'] ?? l10n.customer,
                  style: SangakTypography.bodySmall(context),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: SangakTypography.caption(context).copyWith(color: SangakColors.inkLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: SangakColors.border),
        ],
      ),
    );
  }
}
