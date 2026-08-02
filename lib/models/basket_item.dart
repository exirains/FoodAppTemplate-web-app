import 'bread.dart';

class BasketItem {
  final Bread bread;
  final int quantity;

  const BasketItem({
    required this.bread,
    required this.quantity,
  });

  double get total => bread.price * quantity;

  BasketItem copyWith({
    int? quantity,
  }) {
    return BasketItem(
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

  factory BasketItem.fromJson(Map<String, dynamic> json) {
    return BasketItem(
      bread: Bread.fromJson(json['bread'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
}
