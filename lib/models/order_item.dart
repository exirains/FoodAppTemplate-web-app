class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String nameSnapshot;
  final int quantity;
  final double priceAtPurchase;
  final String imageSnapshot;
  final Map<String, dynamic>? productTranslations;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.nameSnapshot,
    required this.quantity,
    required this.priceAtPurchase,
    required this.imageSnapshot,
    this.productTranslations,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Extract translations from nested product join if available
    Map<String, dynamic>? translationsMap;
    final productData = json['product'];
    if (productData is Map) {
      final rawTranslations = productData['product_translations'];
      if (rawTranslations is Iterable) {
        translationsMap = {};
        for (final t in rawTranslations) {
          if (t is Map) {
            final code = t['language_code']?.toString();
            if (code == null || code.isEmpty) continue;
            translationsMap[code] = {
              'name': t['name']?.toString(),
              'description': t['description']?.toString(),
            };
          }
        }
      }
    }

    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      nameSnapshot: json['name_snapshot'] as String,
      quantity: json['quantity'] as int,
      priceAtPurchase: (json['price_at_purchase'] as num).toDouble(),
      imageSnapshot: json['image_snapshot'] as String,
      productTranslations: translationsMap,
    );
  }

  String localizedName(String locale) {
    if (productTranslations == null || productTranslations!.isEmpty) return nameSnapshot;
    final lang = locale.split('_')[0].split('-')[0];
    return productTranslations![lang]?['name'] ?? 
           productTranslations!['tr']?['name'] ?? 
           productTranslations!['en']?['name'] ?? 
           nameSnapshot;
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
