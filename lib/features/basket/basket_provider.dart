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
            .from('cart_items')
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

  Future<void> _saveBasket() async {
    final user = _ref.read(authProvider).value;
    if (user != null) {
      try {
        debugPrint('Saving basket to Supabase for user ${user.id}...');
        // First clear old items for this user
        await SupabaseService.client.from('cart_items').delete().eq('user_id', user.id);
        
        if (state.isNotEmpty) {
          final data = state.map((item) => {
            'user_id': user.id,
            'product_id': item.bread.id,
            'quantity': item.quantity,
          }).toList();
          await SupabaseService.client.from('cart_items').insert(data);
          debugPrint('Basket saved to Supabase: ${data.length} items');
        }
      } catch (e) {
        debugPrint('CRITICAL: Error saving basket to Supabase: $e');
      }
    }
    
    // Always save locally as fallback/cache
    final basketJson = jsonEncode(state.map((e) => e.toJson()).toList());
    await _ref.read(storageServiceProvider).saveBasket(basketJson);
  }

  Future<void> _syncToSupabase() async {
    final user = _ref.read(authProvider).value;
    if (user == null || state.isEmpty) return;

    final data = state.map((item) => {
      'user_id': user.id,
      'product_id': item.bread.id,
      'quantity': item.quantity,
    }).toList();

    try {
      // Upsert to handle existing items
      await SupabaseService.client.from('cart_items').upsert(
        data, 
        onConflict: 'user_id, product_id'
      );
      _loadBasket(); // Refresh from DB to ensure state is server-driven
    } catch (e) {
      debugPrint('Error syncing basket to Supabase: $e');
    }
  }

  void addItem(Bread bread, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.bread.id == bread.id);
    if (existingIndex != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + quantity)
          else
            state[i]
      ];
    } else {
      state = [...state, BasketItem(bread: bread, quantity: quantity)];
    }
    _saveBasket();
  }

  void removeItem(String breadId) {
    state = state.where((item) => item.bread.id != breadId).toList();
    _saveBasket();
  }

  void updateQuantity(String breadId, int delta) {
    state = [
      for (final item in state)
        if (item.bread.id == breadId)
          item.copyWith(quantity: (item.quantity + delta).clamp(0, 99))
        else
          item
    ].where((i) => i.quantity > 0).toList();
    _saveBasket();
  }

  void clear() {
    state = [];
    _saveBasket();
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
