import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/order.dart';
import '../../shared/utils/role_switcher.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/sangak_back_handler.dart';
import '../../shared/widgets/app_logo.dart';
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
    final isWide = MediaQuery.of(context).size.width > 1000;
    
    return RoleGuard(
      allowedRoles: const ['admin', 'staff'],
      child: SangakBackHandler(
        child: Scaffold(
          backgroundColor: SangakColors.background,
          appBar: isWide ? null : AppBar(
            backgroundColor: SangakColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.go('/home'),
            ),
            title: Text(
              _currentIndex == 0 ? l10n.kitchenPanel : l10n.ordersHistory,
              style: SangakTypography.h3(context),
            ),
            centerTitle: true,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: SangakColors.border),
            ),
          ),
          body: SafeArea(
            child: isWide 
              ? _buildWorkstationLayout(l10n)
              : _buildMobileLayout(l10n),
          ),
          bottomNavigationBar: isWide ? null : _buildBottomNav(l10n),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        const _StaffOrdersView(),
        const _StaffHistoryView(),
      ],
    );
  }

  Widget _buildWorkstationLayout(AppLocalizations l10n) {
    return Row(
      children: [
        // Sidebar (Navigation Rail)
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: SangakColors.surface,
          indicatorColor: SangakColors.primary.withValues(alpha: 0.1),
          selectedIconTheme: const IconThemeData(color: SangakColors.primary),
          unselectedIconTheme: const IconThemeData(color: SangakColors.inkLight),
          labelType: NavigationRailLabelType.all,
          leading: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppLogo.small(),
          ),
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.bakery_dining_rounded),
              label: Text(l10n.orders),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.history_rounded),
              label: Text(l10n.ordersHistory),
            ),
          ],
        ),
        const VerticalDivider(width: 1, thickness: 1, color: SangakColors.border),
        
        // Main Workspace
        Expanded(
          child: Column(
            children: [
              _buildWorkstationHeader(l10n),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    const _StaffOrdersView(),
                    const _StaffHistoryView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkstationHeader(AppLocalizations l10n) {
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: SangakColors.surface,
        border: Border(bottom: BorderSide(color: SangakColors.border)),
      ),
      child: Row(
        children: [
          Text(
            _currentIndex == 0 ? l10n.kitchenPanel : l10n.ordersHistory,
            style: SangakTypography.h2(context),
          ),
          const Spacer(),
          if (userProfile != null) ...[
            Text(
              userProfile.fullName ?? '',
              style: SangakTypography.title(context),
            ),
            const SizedBox(width: 16),
          ],
          IconButton(
            onPressed: () {
              if (userProfile != null) {
                RoleSwitcher.show(context, userProfile.role);
              }
            },
            tooltip: l10n.changeRole,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(
        'Coming Soon: $title',
        style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight),
      ),
    );
  }
}

class _StaffHistoryView extends ConsumerWidget {
  const _StaffHistoryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(staffOrdersProvider);
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return ordersAsync.when(
      data: (orders) {
        final history = orders.where((o) => 
          o.status == OrderStatus.delivered || 
          o.status == OrderStatus.cancelled
        ).toList();

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_rounded, size: 80, color: SangakColors.border),
                const SizedBox(height: 24),
                Text(l10n.noOrderHistory ?? 'No order history yet', style: SangakTypography.h2(context)),
                const SizedBox(height: 8),
                Text(l10n.allCaughtUp, style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight)),
              ],
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: isWide 
            ? _buildHistoryGrid(context, history, l10n)
            : _buildHistoryList(context, history, l10n),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text(l10n.errorOccurred)),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<OrderModel> history, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(SangakDimens.spacing24),
      itemCount: history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) => StaffOrderCard(order: history[index]),
    );
  }

  Widget _buildHistoryGrid(BuildContext context, List<OrderModel> history, AppLocalizations l10n) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1600 ? 4 : (width > 1100 ? 3 : (width > 700 ? 2 : 1));
    final aspectRatio = width > 700 ? 1.6 : 1.3;

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: aspectRatio,
      ),
      itemCount: history.length,
      itemBuilder: (context, index) => StaffOrderCard(order: history[index]),
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
    final isWide = MediaQuery.of(context).size.width > 600;

    return ordersAsync.when(
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
                    if (!isWide) const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: isWide 
                  ? _buildGridView(context, pending, preparing, ready, l10n)
                  : _buildListView(context, pending, preparing, ready, l10n),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text(l10n.errorOccurred)),
    );
  }

  Widget _buildListView(BuildContext context, List<OrderModel> pending, List<OrderModel> preparing, List<OrderModel> ready, AppLocalizations l10n) {
    return ListView(
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
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildGridView(BuildContext context, List<OrderModel> pending, List<OrderModel> preparing, List<OrderModel> ready, AppLocalizations l10n) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1600 ? 4 : (width > 1100 ? 3 : (width > 700 ? 2 : 1));
    final aspectRatio = width > 700 ? 1.6 : 1.3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.isNotEmpty) ...[
            _SectionHeader(title: l10n.newLabel.toUpperCase(), color: SangakColors.warning),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: aspectRatio,
              ),
              itemCount: pending.length,
              itemBuilder: (context, index) => StaffOrderCard(order: pending[index], isNew: true),
            ),
            const SizedBox(height: 32),
          ],
          if (preparing.isNotEmpty) ...[
            _SectionHeader(title: l10n.preparing.toUpperCase(), color: SangakColors.info),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: aspectRatio,
              ),
              itemCount: preparing.length,
              itemBuilder: (context, index) => StaffOrderCard(order: preparing[index]),
            ),
            const SizedBox(height: 32),
          ],
          if (ready.isNotEmpty) ...[
            _SectionHeader(title: l10n.ready.toUpperCase(), color: SangakColors.success),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: aspectRatio,
              ),
              itemCount: ready.length,
              itemBuilder: (context, index) => StaffOrderCard(order: ready[index]),
            ),
            const SizedBox(height: 32),
          ],
        ],
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
