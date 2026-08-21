class OrderRating {
  final String id;
  final String orderId;
  final String userId;
  final int overallRating;
  final int qualityRating;
  final int freshnessRating;
  final int packagingRating;
  final int deliveryRating;
  final String? reviewText;
  final bool isApproved;
  final DateTime createdAt;
  final Map<String, dynamic>? customer;

  OrderRating({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.overallRating,
    required this.qualityRating,
    required this.freshnessRating,
    required this.packagingRating,
    required this.deliveryRating,
    this.reviewText,
    this.isApproved = false,
    required this.createdAt,
    this.customer,
  });

  factory OrderRating.fromJson(Map<String, dynamic> json) {
    return OrderRating(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      overallRating: int.tryParse(json['overall_rating']?.toString() ?? '5') ?? 5,
      qualityRating: int.tryParse(json['quality_rating']?.toString() ?? '5') ?? 5,
      freshnessRating: int.tryParse(json['freshness_rating']?.toString() ?? '5') ?? 5,
      packagingRating: int.tryParse(json['packaging_rating']?.toString() ?? '5') ?? 5,
      deliveryRating: int.tryParse(json['delivery_rating']?.toString() ?? '5') ?? 5,
      reviewText: json['review_text'] as String?,
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      customer: json['customer'] is Map ? Map<String, dynamic>.from(json['customer'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final data = {
      'order_id': orderId,
      'user_id': userId,
      'overall_rating': overallRating,
      'quality_rating': qualityRating,
      'freshness_rating': freshnessRating,
      'packaging_rating': packagingRating,
      'delivery_rating': deliveryRating,
      'review_text': reviewText,
    };

    if (forUpdate || id.isNotEmpty) {
      data['id'] = id;
    }
    
    // is_approved and created_at should be handled by the database
    // to avoid RLS violations if users aren't allowed to set them.

    return data.map((key, value) => MapEntry(key, value))
      ..removeWhere((key, value) => value == null);
  }
}
