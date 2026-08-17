import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward.dart';
import 'supabase_service.dart';

class RewardRepository {
  final _client = SupabaseService.client;

  Future<List<Reward>> getActiveRewards() async {
    final response = await _client.from('rewards').select().eq('is_active', true);
    return (response as List).map((e) => Reward.fromJson(e)).toList();
  }

  Stream<List<Reward>> watchActiveRewards() {
    return _client
        .from('rewards')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('points_cost', ascending: true)
        .map((data) => data.map((e) => Reward.fromJson(e)).toList());
  }

  Future<void> addReward(Reward reward) async {
    await _client.from('rewards').insert(reward.toJson());
  }

  Future<void> updateReward(Reward reward) async {
    await _client.from('rewards').update(reward.toJson()).eq('id', reward.id);
  }

  Future<void> deleteReward(String id) async {
    await _client.from('rewards').delete().eq('id', id);
  }
}

final rewardRepositoryProvider = Provider((ref) => RewardRepository());
