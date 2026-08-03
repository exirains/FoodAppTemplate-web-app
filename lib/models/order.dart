import 'order_item.dart';

enum OrderStatus {
  pending,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value || e._toSql() == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String _toSql() {
    switch (this) {
      case OrderStatus.pending: return 'pending';
      case OrderStatus.preparing: return 'preparing';
      case OrderStatus.outForDelivery: return 'out_for_delivery';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }

  @override
  String toString() => _toSql();
}

class OrderModel {
  final String id;
  final String userId;
  final OrderStatus status;
  final Map<String, dynamic> addressSnapshot;
  final String paymentMethod;
  final double totalPrice;
  final int? estimatedPrepTime;
  final DateTime createdAt;
  final List<OrderItem>? items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.addressSnapshot,
    required this.paymentMethod,
    required this.totalPrice,
    this.estimatedPrepTime,
    required this.createdAt,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      addressSnapshot: json['address_snapshot'] as Map<String, dynamic>,
      paymentMethod: json['payment_method'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      estimatedPrepTime: json['estimated_prep_time'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status.toString(),
      'address_snapshot': addressSnapshot,
      'payment_method': paymentMethod,
      'total_price': totalPrice,
      'estimated_prep_time': estimatedPrepTime,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get orderNumber => 'SNK-${id.substring(0, 8).toUpperCase()}';
}
