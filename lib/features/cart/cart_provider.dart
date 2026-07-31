import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../models/bread.dart';
import '../../models/cart_item.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;

  CartNotifier(this._ref) : super([]) {
    _loadCart();
  }

  void _loadCart() {
    final cartJson = _ref.read(storageServiceProvider).cart;
    if (cartJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        state = decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        // Handle decoding error
        state = [];
      }
    }
  }

  Future<void> _saveCart() async {
    final cartJson = jsonEncode(state.map((e) => e.toJson()).toList());
    await _ref.read(storageServiceProvider).saveCart(cartJson);
  }

  void addItem(Bread bread) {
    final existingIndex = state.indexWhere((item) => item.bread.id == bread.id);
    if (existingIndex != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      state = [...state, CartItem(bread: bread, quantity: 1)];
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
          item.copyWith(quantity: (item.quantity + delta).clamp(1, 99))
        else
          item
    ];
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
