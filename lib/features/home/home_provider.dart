import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../models/bread.dart';
import '../../models/category.dart';
import '../../services/bread_repository.dart';
import '../../core/localization/locale_provider.dart';
import '../auth/auth_provider.dart';

final breadRepositoryProvider = Provider((ref) => BreadRepository());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.read(breadRepositoryProvider);
  final cache = ref.read(cacheServiceProvider);
  final locale = ref.watch(localeProvider);
  final lang = locale.languageCode;
  
  final cached = cache.getCategories(lang);
  if (cached != null && cached.isNotEmpty) {
    repo.getCategories().then((value) {
      if (value.isNotEmpty) cache.saveCategories(value, lang);
    }).catchError((_) {});
    return cached;
  }
  
  final live = await repo.getCategories();
  if (live.isNotEmpty) {
    try {
      await cache.saveCategories(live, lang);
    } catch (_) {}
  }
  return live;
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
    final user = _ref.watch(authProvider).asData?.value;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final favorites = await _ref.read(favoriteServiceProvider).getFavoriteProductIds();
      state = AsyncValue.data(favorites);
    } catch (e) {
      // If auth is null (likely due to error elsewhere), don't set global error
      // just default to empty favorites
      state = const AsyncValue.data([]);
    }
  }

  Future<void> toggle(String productId) async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) return;

    final currentIds = state.asData?.value ?? [];
    final isFavorite = currentIds.contains(productId);

    if (isFavorite) {
      state = AsyncValue.data(currentIds.where((id) => id != productId).toList());
    } else {
      state = AsyncValue.data([...currentIds, productId]);
    }

    try {
      await _ref.read(favoriteServiceProvider).toggleFavorite(productId);
    } catch (e) {
      state = AsyncValue.data(currentIds);
    }
  }
}

final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.asData?.value.contains(productId) ?? false;
});

final favoriteCountProvider = Provider<int>((ref) {
  return ref.watch(favoritesProvider).asData?.value.length ?? 0;
});

final breadsProvider = FutureProvider<List<Bread>>((ref) async {
  final selectedId = ref.watch(selectedCategoryIdProvider);
  final repo = ref.read(breadRepositoryProvider);
  final cache = ref.read(cacheServiceProvider);
  final locale = ref.watch(localeProvider);
  final lang = locale.languageCode;

  if (selectedId == null) {
    final cached = cache.getBreads(lang);
    if (cached != null && cached.isNotEmpty) {
      repo.getBreads().then((value) {
        if (value.isNotEmpty) cache.saveBreads(value, lang);
      }).catchError((_) {});
      return cached;
    }
  }
  
  final live = await repo.getBreads(categoryId: selectedId);
  if (selectedId == null && live.isNotEmpty) {
    try {
      await cache.saveBreads(live, lang);
    } catch (_) {}
  }
  return live;
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final filteredBreadsProvider = Provider<AsyncValue<List<Bread>>>((ref) {
  return ref.watch(breadsProvider);
});

final popularBreadsProvider = FutureProvider<List<Bread>>((ref) async {
  final repo = ref.read(breadRepositoryProvider);
  final cache = ref.read(cacheServiceProvider);
  final locale = ref.watch(localeProvider);
  final lang = locale.languageCode;
  
  final cached = cache.getPopularToday(lang);
  if (cached != null && cached.isNotEmpty) {
    repo.getPopularToday().then((value) {
      if (value.isNotEmpty) cache.savePopularToday(value, lang);
    }).catchError((_) {});
    return cached;
  }
  
  final live = await repo.getPopularToday();
  if (live.isNotEmpty) {
    try {
      await cache.savePopularToday(live, lang);
    } catch (_) {}
  }
  return live;
});
