import 'package:uuid/uuid.dart';
import 'bread.dart';
import 'babka_customization.dart';

class BasketItem {
  final String basketId;
  final Bread bread;
  final int quantity;
  final BabkaCustomization? customization;

  BasketItem({
    String? basketId,
    required this.bread,
    required this.quantity,
    this.customization,
  }) : basketId = basketId ?? const Uuid().v4();

  double get unitPrice => customization != null 
      ? customization!.totalPrice
      : bread.price;

  double get total => unitPrice * quantity;

  BasketItem copyWith({
    String? basketId,
    int? quantity,
    BabkaCustomization? customization,
  }) {
    return BasketItem(
      basketId: basketId ?? this.basketId,
      bread: bread,
      quantity: quantity ?? this.quantity,
      customization: customization ?? this.customization,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basket_id': basketId,
      'bread': bread.toJson(),
      'quantity': quantity,
      'customization': customization?.toJson(),
    };
  }

  factory BasketItem.fromJson(Map<String, dynamic> json) {
    return BasketItem(
      basketId: json['basket_id'] as String?,
      bread: Bread.fromJson(json['bread'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      customization: json['customization'] != null
          ? BabkaCustomization.fromJson(json['customization'] as Map<String, dynamic>)
          : null,
    );
  }
}

