import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../shared/utils/role_switcher.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/sangak_back_handler.dart';
import '../auth/profile_provider.dart';
import 'staff_provider.dart';
import 'widgets/staff_order_card.dart';

class StaffKitchenScreen extends ConsumerStatefulWidget {
  const StaffKitchenScreen({super.key});

  @override
  ConsumerState<StaffKitchenScreen> createState() => _StaffKitchenScreenState();
}

class _StaffKitchenScreenState extends ConsumerState<StaffKitchenScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return RoleGuard(
      allowedRoles: const ['admin', 'staff'],
      child: SangakBackHandler(
        child: Scaffold(
          backgroundColor: SangakColors.background,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              const _StaffOrdersView(),
              _buildPlaceholder(l10n.ordersHistory),
              _buildPlaceholder(l10n.staffProfile),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: SangakColors.border, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: SangakColors.primary,
              unselectedItemColor: SangakColors.inkLight,
              backgroundColor: SangakColors.surface,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bakery_dining_rounded),
                  label: l10n.orders,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history_rounded),
                  label: l10n.ordersHistory,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline_rounded),
                  label: l10n.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Coming Soon',
          style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight),
        ),
      ),
    );
  }
}

class _StaffOrdersView extends ConsumerWidget {
  const _StaffOrdersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeBakeryOrdersProvider);
    final newCount = ref.watch(pendingOrdersCountProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.kitchenPanel, style: SangakTypography.h2(context)),
        actions: [
          IconButton(
            onPressed: () {
              final userProfile = ref.read(userProfileProvider).asData?.value;
              if (userProfile != null) {
                RoleSwitcher.show(context, userProfile.role);
              }
            },
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) return _buildEmptyState(context, l10n);

          final pending = orders.where((o) => o.status == OrderStatus.pending).toList();
          final preparing = orders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing).toList();
          final ready = orders.where((o) => o.status == OrderStatus.ready).toList();

          return Column(
            children: [
              // Sticky New Order Alert
              if (newCount > 0)
                Container(
                  width: double.infinity,
                  color: SangakColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        '$newCount ${l10n.newOrders.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(SangakDimens.spacing24),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _SectionHeader(title: l10n.newLabel.toUpperCase(), color: SangakColors.warning),
                      ...pending.map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: StaffOrderCard(order: o, isNew: true),
                      )),
                    ],
                    if (preparing.isNotEmpty) ...[
                      _SectionHeader(title: l10n.preparing.toUpperCase(), color: SangakColors.info),
                      ...preparing.map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: StaffOrderCard(order: o),
                      )),
                    ],
                    if (ready.isNotEmpty) ...[
                      _SectionHeader(title: l10n.ready.toUpperCase(), color: SangakColors.success),
                      ...ready.map((o) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: StaffOrderCard(order: o),
                      )),
                    ],
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorOccurred)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bakery_dining_outlined, size: 80, color: SangakColors.border),
          const SizedBox(height: 24),
          Text(l10n.allCaughtUp, style: SangakTypography.h2(context)),
          const SizedBox(height: 8),
          Text(l10n.noOrdersToPrepare, style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: SangakTypography.h3(context).copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

