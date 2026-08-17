import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promotion.dart';
import 'supabase_service.dart';

class PromotionsRepository {
  final _client = SupabaseService.client;

  Future<List<Promotion>> getActivePromotions() async {
    final now = DateTime.now().toIso8601String();
    
    // Fetch promotions that are active and within date range
    final response = await _client
        .from('promotions')
        .select()
        .eq('is_active', true)
        .or('start_date.is.null,start_date.lte.$now')
        .or('end_date.is.null,end_date.gte.$now')
        .order('priority', ascending: false);

    return (response as List).map((e) => Promotion.fromJson(e)).toList();
  }

  Stream<List<Promotion>> watchActivePromotions() {
    return _client
        .from('promotions')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .map((data) => data.map((e) => Promotion.fromJson(e)).toList());
  }

  Future<void> addPromotion(Promotion promotion) async {
    await _client.from('promotions').insert(promotion.toJson());
  }

  Future<void> updatePromotion(Promotion promotion) async {
    await _client.from('promotions').update(promotion.toJson()).eq('id', promotion.id);
  }

  Future<void> deletePromotion(String id) async {
    await _client.from('promotions').delete().eq('id', id);
  }
}

final promotionsRepositoryProvider = Provider((ref) => PromotionsRepository());

final activePromotionsProvider = FutureProvider<List<Promotion>>((ref) {
  return ref.read(promotionsRepositoryProvider).getActivePromotions();
});
