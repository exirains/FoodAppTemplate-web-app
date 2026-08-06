class OrderStatusHistory {
  final String id;
  final String orderId;
  final String status;
  final String changedBy;
  final DateTime createdAt;

  OrderStatusHistory({
    required this.id,
    required this.orderId,
    required this.status,
    required this.changedBy,
    required this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: json['status'] as String,
      changedBy: json['changed_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'status': status,
      'changed_by': changedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
