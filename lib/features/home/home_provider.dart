import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../models/bread.dart';
import '../../models/category.dart';
import '../../services/bread_repository.dart';
import '../auth/auth_provider.dart';

final breadRepositoryProvider = Provider((ref) => BreadRepository());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(breadRepositoryProvider).getCategories();
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  return FavoritesNotifier(ref);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Ref _ref;
  FavoritesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    final user = _ref.watch(authProvider).value;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final favorites = await _ref.read(favoriteServiceProvider).getFavoriteProductIds();
      state = AsyncValue.data(favorites);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggle(String productId) async {
    final user = _ref.read(authProvider).value;
    if (user == null) return;

    final currentIds = state.value ?? [];
    final isFavorite = currentIds.contains(productId);

    // Optimistic Update
    if (isFavorite) {
      state = AsyncValue.data(currentIds.where((id) => id != productId).toList());
    } else {
      state = AsyncValue.data([...currentIds, productId]);
    }

    try {
      await _ref.read(favoriteServiceProvider).toggleFavorite(productId);
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentIds);
    }
  }
}

final breadsProvider = FutureProvider<List<Bread>>((ref) async {
  final selectedId = ref.watch(selectedCategoryIdProvider);
  final breads = await ref.read(breadRepositoryProvider).getBreads(categoryId: selectedId);
  final favorites = ref.watch(favoritesProvider).value ?? [];
  
  return breads.map((b) => b.copyWith(isFavorite: favorites.contains(b.id))).toList();
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final filteredBreadsProvider = Provider<AsyncValue<List<Bread>>>((ref) {
  return ref.watch(breadsProvider);
});
