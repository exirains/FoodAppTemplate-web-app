import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/localization/sangak_number_formatter.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../shared/utils/role_switcher.dart';
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
      child: Scaffold(
        backgroundColor: SangakColors.background,
        appBar: AppBar(
          title: Text(l10n.appName),
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
              padding: const EdgeInsets.all(SangakDimens.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context, profileAsync, l10n),
                  const SizedBox(height: SangakDimens.spacing32),
                  
                  _buildRevenueCard(context, stats.todayRevenue, lang, l10n),
                  const SizedBox(height: SangakDimens.spacing24),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: SangakDimens.spacing16,
                    crossAxisSpacing: SangakDimens.spacing16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatItem(
                        context, 
                        l10n.orders, 
                        '${stats.todayTotalOrders}', 
                        Icons.shopping_bag_outlined, 
                        SangakColors.primary,
                        onTap: () => context.push('/admin/orders?tab=0'),
                      ),
                      _buildStatItem(
                        context, 
                        l10n.statusPending, 
                        '${stats.pendingCount}', 
                        Icons.hourglass_empty_rounded, 
                        SangakColors.warning,
                        onTap: () => context.push('/admin/orders?tab=0'),
                      ),
                      _buildStatItem(
                        context, 
                        l10n.statusPreparing, 
                        '${stats.preparingCount}', 
                        Icons.restaurant_rounded, 
                        SangakColors.info,
                        onTap: () => context.push('/admin/orders?tab=1'),
                      ),
                      _buildStatItem(
                        context, 
                        l10n.statusDelivered, 
                        '${stats.deliveredCount}', 
                        Icons.check_circle_outline_rounded, 
                        SangakColors.success,
                        onTap: () => context.push('/admin/orders?tab=4'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: SangakDimens.spacing48),
                  
                  Text(l10n.quickActions, style: SangakTypography.h3(context)),
                  const SizedBox(height: SangakDimens.spacing16),
                  _buildQuickAction(context, l10n.manageOrders, Icons.list_alt_rounded, () => context.push('/admin/orders')),
                  const SizedBox(height: SangakDimens.spacing12),
                  _buildQuickAction(context, l10n.productManagement, Icons.breakfast_dining_rounded, () => context.push('/admin/products')),
                  const SizedBox(height: SangakDimens.spacing12),
                  _buildQuickAction(context, l10n.userManagement, Icons.people_outline_rounded, () => context.push('/admin/users')),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AsyncValue profileAsync, AppLocalizations l10n) {
    return profileAsync.when(
      data: (profile) => Text(
        '${l10n.goodMorning} ${profile?.fullName ?? 'Admin'}',
        style: SangakTypography.h2(context),
      ),
      loading: () => Text('${l10n.goodMorning} ...', style: SangakTypography.h2(context)),
      error: (error, stack) => Text('${l10n.goodMorning} Admin', style: SangakTypography.h2(context)),
    );
  }

  Widget _buildRevenueCard(BuildContext context, double revenue, String lang, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SangakDimens.spacing24),
      decoration: BoxDecoration(
        color: SangakColors.ink,
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        boxShadow: SangakDimens.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todaysRevenue,
            style: SangakTypography.bodySmall(context).copyWith(color: Colors.white70),
          ),
          const SizedBox(height: SangakDimens.spacing8),
          Text(
            SangakNumberFormatter.formatCurrency(revenue, lang),
            style: SangakTypography.display(context).copyWith(color: Colors.white, fontSize: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SangakDimens.radiusL),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SangakColors.surface,
            borderRadius: BorderRadius.circular(SangakDimens.radiusL),
            boxShadow: SangakDimens.shadowLow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: SangakTypography.h3(context)),
                  Text(label, style: SangakTypography.caption(context)),
                ],
              ),
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
          borderRadius: BorderRadius.circular(SangakDimens.radiusM),
          child: Ink(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: SangakColors.surface,
              border: Border.all(color: SangakColors.border),
              borderRadius: BorderRadius.circular(SangakDimens.radiusM),
            ),
            child: Row(
              children: [
                Icon(icon, color: SangakColors.ink, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label, 
                    style: SangakTypography.title(context).copyWith(fontSize: 16),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: SangakColors.inkLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
