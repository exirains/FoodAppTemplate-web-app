import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_loyalty.dart';
import '../models/points_transaction.dart';
import 'supabase_service.dart';

class LoyaltyRepository {
  final _client = SupabaseService.client;

  Future<UserLoyalty?> getUserLoyalty(String userId) async {
    final response = await _client.from('user_loyalty').select().eq('user_id', userId).maybeSingle();
    if (response == null) return null;
    return UserLoyalty.fromJson(response);
  }

  Stream<UserLoyalty?> watchUserLoyalty(String userId) {
    return _client
        .from('user_loyalty')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) => data.isNotEmpty ? UserLoyalty.fromJson(data.first) : null);
  }

  Stream<List<PointsTransaction>> watchPointsHistory(String userId) {
    return _client
        .from('points_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => PointsTransaction.fromJson(e)).toList());
  }

  Future<void> ensureLoyaltyRecord(String userId) async {
    try {
      // Use awardPoints with 0 to trigger the UPSERT in DB
      await awardPoints(
        userId: userId,
        amount: 0,
        reason: 'Account Initialization',
        type: 'earn',
      );
    } catch (e) {
      debugPrint('🚨 Error ensuring loyalty record: $e');
    }
  }

  Future<void> awardPoints({
    required String userId,
    required int amount,
    required String reason,
    required String type,
    String? relatedId,
  }) async {
    await _client.rpc('award_loyalty_points', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_reason': reason,
      'p_type': type,
      'p_related_id': relatedId,
    });
  }

  Future<void> redeemReward({
    required String userId,
    required String rewardId,
    required int cost,
    required String rewardTitle,
  }) async {
    // We can use the same awardPoints but with negative amount and type 'spend'
    // Or we could create a separate RPC, but award_loyalty_points is flexible enough 
    // if we adjust the SQL to allow negative or just handle it here.
    // However, the SQL provided used 'amount' which we can pass as negative if needed,
    // but usually redeeming is its own flow to check balance.
    
    // For now, let's use the awardPoints RPC with negative amount for spending.
    await awardPoints(
      userId: userId,
      amount: -cost,
      reason: 'Redeemed: $rewardTitle',
      type: 'spend',
      relatedId: rewardId,
    );
  }
}

final loyaltyRepositoryProvider = Provider((ref) => LoyaltyRepository());
