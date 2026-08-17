import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/referral_repository.dart';
import '../auth/auth_provider.dart';
import '../../models/referral_code.dart';

final userReferralCodeProvider = FutureProvider<ReferralCode?>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return null;
  
  return ref.read(referralRepositoryProvider).getUserReferralCode(user.id);
});

final referralStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    return {
      'totalInvited': 0,
      'successfulReferrals': 0,
      'totalPointsEarned': 0,
    };
  }
  
  return ref.read(referralRepositoryProvider).getReferralStats(user.id);
});
