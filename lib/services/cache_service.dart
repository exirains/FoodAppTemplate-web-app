import 'package:hive_flutter/hive_flutter.dart';
import '../models/bread.dart';
import '../models/category.dart';

class CacheService {
  static const String boxName = 'cache';
  static const String categoriesKey = 'categories';
  static const String allBreadsKey = 'all_breads';
  static const String popularTodayKey = 'popular_today';

  final Box<List> _box = Hive.box<List>(boxName);

  Future<void> saveCategories(List<Category> categories) async {
    await _box.put(categoriesKey, categories);
  }

  List<Category>? getCategories() {
    final list = _box.get(categoriesKey);
    return list?.cast<Category>();
  }

  Future<void> saveBreads(List<Bread> breads) async {
    await _box.put(allBreadsKey, breads);
  }

  List<Bread>? getBreads() {
    final list = _box.get(allBreadsKey);
    return list?.cast<Bread>();
  }

  Future<void> savePopularToday(List<Bread> breads) async {
    await _box.put(popularTodayKey, breads);
  }

  List<Bread>? getPopularToday() {
    final list = _box.get(popularTodayKey);
    return list?.cast<Bread>();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
