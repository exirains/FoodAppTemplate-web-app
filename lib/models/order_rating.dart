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
  });

  factory OrderRating.fromJson(Map<String, dynamic> json) {
    return OrderRating(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      overallRating: json['overall_rating'] as int,
      qualityRating: json['quality_rating'] as int,
      freshnessRating: json['freshness_rating'] as int,
      packagingRating: json['packaging_rating'] as int,
      deliveryRating: json['delivery_rating'] as int,
      reviewText: json['review_text'] as String?,
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
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
