import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bread.dart';
import '../../models/category.dart';
import '../../services/bread_repository.dart';

final breadRepositoryProvider = Provider((ref) => BreadRepository());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(breadRepositoryProvider).getCategories();
});

final breadsProvider = FutureProvider<List<Bread>>((ref) async {
  return ref.read(breadRepositoryProvider).getBreads();
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final filteredBreadsProvider = Provider<AsyncValue<List<Bread>>>((ref) {
  final breadsAsync = ref.watch(breadsProvider);
  final selectedId = ref.watch(selectedCategoryIdProvider);

  return breadsAsync.whenData((breads) {
    if (selectedId == null) return breads;
    return breads.where((bread) => bread.categoryId == selectedId).toList();
  });
});
