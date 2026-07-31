import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/sangak_bottom_nav.dart';
import '../auth/auth_provider.dart';
import '../auth/pending_action_provider.dart';
import 'home_screen.dart';
import 'widgets/cart_guest_view.dart';
import 'widgets/profile_guest_view.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

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
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final isGuest = user == null;

    final List<Widget> screens = [
      const HomeScreen(),
      const Scaffold(body: Center(child: Text('Search Screen'))),
      isGuest ? const CartGuestView() : const Scaffold(body: Center(child: Text('Cart Screen'))),
      isGuest ? const ProfileGuestView() : const Scaffold(body: Center(child: Text('Profile Screen'))),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: SangakBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
