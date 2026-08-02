import 'package:hive_flutter/hive_flutter.dart';
import '../models/bread.dart';
import '../models/category.dart';

class CacheService {
  static const String boxName = 'cache';
  
  final Box<List> _box = Hive.box<List>(boxName);

  Future<void> saveCategories(List<Category> categories, String languageCode) async {
    await _box.put('categories_$languageCode', categories);
  }

  List<Category>? getCategories(String languageCode) {
    final list = _box.get('categories_$languageCode');
    return list?.cast<Category>();
  }

  Future<void> saveBreads(List<Bread> breads, String languageCode) async {
    await _box.put('all_breads_$languageCode', breads);
  }

  List<Bread>? getBreads(String languageCode) {
    final list = _box.get('all_breads_$languageCode');
    return list?.cast<Bread>();
  }

  Future<void> savePopularToday(List<Bread> breads, String languageCode) async {
    await _box.put('popular_today_$languageCode', breads);
  }

  List<Bread>? getPopularToday(String languageCode) {
    final list = _box.get('popular_today_$languageCode');
    return list?.cast<Bread>();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
