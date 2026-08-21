enum ReferralStatus {
  pending,
  qualified,
  rewarded,
  cancelled;

  static ReferralStatus fromString(String value) {
    return ReferralStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReferralStatus.pending,
    );
  }

  @override
  String toString() => name;
}

class Referral {
  final String id;
  final String referrerUserId;
  final String referredUserId;
  final String referralCodeId;
  final ReferralStatus status;
  final String? completedOrderId;
  final DateTime? rewardedAt;
  final DateTime? qualifiedAt;
  final DateTime createdAt;
  final String? referredUserName; // NEW

  Referral({
    required this.id,
    required this.referrerUserId,
    required this.referredUserId,
    required this.referralCodeId,
    required this.status,
    this.completedOrderId,
    this.rewardedAt,
    this.qualifiedAt,
    required this.createdAt,
    this.referredUserName,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      referrerUserId: json['referrer_user_id'] as String,
      referredUserId: json['referred_user_id'] as String,
      referralCodeId: json['referral_code_id'] as String,
      status: ReferralStatus.fromString(json['status'] as String),
      completedOrderId: json['completed_order_id'] as String?,
      rewardedAt: json['rewarded_at'] != null 
          ? DateTime.parse(json['rewarded_at'] as String)
          : null,
      qualifiedAt: json['qualified_at'] != null 
          ? DateTime.parse(json['qualified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      referredUserName: json['referred_user'] != null 
          ? json['referred_user']['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_user_id': referrerUserId,
      'referred_user_id': referredUserId,
      'referral_code_id': referralCodeId,
      'status': status.toString(),
      'completed_order_id': completedOrderId,
      'rewarded_at': rewardedAt?.toIso8601String(),
      'qualified_at': qualifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
