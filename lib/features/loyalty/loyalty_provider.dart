import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/loyalty_repository.dart';
import '../../services/reward_repository.dart';
import '../../services/lifecycle_service.dart';
import '../../models/user_loyalty.dart';
import '../../models/points_transaction.dart';
import '../../models/reward.dart';
import '../auth/auth_provider.dart';

final userLoyaltyProvider = StreamProvider<UserLoyalty?>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value(null);
  
  // Watch for app resume to recover stale realtime connections
  ref.listen<AsyncValue<AppLifecycleState>>(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating User Loyalty Realtime Provider');
      ref.invalidateSelf();
    }
  });

  return ref.read(loyaltyRepositoryProvider).watchUserLoyalty(user.id).handleError((error) {
    debugPrint('🚨 User Loyalty Stream Error: $error');
  });
});

final pointsHistoryProvider = StreamProvider<List<PointsTransaction>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value([]);

  // Watch for app resume to recover stale realtime connections
  ref.listen<AsyncValue<AppLifecycleState>>(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating Points History Realtime Provider');
      ref.invalidateSelf();
    }
  });

  return ref.read(loyaltyRepositoryProvider).watchPointsHistory(user.id);
});

final availableRewardsProvider = StreamProvider<List<Reward>>((ref) {
  // Watch for app resume to recover stale realtime connections
  ref.listen<AsyncValue<AppLifecycleState>>(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating Available Rewards Realtime Provider');
      ref.invalidateSelf();
    }
  });

  return ref.read(rewardRepositoryProvider).watchActiveRewards();
});
