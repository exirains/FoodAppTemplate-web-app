import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bread.dart';
import '../models/category.dart';
import 'supabase_service.dart';

class BreadRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Category>> getCategories() async {
    try {
      debugPrint('Fetching categories...');
      final response = await _client.from('categories')
          .select('id, name, image_url') // Optimized select
          .order('name');
      final list = (response as List).map((json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String? ?? '',
      )).toList();
      debugPrint('Parsed ${list.length} Category objects');
      return list;
    } catch (e, stack) {
      debugPrint('Error fetching categories: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<List<Bread>> getBreads({String? categoryId}) async {
    try {
      debugPrint('Fetching breads (category: $categoryId)...');
      var query = _client.from('products').select('id, category_id, name, price, image_url, available, tag, prep_time, calories, is_organic'); // Optimized select
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      
      final response = await query.order('created_at', ascending: false);
      final List<Bread> list = [];
      final rawList = response as List;
      debugPrint('Received ${rawList.length} products from Supabase');
      
      for (var json in rawList) {
        try {
          list.add(Bread.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing product ${json['id']}: $e');
        }
      }
      
      debugPrint('Parsed ${list.length} Bread objects');
      return list;
    } catch (e, stack) {
      debugPrint('CRITICAL: Error fetching breads: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<Bread?> getBreadDetails(String id) async {
    try {
      debugPrint('Fetching bread details (id: $id)...');
      final response = await _client.from('products').select().eq('id', id).single();
      final bread = Bread.fromJson(response);
      debugPrint('Parsed details for ${bread.name}');
      return bread;
    } catch (e, stack) {
      debugPrint('Error fetching bread details: $e');
      debugPrint(stack.toString());
      return null;
    }
  }

  Future<List<Bread>> getPopularToday() async {
    try {
      final today = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(today);
      debugPrint('Requesting popular_today date: $dateString');
      
      final response = await _client.from('popular_today')
          .select('products(*)')
          .eq('display_date', dateString);
      
      debugPrint('Popular today raw response: $response');
      
      if ((response as List).isNotEmpty) {
        final rawList = response as List;
        debugPrint('Found ${rawList.length} records in popular_today before parsing');
        
        final List<Bread> list = [];
        for (var item in rawList) {
          try {
            if (item['products'] != null) {
              list.add(Bread.fromJson(item['products']));
            } else {
              debugPrint('Warning: popular_today record has null products join');
            }
          } catch (e) {
            debugPrint('Error parsing nested popular bread: $e');
          }
        }
        
        debugPrint('Parsed ${list.length} Bread objects for popular today');
        return list;
      }
      
      debugPrint('No popular products for today in DB. Picking fallback...');
      // Fallback: Pick 3 random available products and save them for today
      final allAvailableResponse = await _client.from('products')
          .select('id')
          .eq('available', true);
      
      if ((allAvailableResponse as List).isEmpty) {
        debugPrint('No available products found for fallback.');
        return [];
      }
      
      final availableIds = (allAvailableResponse as List).map((p) => p['id'] as String).toList();
      debugPrint('Found ${availableIds.length} available products for fallback selection');
      
      availableIds.shuffle();
      final selection = availableIds.take(3).toList();
      debugPrint('Selected IDs for today: $selection');
      
      final insertData = selection.map((id) => {
        'product_id': id,
        'display_date': dateString,
      }).toList();
      
      final breads = await getBreadsByIds(selection);
      debugPrint('Fetched ${breads.length} full Bread objects for fallback');
      
      try {
        await _client.from('popular_today').upsert(insertData, onConflict: 'product_id, display_date');
        debugPrint('Saved fallback selection to DB for $dateString');
      } catch (e) {
        debugPrint('Note: Failed to cache popular today in DB, but returning selection. $e');
      }
      
      return breads;
    } catch (e, stack) {
      debugPrint('CRITICAL: Error getting popular today: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<List<Bread>> getBreadsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      debugPrint('Fetching breads by IDs: $ids');
      final response = await _client.from('products').select().filter('id', 'in', ids);
      final list = (response as List).map((json) => Bread.fromJson(json)).toList();
      debugPrint('Parsed ${list.length} Bread objects by ID');
      return list;
    } catch (e, stack) {
      debugPrint('Error fetching breads by IDs: $e');
      debugPrint(stack.toString());
      return [];
    }
  }
}
