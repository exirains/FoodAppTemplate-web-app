class PointsTransaction {
  final String id;
  final String userId;
  final int amount;
  final String type; // 'earn', 'spend'
  final String reason;
  final String? relatedId;
  final DateTime createdAt;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    this.relatedId,
    required this.createdAt,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      reason: json['reason'] as String,
      relatedId: json['related_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'reason': reason,
      'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
