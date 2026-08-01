import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../models/bread.dart';
import '../../models/cart_item.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;

  CartNotifier(this._ref) : super([]) {
    _loadCart();
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

  void _loadCart() async {
    final user = _ref.read(authProvider).value;
    if (user != null) {
      // Load from Supabase
      try {
        final response = await SupabaseService.client
            .from('cart_items')
            .select('quantity, products(*)')
            .eq('user_id', user.id);
        
        final List<CartItem> items = (response as List).map((e) {
          return CartItem(
            bread: Bread.fromJson(e['products']),
            quantity: e['quantity'] as int,
          );
        }).toList();
        state = items;
      } catch (e) {
        _loadLocalCart();
      }
    } else {
      _loadLocalCart();
    }
  }

  void _loadLocalCart() {
    final cartJson = _ref.read(storageServiceProvider).cart;
    if (cartJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        state = decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _saveCart() async {
    final user = _ref.read(authProvider).value;
    if (user != null) {
      // Save to Supabase
      try {
        print('Saving cart for user ${user.id}...');
        // First clear old items for this user
        await SupabaseService.client.from('cart_items').delete().eq('user_id', user.id);
        
        if (state.isNotEmpty) {
          final data = state.map((item) => {
            'user_id': user.id,
            'product_id': item.bread.id,
            'quantity': item.quantity,
          }).toList();
          await SupabaseService.client.from('cart_items').insert(data);
          print('Cart items inserted: ${data.length}');
        }
      } catch (e) {
        print('Error saving cart to Supabase: $e');
      }
    } else {
      // Save locally
      final cartJson = jsonEncode(state.map((e) => e.toJson()).toList());
      await _ref.read(storageServiceProvider).saveCart(cartJson);
    }
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
      _loadCart(); // Refresh from DB to ensure state is server-driven
    } catch (e) {
      // Fail silently or log
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
      state = [...state, CartItem(bread: bread, quantity: quantity)];
    }
    _saveCart();
  }

  void removeItem(String breadId) {
    state = state.where((item) => item.bread.id != breadId).toList();
    _saveCart();
  }

  void updateQuantity(String breadId, int delta) {
    state = [
      for (final item in state)
        if (item.bread.id == breadId)
          item.copyWith(quantity: (item.quantity + delta).clamp(0, 99))
        else
          item
    ].where((i) => i.quantity > 0).toList();
    _saveCart();
  }

  void clear() {
    state = [];
    _saveCart();
  }
}

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.total);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});
