import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_rating.dart';
import 'supabase_service.dart';

class RatingRepository {
  final _client = SupabaseService.client;

  Future<void> submitRating(OrderRating rating) async {
    try {
      // Use upsert to prevent duplicate ratings for the same order
      // We explicitly pass the user_id to ensure RLS doesn't fail due to missing context
      // and we use the simplified toJson() that excludes system columns.
      await _client.from('order_ratings').upsert(
        rating.toJson(),
        onConflict: 'order_id', 
      );
    } catch (e) {
      debugPrint('🚨 Rating submission failed: $e');
      rethrow;
    }
  }

  Future<OrderRating?> getOrderRating(String orderId) async {
    try {
      final response = await _client
          .from('order_ratings')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      if (response == null) return null;
      return OrderRating.fromJson(response);
    } catch (e) {
      // If maybeSingle fails due to multiple rows (before unique constraint), 
      // return the first one to keep UI working
      final response = await _client
          .from('order_ratings')
          .select()
          .eq('order_id', orderId)
          .limit(1);
      if ((response as List).isEmpty) return null;
      return OrderRating.fromJson(response.first);
    }
  }

  Future<List<OrderRating>> getAllRatings() async {
    final response = await _client
        .from('order_ratings')
        .select('*, customer:profiles!user_id(full_name, avatar_url)')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => OrderRating.fromJson(json)).toList();
  }

  Future<void> approveRating(String ratingId) async {
    await _client.from('order_ratings').update({'is_approved': true}).eq('id', ratingId);
  }

  Future<void> deleteRating(String ratingId) async {
    await _client.from('order_ratings').delete().eq('id', ratingId);
  }
}

final ratingRepositoryProvider = Provider((ref) => RatingRepository());
