import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/sangak_bottom_nav.dart';
import '../auth/auth_provider.dart';
import '../auth/pending_action_provider.dart';
import 'home_screen.dart';
import 'widgets/basket_guest_view.dart';
import 'widgets/profile_guest_view.dart';
import '../basket/basket_screen.dart';
import '../profile/profile_screen.dart';
import '../explore/explore_screen.dart';
import 'tab_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for auth changes to execute pending actions (Context Preservation)
    ref.listenManual(authProvider, (previous, next) {
      final user = next.asData?.value;
      final prevUser = previous?.asData?.value;
      
      if (user != null && prevUser == null) {
        // User just logged in, execute pending action if any
        ref.read(pendingActionProvider.notifier).execute();
      }
    });
  }

  void _onTabTapped(int index) {
    ref.read(tabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;
    final currentIndex = ref.watch(tabProvider);
    final isGuest = user == null;
    final isHomeTab = currentIndex == 0;

    final List<Widget> screens = [
      const HomeScreen(),
      const ExploreScreen(),
      isGuest ? const BasketGuestView() : const BasketScreen(),
      isGuest ? const ProfileGuestView() : const ProfileScreen(),
    ];

    return PopScope(
      canPop: isHomeTab,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isHomeTab) {
          ref.read(tabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.01),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(currentIndex),
            child: screens[currentIndex],
          ),
        ),
        bottomNavigationBar: SangakBottomNav(
          currentIndex: currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
