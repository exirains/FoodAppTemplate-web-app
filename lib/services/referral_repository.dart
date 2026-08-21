import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_code.dart';
import '../models/referral.dart';
import 'supabase_service.dart';

class ReferralRepository {
  final _client = SupabaseService.client;

  /// Fetches the referral code for a specific user
  Future<ReferralCode?> getUserReferralCode(String userId) async {
    try {
      final response = await _client
          .from('referral_codes')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      return ReferralCode.fromJson(response);
    } catch (e) {
      debugPrint('🚨 Error fetching referral code: $e');
      return null;
    }
  }

  /// Validates a referral code using the secure backend RPC
  Future<Map<String, dynamic>> validateReferralCodeSecurely(String code, {String? userId}) async {
    try {
      final response = await _client.rpc('validate_referral_code', params: {
        'p_code': code,
        'p_user_id': userId,
      });
      
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('🚨 Error validating referral code securely: $e');
      return {'valid': false, 'error': e.toString()};
    }
  }

  /// Processes a referral reward atomically using the backend RPC
  Future<Map<String, dynamic>> processReferralReward({
    required String referredUserId,
    required String referralCode,
  }) async {
    try {
      final response = await _client.rpc('process_referral_reward', params: {
        'p_referred_user_id': referredUserId,
        'p_referral_code': referralCode,
      });
      
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('🚨 Error processing referral reward: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Links a new user to a referrer using a referral code
  /// [DEPRECATED] Use [processReferralReward] for atomic reward processing
  Future<void> linkReferral({
    required String referredUserId,
    required String referralCode,
  }) async {
    final result = await processReferralReward(
      referredUserId: referredUserId,
      referralCode: referralCode,
    );
    
    if (result['success'] == false && result['valid'] == false) {
       throw Exception(result['error'] ?? 'Referral processing failed');
    }
  }

  /// Gets referral statistics for a user
  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      final referralsResponse = await _client
          .from('referrals')
          .select('*, referred_user:profiles!referred_user_id(full_name)')
          .eq('referrer_user_id', userId)
          .order('created_at', ascending: false);
      
      final List referralsList = referralsResponse as List;
      final List<Referral> referrals = referralsList.map((r) => Referral.fromJson(r)).toList();
      
      final totalInvited = referrals.length;
      final successfulReferrals = referrals.where((r) => r.status == ReferralStatus.rewarded).length;
      
      // Calculate points earned from referrals by querying points_transactions
      final pointsResponse = await _client
          .from('points_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('reason', 'Referral Reward');
      
      final List points = pointsResponse as List;
      final totalPointsEarned = points.fold<int>(0, (sum, p) => sum + (p['amount'] as int));

      return {
        'totalInvited': totalInvited,
        'successfulReferrals': successfulReferrals,
        'totalPointsEarned': totalPointsEarned,
        'referrals': referrals,
        'referralData': referralsList, // For raw access if needed
      };
    } catch (e) {
      debugPrint('🚨 Error getting referral stats: $e');
      return {
        'totalInvited': 0,
        'successfulReferrals': 0,
        'totalPointsEarned': 0,
        'referrals': <Referral>[],
      };
    }
  }
}

final referralRepositoryProvider = Provider((ref) => ReferralRepository());
