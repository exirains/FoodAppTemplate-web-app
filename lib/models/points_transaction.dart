class PointsTransaction {
  final String id;
  final String userId;
  final int points;
  final String type; // 'earn', 'spend'
  final String reason;
  final String? orderId;
  final DateTime createdAt;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.reason,
    this.orderId,
    required this.createdAt,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      points: json['points'] as int,
      type: json['type'] as String,
      reason: json['reason'] as String,
      orderId: json['order_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'type': type,
      'reason': reason,
      'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
