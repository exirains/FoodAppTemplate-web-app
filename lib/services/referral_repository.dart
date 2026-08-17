import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_code.dart';
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

  /// Validates a referral code and returns the referral_code_id if valid
  Future<String?> validateReferralCode(String code) async {
    try {
      final response = await _client
          .from('referral_codes')
          .select('id, user_id, is_active')
          .ilike('code', code)
          .maybeSingle();
      
      if (response == null) return null;
      if (response['is_active'] == false) return null;
      
      return response['id'] as String;
    } catch (e) {
      debugPrint('🚨 Error validating referral code: $e');
      return null;
    }
  }

  /// Links a new user to a referrer using a referral code
  Future<void> linkReferral({
    required String referredUserId,
    required String referralCode,
  }) async {
    try {
      // 1. Get the referral code ID and referrer ID
      final codeResponse = await _client
          .from('referral_codes')
          .select('id, user_id')
          .ilike('code', referralCode)
          .maybeSingle();
      
      if (codeResponse == null) {
        throw Exception('Invalid referral code');
      }

      final String referralCodeId = codeResponse['id'];
      final String referrerUserId = codeResponse['user_id'];

      if (referrerUserId == referredUserId) {
        throw Exception('Self-referral is not allowed');
      }

      // 2. Create the referral relationship
      await _client.from('referrals').insert({
        'referrer_user_id': referrerUserId,
        'referred_user_id': referredUserId,
        'referral_code_id': referralCodeId,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('🚨 Error linking referral: $e');
      rethrow;
    }
  }

  /// Gets referral statistics for a user
  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      final referralsResponse = await _client
          .from('referrals')
          .select('status, id')
          .eq('referrer_user_id', userId);
      
      final List referrals = referralsResponse as List;
      
      final totalInvited = referrals.length;
      final successfulReferrals = referrals.where((r) => r['status'] == 'rewarded').length;
      
      // Calculate points earned from referrals by querying points_transactions
      final pointsResponse = await _client
          .from('points_transactions')
          .select('points')
          .eq('user_id', userId)
          .eq('reason', 'Referral Reward');
      
      final List points = pointsResponse as List;
      final totalPointsEarned = points.fold<int>(0, (sum, p) => sum + (p['points'] as int));

      return {
        'totalInvited': totalInvited,
        'successfulReferrals': successfulReferrals,
        'totalPointsEarned': totalPointsEarned,
      };
    } catch (e) {
      debugPrint('🚨 Error getting referral stats: $e');
      return {
        'totalInvited': 0,
        'successfulReferrals': 0,
        'totalPointsEarned': 0,
      };
    }
  }
}

final referralRepositoryProvider = Provider((ref) => ReferralRepository());
