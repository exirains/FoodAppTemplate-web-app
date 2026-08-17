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
import '../auth/profile_provider.dart';
import '../../services/loyalty_repository.dart';
import '../../services/options_repository.dart';
import '../../services/supabase_service.dart';
import '../../shared/utils/sangak_toast.dart';
import 'tab_provider.dart';
import '../../shared/widgets/sangak_back_handler.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(authProvider, (previous, next) {
      final user = next.asData?.value;
      final prevUser = previous?.asData?.value;
      if (user != null && prevUser == null) {
        ref.read(pendingActionProvider.notifier).execute();
        ref.read(loyaltyRepositoryProvider).ensureLoyaltyRecord(user.id);
        _handleEngagementStreak(user.id);
      }
    });
  }

  Future<void> _handleEngagementStreak(String userId) async {
    final options = ref.read(appOptionsProvider).value ?? {};
    final bool loginStreakEnabled = options['enable_login_streak']?.toString() == 'true';
    if (!loginStreakEnabled) return;

    try {
      final profile = await SupabaseService.client.from('profiles').select('last_login_date, current_streak').eq('id', userId).single();
      final lastLoginStr = profile['last_login_date'] as String?;
      final currentStreak = profile['current_streak'] as int? ?? 0;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (lastLoginStr != null) {
        final lastLogin = DateTime.parse(lastLoginStr);
        final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
        final difference = todayDate.difference(lastLoginDate).inDays;

        if (difference == 1) {
          final newStreak = currentStreak + 1;
          await SupabaseService.client.from('profiles').update({'last_login_date': todayDate.toIso8601String(), 'current_streak': newStreak, 'max_streak': currentStreak >= (profile['max_streak'] ?? 0) ? newStreak : profile['max_streak']}).eq('id', userId);
          final threshold = int.tryParse(options['streak_threshold']?.toString() ?? '3') ?? 3;
          if (newStreak % threshold == 0) {
            final bonus = int.tryParse(options['streak_bonus']?.toString() ?? '50') ?? 50;
            await ref.read(loyaltyRepositoryProvider).awardPoints(userId: userId, amount: bonus, reason: 'Streak Bonus ($newStreak Days)', type: 'earn');
            if (mounted) SangakToast.show(context, '🔥 $newStreak Day Streak! +$bonus Pts');
          }
        } else if (difference > 1) {
          await SupabaseService.client.from('profiles').update({'last_login_date': todayDate.toIso8601String(), 'current_streak': 1}).eq('id', userId);
        }
      } else {
        await SupabaseService.client.from('profiles').update({'last_login_date': todayDate.toIso8601String(), 'current_streak': 1}).eq('id', userId);
      }
      ref.invalidate(userProfileProvider);
    } catch (e) {
      debugPrint('Error handling streak: $e');
    }
  }

  void _onTabTapped(int index) => ref.read(tabProvider.notifier).state = index;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;
    final currentIndex = ref.watch(tabProvider);
    final isGuest = user == null;

    final List<Widget> screens = [
      const HomeScreen(),
      const ExploreScreen(),
      isGuest ? const BasketGuestView() : const BasketScreen(),
      isGuest ? const ProfileGuestView() : const ProfileScreen(),
    ];

    return SangakBackHandler(
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.01), end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey<int>(currentIndex), child: screens[currentIndex]),
        ),
        bottomNavigationBar: SangakBottomNav(currentIndex: currentIndex, onTap: _onTabTapped),
      ),
    );
  }
}
