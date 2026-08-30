import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/favorite_service.dart';
import '../../main.dart';

class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final FavoriteService _service;

  FavoritesNotifier(Ref ref, this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final ids = await _service.getFavoriteProductIds();
      state = AsyncValue.data(ids);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle(String productId) async {
    final currentIds = state.value ?? [];
    try {
      // Optimistic update
      if (currentIds.contains(productId)) {
        state = AsyncValue.data(currentIds.where((id) => id != productId).toList());
      } else {
        state = AsyncValue.data([...currentIds, productId]);
      }

      await _service.toggleFavorite(productId);
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentIds);
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  return FavoritesNotifier(ref, ref.watch(favoriteServiceProvider));
});

final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.value?.contains(productId) ?? false;
});

final favoriteCountProvider = Provider<int>((ref) {
  return ref.watch(favoritesProvider).value?.length ?? 0;
});
