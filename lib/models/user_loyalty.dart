class UserLoyalty {
  final String userId;
  final int currentPoints;
  final int totalEarnedPoints;
  final String loyaltyLevel;
  final DateTime? updatedAt;

  UserLoyalty({
    required this.userId,
    this.currentPoints = 0,
    this.totalEarnedPoints = 0,
    this.loyaltyLevel = 'Bronze',
    this.updatedAt,
  });

  factory UserLoyalty.fromJson(Map<String, dynamic> json) {
    return UserLoyalty(
      userId: json['user_id'] as String,
      currentPoints: json['current_points'] as int? ?? 0,
      totalEarnedPoints: json['total_earned_points'] as int? ?? 0,
      loyaltyLevel: json['loyalty_level'] as String? ?? 'Bronze',
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_points': currentPoints,
      'total_earned_points': totalEarnedPoints,
      'loyalty_level': loyaltyLevel,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
