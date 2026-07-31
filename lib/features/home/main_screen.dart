import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/sangak_bottom_nav.dart';
import '../auth/auth_provider.dart';
import '../auth/pending_action_provider.dart';
import 'home_screen.dart';
import 'widgets/cart_guest_view.dart';
import 'widgets/profile_guest_view.dart';
import '../cart/cart_screen.dart';
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
      if (next.value != null && previous?.value == null) {
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
    final user = ref.watch(authProvider).value;
    final currentIndex = ref.watch(tabProvider);
    final isGuest = user == null;

    final List<Widget> screens = [
      const HomeScreen(),
      const Scaffold(body: Center(child: Text('Search Screen'))),
      isGuest ? const CartGuestView() : const CartScreen(),
      isGuest ? const ProfileGuestView() : const Scaffold(body: Center(child: Text('Profile Screen'))),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: SangakBottomNav(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
