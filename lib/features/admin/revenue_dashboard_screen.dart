import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/sangak_back_handler.dart';
import '../../models/order.dart';
import 'admin_provider.dart';

class RevenueDashboardScreen extends ConsumerWidget {
  const RevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final range = ref.watch(revenueDateRangeProvider);
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;
    final isWide = MediaQuery.of(context).size.width > 1000;

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: SangakBackHandler(
        child: Scaffold(
          backgroundColor: SangakColors.background,
          appBar: AppBar(
            title: Text(l10n.revenueDashboard),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: statsAsync.when(
            data: (stats) => RefreshIndicator(
              onRefresh: () => ref.refresh(adminOrdersProvider.future),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SangakDimens.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RangeSelector(currentRange: range),
                    const SizedBox(height: 24),
                    if (isWide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left Column: Main Metrics + Live Progress
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildMainMetrics(context, stats, lang, l10n, range),
                                  const SizedBox(height: 24),
                                  _buildLiveProgress(context, stats, l10n),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Column: Weekly Trends + Top Products
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildWeeklyTrends(context, stats, lang, l10n, range),
                                  const SizedBox(height: 24),
                                  _buildTopProducts(context, stats, lang, l10n),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _buildMainMetrics(context, stats, lang, l10n, range),
                      const SizedBox(height: 24),
                      _buildWeeklyTrends(context, stats, lang, l10n, range),
                      const SizedBox(height: 24),
                      _buildLiveProgress(context, stats, l10n),
                      const SizedBox(height: 24),
                      _buildTopProducts(context, stats, lang, l10n),
                      const SizedBox(height: 24),
                      _buildQuickStats(context, stats, l10n),
                    ],
                    if (isWide) ...[
                      const SizedBox(height: 24),
                      _buildQuickStats(context, stats, l10n),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text(l10n.errorOccurred)),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMetrics(BuildContext context, AdminStats stats, String lang, AppLocalizations l10n, DateTimeRange range) {
    final aov = stats.todayTotalOrders > 0 ? stats.todayRevenue / stats.todayTotalOrders : 0.0;
    
    String revenueTitle = l10n.todaysRevenue;
    final days = range.duration.inDays;
    if (days > 1 && days <= 7) {
      revenueTitle = 'Weekly Revenue';
    } else if (days > 7 && days <= 31) {
      revenueTitle = '${l10n.thisMonth} Revenue';
    } else if (days > 31) {
      final startStr = DateFormat('MMM dd').format(range.start);
      final endStr = DateFormat('MMM dd').format(range.end);
      revenueTitle = 'Revenue ($startStr - $endStr)';
    }

    return Column(
      children: [
        _MetricCard(
          title: revenueTitle,
          value: SangakNumberFormatter.formatCurrency(stats.todayRevenue, lang),
          icon: Icons.payments_outlined,
          color: SangakColors.primary,
          isLarge: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: l10n.activeOrders,
                value: '${stats.activeOrdersCount}',
                icon: Icons.shopping_basket_outlined,
                color: SangakColors.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: l10n.averageOrderValue,
                value: SangakNumberFormatter.formatCurrency(aov, lang),
                icon: Icons.analytics_outlined,
                color: SangakColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyTrends(BuildContext context, AdminStats stats, String lang, AppLocalizations l10n, DateTimeRange range) {
    final maxRevenue = stats.weeklyRevenue.values.fold<double>(0, (max, v) => v > max ? v : max);
    final sortedDays = stats.weeklyRevenue.keys.toList()..sort();
    final isCompact = sortedDays.length > 7;

    String chartTitle = l10n.weeklySalesTrends;
    final days = range.duration.inDays;
    if (days <= 1) {
      chartTitle = l10n.todaysRevenue;
    } else if (days > 7 && days <= 31) {
      chartTitle = l10n.thisMonth;
    } else if (days > 31) {
      final startStr = DateFormat('MMM dd').format(range.start);
      final endStr = DateFormat('MMM dd').format(range.end);
      chartTitle = '$startStr - $endStr';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowLow,
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chartTitle, style: SangakTypography.h3(context)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedDays.map((day) {
                final revenue = stats.weeklyRevenue[day] ?? 0.0;
                final heightFactor = maxRevenue > 0 ? revenue / maxRevenue : 0.0;
                final dayName = isCompact ? DateFormat('dd').format(day) : DateFormat('E', lang).format(day);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: '${DateFormat('MMM dd').format(day)}: ${SangakNumberFormatter.formatCurrency(revenue, lang)}',
                        child: Container(
                          width: isCompact ? 10 : 20,
                          height: (heightFactor * 140).clamp(4, 140).toDouble(),
                          decoration: BoxDecoration(
                            color: day.day == DateTime.now().day 
                                ? SangakColors.primary 
                                : SangakColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayName,
                        style: SangakTypography.caption(context).copyWith(
                          fontSize: 9,
                          fontWeight: day.day == DateTime.now().day ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context, AdminStats stats, String lang, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowLow,
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.topProducts, style: SangakTypography.h3(context)),
          const SizedBox(height: 20),
          if (stats.topSellingProducts.isEmpty)
            Center(child: Text(l10n.noProductsFound, style: SangakTypography.bodySmall(context)))
          else
            ...stats.topSellingProducts.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.key, style: SangakTypography.bodyMedium(context)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: SangakColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${e.value}x', style: SangakTypography.title(context).copyWith(fontSize: 12, color: SangakColors.primary)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildLiveProgress(BuildContext context, AdminStats stats, AppLocalizations l10n) {
    final total = stats.activeOrdersCount;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowLow,
        border: Border.all(color: SangakColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.liveOrderProgress, style: SangakTypography.h3(context)),
              _MetricCard(
                title: l10n.avgDeliveryTime,
                value: '${stats.averageDeliveryTimeMinutes.toStringAsFixed(1)} ${l10n.minutesShort}',
                icon: Icons.timer_outlined,
                color: SangakColors.warning,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressItem(context, l10n.statusPending, stats.statusBreakdown[OrderStatus.pending] ?? 0, total, SangakColors.warning),
          const SizedBox(height: 16),
          _buildProgressItem(context, l10n.statusPreparing, (stats.statusBreakdown[OrderStatus.preparing] ?? 0) + (stats.statusBreakdown[OrderStatus.confirmed] ?? 0), total, SangakColors.info),
          const SizedBox(height: 16),
          _buildProgressItem(context, l10n.statusReady, stats.statusBreakdown[OrderStatus.ready] ?? 0, total, SangakColors.accent),
          const SizedBox(height: 16),
          _buildProgressItem(context, l10n.outForDelivery, stats.statusBreakdown[OrderStatus.outForDelivery] ?? 0, total, SangakColors.primary),
        ],
      ),
    );
  }

  Widget _buildProgressItem(BuildContext context, String label, int count, int total, Color color) {
    final percent = total > 0 ? count / total : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: SangakTypography.bodyMedium(context)),
            Text('$count', style: SangakTypography.title(context).copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, AdminStats stats, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SangakColors.ink,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderSummary,
            style: SangakTypography.h3(context).copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatRow(l10n.totalOrdersToday, '${stats.todayTotalOrders}', Colors.white70)),
              const VerticalDivider(color: Colors.white12),
              Expanded(child: _buildStatRow(l10n.statusDelivered, '${stats.deliveredCount}', Colors.white70)),
              const VerticalDivider(color: Colors.white12),
              Expanded(child: _buildStatRow(l10n.statusCancelled, '${stats.statusBreakdown[OrderStatus.cancelled] ?? 0}', Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLarge;
  final bool isSmall;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLarge = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(SangakDimens.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Text(value, style: SangakTypography.title(context).copyWith(fontSize: 12, color: color)),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16),
      decoration: BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowLow,
        border: Border.all(color: SangakColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isLarge ? 32 : 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SangakTypography.bodySmall(context).copyWith(color: SangakColors.inkLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: isLarge 
                      ? SangakTypography.display(context).copyWith(fontSize: 28, color: SangakColors.ink)
                      : SangakTypography.h2(context).copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends ConsumerWidget {
  final DateTimeRange currentRange;
  const _RangeSelector({required this.currentRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(ref, l10n.today, DateTimeRange(start: today, end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)))),
          const SizedBox(width: 8),
          _buildChip(ref, 'Week', DateTimeRange(start: today.subtract(const Duration(days: 6)), end: now)),
          const SizedBox(width: 8),
          _buildChip(ref, l10n.thisMonth, DateTimeRange(start: DateTime(now.year, now.month, 1), end: now)),
          const SizedBox(width: 8),
          _buildCustomChip(context, ref, l10n),
        ],
      ),
    );
  }

  Widget _buildChip(WidgetRef ref, String label, DateTimeRange range) {
    final isSelected = currentRange.start.day == range.start.day && currentRange.duration.inDays == range.duration.inDays;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) ref.read(revenueDateRangeProvider.notifier).state = range;
      },
      selectedColor: SangakColors.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: isSelected ? SangakColors.primary : SangakColors.ink, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  Widget _buildCustomChip(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return ActionChip(
      label: Row(
        children: [
          Text(l10n.customRange),
          const SizedBox(width: 4),
          const Icon(Icons.date_range, size: 14),
        ],
      ),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: currentRange,
        );
        if (picked != null) {
          ref.read(revenueDateRangeProvider.notifier).state = picked;
        }
      },
    );
  }
}
