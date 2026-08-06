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
      final response = await _client.from('categories').select().order('priority', ascending: true);
      final rawList = response as List;
      
      final categoryIds = rawList
          .map((json) => (json as Map)['id']?.toString())
          .whereType<String>()
          .toList();
          
      final translations = await _getCategoryTranslations(categoryIds);
      debugPrint('Found ${translations.length} category translation sets');

      final list = rawList.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        final id = map['id']?.toString();
        // Crucial: assign the list of translation maps to the expected key
        map['category_translations'] = id != null ? (translations[id] ?? []) : [];
        return Category.fromJson(map);
      }).toList();
      
      return list;
    } catch (e, stack) {
      debugPrint('Error fetching categories: $e');
      if (kDebugMode) debugPrint(stack.toString());
      return [];
    }
  }

  Future<List<Bread>> getBreads({String? categoryId}) async {
    try {
      debugPrint('Fetching breads (category: $categoryId)...');
      var query = _client.from('products').select();
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      
      final response = await query.order('created_at', ascending: false);
      final rawList = response as List;
      
      final productIds = rawList
          .map((json) => (json as Map)['id']?.toString())
          .whereType<String>()
          .toList();
          
      final translations = await _getProductTranslations(productIds);
      debugPrint('Found ${translations.length} product translation sets');

      final List<Bread> list = [];
      for (final json in rawList) {
        final map = Map<String, dynamic>.from(json as Map);
        final id = map['id']?.toString();
        // Crucial: assign the list of translation maps to the expected key
        map['product_translations'] = id != null ? (translations[id] ?? []) : [];
        try {
          list.add(Bread.fromJson(map));
        } catch (e) {
          debugPrint('Error parsing bread ${map['id']}: $e');
        }
      }
      
      return list;
    } catch (e, stack) {
      debugPrint('Error fetching breads: $e');
      if (kDebugMode) debugPrint(stack.toString());
      return [];
    }
  }

  Future<Bread?> getBreadDetails(String id) async {
    try {
      final response = await _client.from('products').select().eq('id', id).single();
      final translations = await _getProductTranslations([id]);
      
      final map = Map<String, dynamic>.from(response);
      map['product_translations'] = translations[id] ?? [];
      return Bread.fromJson(map);
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
      final response = await _client.from('products').select().inFilter('id', ids);
      final translations = await _getProductTranslations(ids);
      
      final list = (response as List).map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        final id = map['id']?.toString();
        map['product_translations'] = id != null ? (translations[id] ?? []) : [];
        return Bread.fromJson(map);
      }).toList();
      
      return list;
    } catch (e) {
      debugPrint('Error in getBreadsByIds: $e');
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getProductTranslations(List<String> productIds) async {
    if (productIds.isEmpty) return {};
    try {
      final response = await _client.from('product_translations').select().inFilter('product_id', productIds);
      final result = <String, List<Map<String, dynamic>>>{};
      for (final row in response as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final pid = map['product_id']?.toString();
        if (pid != null) {
          result.putIfAbsent(pid, () => []).add(map);
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error in _getProductTranslations: $e');
      return {};
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getCategoryTranslations(List<String> categoryIds) async {
    if (categoryIds.isEmpty) return {};
    try {
      final response = await _client.from('category_translations').select().inFilter('category_id', categoryIds);
      final result = <String, List<Map<String, dynamic>>>{};
      for (final row in response as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final cid = map['category_id']?.toString();
        if (cid != null) {
          result.putIfAbsent(cid, () => []).add(map);
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error in _getCategoryTranslations: $e');
      return {};
    }
  }

  /// Admin: Add new product
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _client.from('products').insert(data);
  }

  /// Admin: Update product details
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _client.from('products').update(data).eq('id', id);
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
}
