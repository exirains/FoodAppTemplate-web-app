class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String nameSnapshot;
  final int quantity;
  final double priceAtPurchase;
  final String imageSnapshot;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.nameSnapshot,
    required this.quantity,
    required this.priceAtPurchase,
    required this.imageSnapshot,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      nameSnapshot: json['name_snapshot'] as String,
      quantity: json['quantity'] as int,
      priceAtPurchase: (json['price_at_purchase'] as num).toDouble(),
      imageSnapshot: json['image_snapshot'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'name_snapshot': nameSnapshot,
      'quantity': quantity,
      'price_at_purchase': priceAtPurchase,
      'image_snapshot': imageSnapshot,
    };
  }

  double get total => priceAtPurchase * quantity;
}
