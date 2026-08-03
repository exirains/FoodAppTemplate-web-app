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
    _loadBasket();
    _listenToAuth();
  }

  void _listenToAuth() {
    _ref.listen(authProvider, (previous, next) {
      if (next.value != null && previous?.value == null) {
        // Just logged in, sync local to remote
        _syncToSupabase();
      }
    });
  }

  void _loadBasket() async {
    final user = _ref.read(authProvider).value;
    if (user != null) {
      // Load from Supabase
      try {
        final response = await SupabaseService.client
            .from('basket_items')
            .select('quantity, products(*)')
            .eq('user_id', user.id);
        
        final List<BasketItem> items = (response as List).map((e) {
          return BasketItem(
            bread: Bread.fromJson(e['products']),
            quantity: e['quantity'] as int,
          );
        }).toList();
        state = items;
      } catch (e) {
        _loadLocalBasket();
      }
    } else {
      _loadLocalBasket();
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
    final user = _ref.read(authProvider).value;
    if (user == null) return;

    try {
      debugPrint('Starting basket merge after login...');
      
      // 1. Fetch existing cloud basket
      final response = await SupabaseService.client
          .from('basket_items')
          .select('product_id, quantity, products(*)')
          .eq('user_id', user.id);
      
      final cloudItems = (response as List).map((e) => BasketItem(
        bread: Bread.fromJson(e['products']),
        quantity: e['quantity'] as int,
      )).toList();

      // 2. Merge local (guest) basket into cloud basket
      final merged = List<BasketItem>.from(cloudItems);
      for (final guestItem in state) {
        final existingIndex = merged.indexWhere((ci) => ci.bread.id == guestItem.bread.id);
        if (existingIndex != -1) {
          // Sum quantities: Guest x2 + Account x1 = Sangak x3
          merged[existingIndex] = merged[existingIndex].copyWith(
            quantity: merged[existingIndex].quantity + guestItem.quantity,
          );
        } else {
          merged.add(guestItem);
        }
      }

      // 3. Save merged basket back to Supabase
      if (merged.isNotEmpty) {
        final data = merged.map((item) => {
          'user_id': user.id,
          'product_id': item.bread.id,
          'quantity': item.quantity,
        }).toList();

        await SupabaseService.client.from('basket_items').upsert(
          data, 
          onConflict: 'user_id, product_id'
        );
      }

      // 4. Update local state to the final merged version
      state = merged;
      _saveLocal();
      
      debugPrint('Basket merge complete: ${state.length} products');
    } catch (e) {
      debugPrint('Error merging guest basket to Supabase: $e');
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
    final user = _ref.read(authProvider).value;
    if (user == null) return;

    try {
      await SupabaseService.client.from('basket_items').upsert({
        'user_id': user.id,
        'product_id': productId,
        'quantity': quantity,
      }, onConflict: 'user_id, product_id');
    } catch (e) {
      debugPrint('Error background syncing basket item: $e');
    }
  }

  Future<void> _deleteItem(String productId) async {
    final user = _ref.read(authProvider).value;
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
    final user = _ref.read(authProvider).value;
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
