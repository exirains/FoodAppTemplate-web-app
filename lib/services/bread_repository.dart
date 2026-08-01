import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bread.dart';
import '../models/category.dart';
import 'supabase_service.dart';

class BreadRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Category>> getCategories() async {
    try {
      final response = await _client.from('categories').select().order('name');
      return (response as List).map((json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String? ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<List<Bread>> getBreads({String? categoryId}) async {
    try {
      var query = _client.from('products').select();
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Bread.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching breads: $e');
      return []; // Return empty list instead of rethrowing to avoid breaking the UI completely
    }
  }
}
