import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FavoriteService {
  final SupabaseClient _client = SupabaseService.client;

  Future<bool> isFavorite(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('favorites')
        .select()
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();
    
    return response != null;
  }

  Future<void> toggleFavorite(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final favorite = await isFavorite(productId);

    if (favorite) {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    } else {
      await _client.from('favorites').insert({
        'user_id': user.id,
        'product_id': productId,
      });
    }
  }

  Future<List<String>> getFavoriteProductIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', user.id);
    
    return (response as List).map((e) => e['product_id'] as String).toList();
  }
}
