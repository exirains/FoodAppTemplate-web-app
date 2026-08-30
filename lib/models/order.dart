import 'order_item.dart';
import 'package:babka/l10n/app_localizations.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
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
      case OrderStatus.confirmed: return 'confirmed';
      case OrderStatus.preparing: return 'preparing';
      case OrderStatus.ready: return 'ready';
      case OrderStatus.outForDelivery: return 'out_for_delivery';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending: return 'PENDING';
      case OrderStatus.confirmed: return 'CONFIRMED';
      case OrderStatus.preparing: return 'PREPARING';
      case OrderStatus.ready: return 'READY';
      case OrderStatus.outForDelivery: return 'OUT FOR DELIVERY';
      case OrderStatus.delivered: return 'DELIVERED';
      case OrderStatus.cancelled: return 'CANCELLED';
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case OrderStatus.pending: return l10n.statusPending;
      case OrderStatus.confirmed: return l10n.statusConfirmed;
      case OrderStatus.preparing: return l10n.statusPreparing;
      case OrderStatus.ready: return l10n.statusReady;
      case OrderStatus.outForDelivery: return l10n.outForDelivery;
      case OrderStatus.delivered: return l10n.statusDelivered;
      case OrderStatus.cancelled: return l10n.statusCancelled;
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
  final String? assignedDeliveryPerson;
  final String? deliveryCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem>? items;
  final Map<String, dynamic>? userProfile; // Joined customer info
  final Map<String, dynamic>? deliveryProfile; // Joined delivery person info

  OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.addressSnapshot,
    required this.paymentMethod,
    required this.totalPrice,
    this.estimatedPrepTime,
    this.assignedDeliveryPerson,
    this.deliveryCode,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.userProfile,
    this.deliveryProfile,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Robust profile extraction: handles both 'profiles' and aliased 'customer' keys
    Map<String, dynamic>? profileData;
    final rawProfiles = json['profiles'] ?? json['customer'];
    
    if (rawProfiles is Map<String, dynamic>) {
      profileData = Map<String, dynamic>.from(rawProfiles);
    } else if (rawProfiles is List && rawProfiles.isNotEmpty) {
      profileData = Map<String, dynamic>.from(rawProfiles.first as Map);
    }

    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      addressSnapshot: json['address_snapshot'] as Map<String, dynamic>,
      paymentMethod: json['payment_method'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      estimatedPrepTime: json['estimated_prep_time'] as int?,
      assignedDeliveryPerson: json['assigned_delivery_person'] as String?,
      deliveryCode: json['delivery_code']?.toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      userProfile: profileData,
      deliveryProfile: json['delivery_person'] is Map ? Map<String, dynamic>.from(json['delivery_person'] as Map) : null,
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
      'assigned_delivery_person': assignedDeliveryPerson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get orderNumber => 'SNK-${id.substring(0, 4).toUpperCase()}';
}

