import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../models/bread.dart';
import '../../models/basket_item.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';

final basketProvider = StateNotifierProvider<BasketNotifier, List<BasketItem>>((ref) {
  return BasketNotifier(ref);
});

class BasketNotifier extends StateNotifier<List<BasketItem>> {
  final Ref _ref;

  BasketNotifier(this._ref) : super([]) {
    _init();
  }

  void _init() async {
    final user = _ref.read(authProvider).asData?.value;
    
    if (user != null) {
      // 1. Logged in user: Cloud is absolute source of truth on launch.
      // This prevents the doubling bug where disk and cloud items were summed.
      debugPrint('App launched for logged-in user: fetching fresh cloud basket.');
      _loadBasket();
    } else {
      // 2. Guest user: Load from local storage (disk).
      _loadLocalBasket();
    }
    
    _listenToAuth();
  }

  void _listenToAuth() {
    _ref.listen(authProvider, (previous, next) {
      final user = next.asData?.value;
      final prevUser = previous?.asData?.value;
      
      if (user != null && prevUser == null) {
        debugPrint('Auth transition: Guest -> Logged In. Syncing...');
        _syncToSupabase();
      }
    });
  }

  void _loadBasket() async {
    // This is now handled by _init and _listenToAuth
    // But keeping it for manual refreshes if needed
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) {
      _loadLocalBasket();
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('basket_items')
          .select('quantity, products(*, product_translations(*))')
          .eq('user_id', user.id);
      
      final List<BasketItem> items = (response as List).map((e) {
        try {
          return BasketItem(
            bread: Bread.fromJson(e['products']),
            quantity: e['quantity'] as int,
          );
        } catch (e) {
          debugPrint('Error parsing cloud basket item: $e');
          return null;
        }
      }).whereType<BasketItem>().toList();
      
      state = items;
      _saveLocal();
    } catch (e) {
      debugPrint('Error loading basket from Supabase: $e');
    }
  }

  void _loadLocalBasket() {
    final basketJson = _ref.read(storageServiceProvider).basket;
    if (basketJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(basketJson);
        state = decoded.map((e) => BasketItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _saveLocal() async {
    final basketJson = jsonEncode(state.map((e) => e.toJson()).toList());
    await _ref.read(storageServiceProvider).saveBasket(basketJson);
  }

  Future<void> _syncToSupabase() async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) {
      debugPrint('Sync skipped: No user');
      return;
    }

    try {
      debugPrint('Syncing basket to Supabase for user: ${user.id}');
      
      // 1. Fetch cloud items
      final response = await SupabaseService.client
          .from('basket_items')
          .select('product_id, quantity, products(*)')
          .eq('user_id', user.id);
      
      final cloudItems = (response as List).map((e) {
        try {
          return BasketItem(
            bread: Bread.fromJson(e['products']),
            quantity: e['quantity'] as int,
          );
        } catch (e) {
          debugPrint('Error parsing cloud basket item: $e');
          return null;
        }
      }).whereType<BasketItem>().toList();

      debugPrint('Cloud basket: ${cloudItems.length} items');

      // 2. Merge local items into cloud items
      final Map<String, BasketItem> mergedMap = {};
      
      // Add cloud items first
      for (final item in cloudItems) {
        mergedMap[item.bread.id] = item;
      }
      
      // Merge local items (summing quantities)
      for (final localItem in state) {
        if (mergedMap.containsKey(localItem.bread.id)) {
          mergedMap[localItem.bread.id] = mergedMap[localItem.bread.id]!.copyWith(
            quantity: mergedMap[localItem.bread.id]!.quantity + localItem.quantity,
          );
        } else {
          mergedMap[localItem.bread.id] = localItem;
        }
      }

      final mergedList = mergedMap.values.toList();

      // 3. Upsert merged back to cloud
      if (mergedList.isNotEmpty) {
        final data = mergedList.map((item) => {
          'user_id': user.id,
          'product_id': item.bread.id,
          'quantity': item.quantity,
        }).toList();

        await SupabaseService.client.from('basket_items').upsert(
          data, 
          onConflict: 'user_id,product_id' // NO SPACE
        );
      }

      // 4. Update memory state
      state = mergedList;
      _saveLocal();
      
      debugPrint('Basket sync complete. Final count: ${state.length}');
    } catch (e) {
      debugPrint('CRITICAL: Error in _syncToSupabase: $e');
      _loadBasket(); 
    }
  }

  void addItem(Bread bread, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.bread.id == bread.id);
    int newQuantity = quantity;

    if (existingIndex != -1) {
      newQuantity = state[existingIndex].quantity + quantity;
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: newQuantity)
          else
            state[i]
      ];
    } else {
      state = [...state, BasketItem(bread: bread, quantity: quantity)];
    }
    
    _saveLocal();
    _syncItem(bread.id, newQuantity);
  }

  void removeItem(String breadId) {
    state = state.where((item) => item.bread.id != breadId).toList();
    _saveLocal();
    _deleteItem(breadId);
  }

  void updateQuantity(String breadId, int delta) {
    final index = state.indexWhere((item) => item.bread.id == breadId);
    if (index == -1) return;
    
    final item = state[index];
    final newQuantity = (item.quantity + delta).clamp(0, 99);
    
    if (newQuantity > 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) item.copyWith(quantity: newQuantity) else state[i]
      ];
      _saveLocal();
      _syncItem(breadId, newQuantity);
    } else {
      removeItem(breadId);
    }
  }

  Future<void> _syncItem(String productId, int quantity) async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) return;

    try {
      debugPrint('Background sync item: $productId (qty: $quantity) for user: ${user.id}');
      await SupabaseService.client.from('basket_items').upsert({
        'user_id': user.id,
        'product_id': productId,
        'quantity': quantity,
      }, onConflict: 'user_id,product_id');
      debugPrint('Sync successful');
    } catch (e) {
      debugPrint('Error background syncing basket item: $e');
    }
  }

  Future<void> _deleteItem(String productId) async {
    final user = _ref.read(authProvider).asData?.value;
    if (user == null) return;

    try {
      await SupabaseService.client
          .from('basket_items')
          .delete()
          .match({'user_id': user.id, 'product_id': productId});
    } catch (e) {
      debugPrint('Error background deleting basket item: $e');
    }
  }

  void clear() async {
    final user = _ref.read(authProvider).asData?.value;
    state = [];
    _saveLocal();
    
    if (user != null) {
      try {
        await SupabaseService.client.from('basket_items').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint('Error clearing Supabase basket: $e');
      }
    }
  }
}

final basketTotalProvider = Provider<double>((ref) {
  final basket = ref.watch(basketProvider);
  return basket.fold(0, (sum, item) => sum + item.total);
});

final basketItemCountProvider = Provider<int>((ref) {
  final basket = ref.watch(basketProvider);
  return basket.fold(0, (sum, item) => sum + item.quantity);
});
