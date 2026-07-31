import 'bread.dart';

class CartItem {
  final Bread bread;
  final int quantity;

  const CartItem({
    required this.bread,
    required this.quantity,
  });

  double get total => bread.price * quantity;

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      bread: bread,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bread': bread.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      bread: Bread.fromJson(json['bread'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
}
