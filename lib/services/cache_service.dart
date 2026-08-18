import 'package:hive_flutter/hive_flutter.dart';
import '../models/bread.dart';
import '../models/category.dart';

class CacheService {
  static const String boxName = 'cache';

  // Use a dynamic getter instead of typed Box<List> field
  Box get _box => Hive.box(boxName);

  Future<void> saveCategories(List<Category> categories, String languageCode) async {
    await _box.put('categories_$languageCode', categories);
  }

  List<Category>? getCategories(String languageCode) {
    final rawList = _box.get('categories_$languageCode') as List?;
    return rawList?.cast<Category>();
  }

  Future<void> saveBreads(List<Bread> breads, String languageCode) async {
    await _box.put('all_breads_$languageCode', breads);
  }

  List<Bread>? getBreads(String languageCode) {
    final rawList = _box.get('all_breads_$languageCode') as List?;
    return rawList?.cast<Bread>();
  }

  Future<void> savePopularToday(List<Bread> breads, String languageCode) async {
    await _box.put('popular_today_$languageCode', breads);
  }

  List<Bread>? getPopularToday(String languageCode) {
    final rawList = _box.get('popular_today_$languageCode') as List?;
    return rawList?.cast<Bread>();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}