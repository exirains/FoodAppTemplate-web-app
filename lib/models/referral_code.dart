class ReferralCode {
  final String id;
  final String userId;
  final String code;
  final bool isActive;
  final DateTime createdAt;

  ReferralCode({
    required this.id,
    required this.userId,
    required this.code,
    this.isActive = true,
    required this.createdAt,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'code': code,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
