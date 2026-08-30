import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import '../../core/localization/babka_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/utils/babka_toast.dart';
import '../../shared/utils/role_switcher.dart';
import '../../shared/widgets/babka_back_handler.dart';
import '../auth/profile_provider.dart';
import 'admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context);
    final lang = ref.watch(localeProvider).languageCode;

    return RoleGuard(
      allowedRoles: const ['admin'],
      child: BabkaBackHandler(
        child: Scaffold(
          backgroundColor: BabkaColors.background,
          appBar: AppBar(
            title: Text(l10n.appName),
            actions: [
              IconButton(
                onPressed: () {
                  final userProfile = ref.read(userProfileProvider).asData?.value;
                  if (userProfile != null) {
                    RoleSwitcher.show(context, userProfile.role);
                  } else {
                    BabkaToast.show(context, l10n.syncingPermissions);
                    ref.invalidate(userProfileProvider);
                  }
                },
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              IconButton(
                onPressed: () => context.push('/admin/orders'),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: statsAsync.when(
            data: (stats) => RefreshIndicator(
              onRefresh: () => ref.refresh(adminOrdersProvider.future),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BabkaDimens.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(context, profileAsync, l10n),
                    const SizedBox(height: BabkaDimens.spacing32),
                    _buildRevenueCard(context, stats.todayRevenue, lang, l10n),
                    const SizedBox(height: BabkaDimens.spacing24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: BabkaDimens.spacing16,
                      crossAxisSpacing: BabkaDimens.spacing16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatItem(context, l10n.orders, '${stats.todayTotalOrders}', Icons.shopping_bag_outlined, BabkaColors.primary, onTap: () => context.push('/admin/orders?tab=0')),
                        _buildStatItem(context, l10n.statusPending, '${stats.pendingCount}', Icons.hourglass_empty_rounded, BabkaColors.warning, onTap: () => context.push('/admin/orders?tab=0')),
                        _buildStatItem(context, l10n.statusPreparing, '${stats.preparingCount}', Icons.restaurant_rounded, BabkaColors.info, onTap: () => context.push('/admin/orders?tab=1')),
                        _buildStatItem(context, l10n.statusDelivered, '${stats.deliveredCount}', Icons.check_circle_outline_rounded, BabkaColors.success, onTap: () => context.push('/admin/orders?tab=4')),
                      ],
                    ),
                    const SizedBox(height: BabkaDimens.spacing48),
                    Text(l10n.quickActions, style: BabkaTypography.h3(context)),
                    const SizedBox(height: BabkaDimens.spacing16),
                    _buildQuickAction(context, l10n.revenueDashboard, Icons.bar_chart_rounded, () => context.push('/admin/revenue')),
                    const SizedBox(height: BabkaDimens.spacing12),
                    _buildQuickAction(context, l10n.manageOrders, Icons.list_alt_rounded, () => context.push('/admin/orders')),
                    const SizedBox(height: BabkaDimens.spacing12),
                    _buildQuickAction(context, l10n.productManagement, Icons.breakfast_dining_rounded, () => context.push('/admin/products')),
                    const SizedBox(height: BabkaDimens.spacing12),
                    _buildQuickAction(context, l10n.userManagement, Icons.people_outline_rounded, () => context.push('/admin/users')),
                    const SizedBox(height: BabkaDimens.spacing12),
                    _buildQuickAction(context, l10n.adminSettings, Icons.settings_suggest_rounded, () => context.push('/admin/settings')),
                    const SizedBox(height: BabkaDimens.spacing12),
                    _buildQuickAction(context, l10n.reviewManagement, Icons.rate_review_rounded, () => context.push('/admin/reviews')),
                    const SizedBox(height: BabkaDimens.spacing12),
                    _buildQuickAction(context, l10n.promotionsBanners, Icons.campaign_rounded, () => context.push('/admin/promotions')),
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

  Widget _buildGreeting(BuildContext context, AsyncValue profileAsync, AppLocalizations l10n) {
    return profileAsync.when(
      data: (profile) => Text('${l10n.goodMorning} ${profile?.fullName ?? l10n.adminPanel}', style: BabkaTypography.h2(context)),
      loading: () => Text('${l10n.goodMorning} ...', style: BabkaTypography.h2(context)),
      error: (error, stack) => Text('${l10n.goodMorning} ${l10n.adminPanel}', style: BabkaTypography.h2(context)),
    );
  }

  Widget _buildRevenueCard(BuildContext context, double revenue, String lang, AppLocalizations l10n) {
    return InkWell(
      onTap: () => context.push('/admin/revenue'),
      borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
        decoration: BoxDecoration(
          color: BabkaColors.ink,
          borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
          boxShadow: BabkaDimens.shadowMedium,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.todaysRevenue, style: BabkaTypography.bodySmall(context).copyWith(color: Colors.white70)),
                  const SizedBox(height: BabkaDimens.spacing8),
                  Text(BabkaNumberFormatter.formatCurrency(revenue, lang), style: BabkaTypography.display(context).copyWith(color: Colors.white, fontSize: 36)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusL),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: BabkaColors.surface, borderRadius: BorderRadius.circular(BabkaDimens.radiusL), boxShadow: BabkaDimens.shadowLow, border: Border.all(color: BabkaColors.border.withValues(alpha: 0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(BabkaDimens.radiusPill)),
                    child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(label.toUpperCase(), style: BabkaTypography.caption(context).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
          child: Ink(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: BabkaColors.surface, border: Border.all(color: BabkaColors.border), borderRadius: BorderRadius.circular(BabkaDimens.radiusM)),
            child: Row(
              children: [
                Icon(icon, color: BabkaColors.ink, size: 24),
                const SizedBox(width: 16),
                Expanded(child: Text(label, style: BabkaTypography.title(context).copyWith(fontSize: 16))),
                const Icon(Icons.chevron_right_rounded, color: BabkaColors.inkLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

