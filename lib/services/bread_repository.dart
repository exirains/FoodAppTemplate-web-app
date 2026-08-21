import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bread.dart';
import '../models/category.dart';
import 'supabase_service.dart';

class BreadRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Category>> getCategories() async {
    try {
      debugPrint('Fetching categories with translations...');
      final response = await _client
          .from('categories')
          .select('*, category_translations(*)')
          .order('priority', ascending: true);
      
      final rawList = response as List;
      final list = rawList.map((json) => Category.fromJson(Map<String, dynamic>.from(json as Map))).toList();
      
      return list;
    } catch (e, stack) {
      debugPrint('Error fetching categories: $e');
      if (kDebugMode) debugPrint(stack.toString());
      return [];
    }
  }

  Future<List<Bread>> getBreads({String? categoryId}) async {
    try {
      debugPrint('Fetching breads with translations (category: $categoryId)...');
      var query = _client.from('products').select('*, product_translations(*)');
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;
      
      final List<Bread> list = rawList
          .map((json) => Bread.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      
      return list;
    } catch (e, stack) {
      debugPrint('Error fetching breads: $e');
      if (kDebugMode) debugPrint(stack.toString());
      return [];
    }
  }

  Future<Bread?> getBreadDetails(String id) async {
    try {
      final response = await _client.from('products').select('*, product_translations(*)').eq('id', id).single();
      return Bread.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error fetching bread details: $e');
      return null;
    }
  }

  Future<List<Bread>> getPopularToday() async {
    try {
      final today = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(today);
      
      final response = await _client.from('popular_today')
          .select('product_id')
          .eq('display_date', dateString);
      
      if ((response as List).isNotEmpty) {
        final ids = (response as List)
            .map((item) => (item as Map)['product_id']?.toString())
            .whereType<String>()
            .toList();
        return getBreadsByIds(ids);
      }
      
      final allAvailableResponse = await _client.from('products').select('id').eq('available', true);
      if ((allAvailableResponse as List).isEmpty) return [];
      
      final availableIds = (allAvailableResponse as List)
          .map((p) => (p as Map)['id']?.toString())
          .whereType<String>()
          .toList();
          
      availableIds.shuffle();
      final selection = availableIds.take(3).toList();
      
      final insertData = selection.map((id) => {'product_id': id, 'display_date': dateString}).toList();
      final breads = await getBreadsByIds(selection);
      
      try {
        await _client.from('popular_today').upsert(insertData);
      } catch (_) {}
      
      return breads;
    } catch (e) {
      debugPrint('Error in getPopularToday: $e');
      return [];
    }
  }

  Future<List<Bread>> getBreadsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _client.from('products').select('*, product_translations(*)').inFilter('id', ids);
      final list = (response as List).map((json) => Bread.fromJson(Map<String, dynamic>.from(json as Map))).toList();
      return list;
    } catch (e) {
      debugPrint('Error in getBreadsByIds: $e');
      return [];
    }
  }

  /// Admin: Add new product
  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> data) async {
    return await _client.from('products').insert(data).select().single();
  }

  /// Admin: Update product details
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _client.from('products').update(data).eq('id', id).select();
    if ((response as List).isEmpty) {
      throw Exception('Product not found or update failed');
    }
  }

  /// Admin: Upload product image
  Future<String> uploadImage(String productId, Uint8List bytes, String extension) async {
    final fileName = '$productId.$extension';
    final path = 'product_images/$fileName';
    
    await _client.storage.from('products').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    
    return _client.storage.from('products').getPublicUrl(path);
  }

  /// Admin: Update product availability
  Future<void> updateAvailability(String id, bool available) async {
    await _client.from('products').update({'available': available}).eq('id', id);
  }

  /// Admin: Delete product
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  /// Admin: Update product price
  Future<void> updatePrice(String id, double price) async {
    await _client.from('products').update({'price': price}).eq('id', id);
  }

  /// Admin: Update product translations
  Future<void> updateTranslations(String id, Map<String, Map<String, String>> translations) async {
    for (final entry in translations.entries) {
      final lang = entry.key;
      final data = entry.value;
      await _client.from('product_translations').upsert({
        'product_id': id,
        'language_code': lang,
        'name': data['name'],
        'description': data['description'],
      }, onConflict: 'product_id,language_code');
    }
  }

  Stream<List<Map<String, dynamic>>> watchBreads({String? categoryId}) {
    final query = _client.from('products').stream(primaryKey: ['id']);
    if (categoryId != null) {
      return query.eq('category_id', categoryId);
    }
    return query;
  }
}

final breadRepositoryProvider = Provider((ref) => BreadRepository());

final breadsProvider = FutureProvider.family<List<Bread>, String?>((ref, categoryId) {
  return ref.watch(breadRepositoryProvider).getBreads(categoryId: categoryId);
});
