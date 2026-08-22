import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/basket_item.dart';
import '../models/address.dart';
import 'supabase_service.dart';
import 'loyalty_repository.dart';
import 'options_repository.dart';
import '../features/loyalty/loyalty_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderRepository {
  final SupabaseClient _client = SupabaseService.client;
  final Ref? _ref;

  OrderRepository([this._ref]);

  Future<OrderModel> createOrder({
    required String userId,
    required List<BasketItem> items,
    required Address address,
    required String paymentMethod,
    required double totalPrice,
    String? deliveryCode,
    int? estimatedPrepTime,
  }) async {
    try {
      debugPrint('Placing atomic order in Supabase...');
      
      final List<Map<String, dynamic>> itemsData = items.map((item) => {
        'product_id': item.bread.id,
        'name_snapshot': item.bread.name,
        'quantity': item.quantity,
        'price_at_purchase': item.bread.price,
        'image_snapshot': item.bread.imageUrl,
      }).toList();

      final response = await _client.rpc('place_order_atomic', params: {
        'p_address_snapshot': address.toJson(),
        'p_payment_method': paymentMethod,
        'p_total_price': totalPrice,
        'p_delivery_code': deliveryCode,
        'p_estimated_prep_time': estimatedPrepTime,
        'p_items': itemsData,
      });

      debugPrint('Atomic order placed successfully');
      return OrderModel.fromJson(response as Map<String, dynamic>);
    } catch (e, stack) {
      debugPrint('Error placing atomic order: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<List<OrderModel>> getMyOrders(String userId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching my orders: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
          .order('created_at', ascending: false);

      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all orders: $e');
      return [];
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
          .eq('id', orderId)
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching order by ID: $e');
      return null;
    }
  }

  Future<List<OrderModel>> getAssignedOrders(String driverId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
          .eq('assigned_delivery_person', driverId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching assigned orders: $e');
      return [];
    }
  }

  Future<void> confirmDelivery({
    required String orderId,
    required String pin,
  }) async {
    try {
      await _client.rpc('confirm_delivery', params: {
        'p_order_id': orderId,
        'p_pin': pin,
      });
      
      if (_ref != null) {
        await _awardPointsForDelivery(orderId);
      }
      
      debugPrint('Delivery confirmed via RPC');
    } catch (e) {
      debugPrint('Error confirming delivery: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    required String changedBy,
    String? role,
  }) async {
    try {
      // Staff Guardrails: prevent staff from setting delivery statuses
      if (role == 'staff') {
        const staffAllowed = [
          OrderStatus.confirmed,
          OrderStatus.preparing,
          OrderStatus.ready,
          OrderStatus.cancelled,
        ];
        if (!staffAllowed.contains(status)) {
          throw Exception('Staff role is not authorized to set status to ${status.name}');
        }
      }

      await _client.from('orders').update({
        'status': status.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _client.from('order_status_history').insert({
        'order_id': orderId,
        'status': status.toString(),
        'changed_by': changedBy,
      });

      if (status == OrderStatus.delivered && _ref != null) {
        await _awardPointsForDelivery(orderId);
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  Future<bool> assignDeliveryPerson(String orderId, String driverId, {bool ifUnassigned = false}) async {
    try {
      var query = _client.from('orders').update({
        'assigned_delivery_person': driverId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      if (ifUnassigned) {
        // Idempotent: succeed if unassigned OR if already assigned to this driver
        query = query.or('assigned_delivery_person.is.null,assigned_delivery_person.eq.$driverId');
      }

      final response = await query.select('id');
      
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error assigning delivery person: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDeliveryStaff() async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, email')
          .eq('role', 'delivery');
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching delivery staff: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOrderStatusHistory(String orderId) async {
    try {
      final response = await _client
          .from('order_status_history')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching status history: $e');
      return [];
    }
  }

  Stream<List<OrderModel>> watchAvailableOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((list) async {
          final response = await _client
              .from('orders')
              .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
              .or('status.eq.ready,status.eq.out_for_delivery')
              .isFilter('assigned_delivery_person', null)
              .order('created_at', ascending: false);
          
          return (response as List).map((json) => OrderModel.fromJson(json)).toList();
        });
  }

  Stream<List<OrderModel>> watchIncomingOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((list) async {
          final response = await _client
              .from('orders')
              .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
              .or('status.eq.preparing,status.eq.confirmed')
              .isFilter('assigned_delivery_person', null)
              .order('created_at', ascending: false);
          
          return (response as List).map((json) => OrderModel.fromJson(json)).toList();
        });
  }

  Stream<List<OrderModel>> watchDriverOrders(String driverId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_delivery_person', driverId)
        .order('created_at', ascending: false)
        .asyncMap((list) async {
          final response = await _client
              .from('orders')
              .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
              .eq('assigned_delivery_person', driverId)
              .or('status.eq.out_for_delivery,status.eq.ready')
              .order('created_at', ascending: false);
              
          return (response as List).map((json) => OrderModel.fromJson(json)).toList();
        });
  }

  Stream<List<OrderModel>> watchDriverHistory(String driverId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_delivery_person', driverId)
        .order('created_at', ascending: false)
        .asyncMap((list) async {
          final response = await _client
              .from('orders')
              .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
              .eq('assigned_delivery_person', driverId)
              .or('status.eq.delivered,status.eq.cancelled')
              .order('created_at', ascending: false);
              
          return (response as List).map((json) => OrderModel.fromJson(json)).toList();
        });
  }

  Future<List<OrderModel>> getDriverHistory(String driverId, {
    OrderStatus? status,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var dbQuery = _client
          .from('orders')
          .select('*, customer:profiles!user_id(*), delivery_person:profiles!assigned_delivery_person(*), order_items(*, product:products(product_translations(*)))')
          .eq('assigned_delivery_person', driverId);

      if (status != null) {
        dbQuery = dbQuery.eq('status', status.toString());
      } else {
        dbQuery = dbQuery.or('status.eq.delivered,status.eq.cancelled');
      }

      if (startDate != null) {
        dbQuery = dbQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        dbQuery = dbQuery.lte('created_at', endDate.toIso8601String());
      }

      final response = await dbQuery.order('created_at', ascending: false);
      var orders = (response as List).map((json) => OrderModel.fromJson(json)).toList();
      
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        orders = orders.where((o) => 
          o.orderNumber.toLowerCase().contains(q) || 
          (o.userProfile?['full_name']?.toString().toLowerCase().contains(q) ?? false) ||
          (o.addressSnapshot['address']?.toString().toLowerCase().contains(q) ?? false)
        ).toList();
      }
      
      return orders;
    } catch (e) {
      debugPrint('Error fetching driver history: $e');
      return [];
    }
  }

  Stream<List<OrderModel>> watchMyOrders(String userId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((list) async {
          return await getMyOrders(userId);
        });
  }

  Stream<List<Map<String, dynamic>>> watchOrderStatus(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .limit(1);
  }

  Stream<List<Map<String, dynamic>>> watchAllOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> _awardPointsForDelivery(String orderId) async {
    if (_ref == null) return;
    try {
      final order = await getOrderById(orderId);
      if (order == null) {
        debugPrint('🚨 [LOYALTY] Order $orderId not found for points award');
        return;
      }

      // 1. Duplicate Protection Check
      final existing = await _client
          .from('points_transactions')
          .select('id')
          .eq('related_id', orderId)
          .eq('reason', 'Order reward') 
          .maybeSingle();

      if (existing != null) {
        debugPrint('⏩ [LOYALTY] Points already awarded for order $orderId. Skipping.');
        return;
      }

      // 2. Fetch loyalty settings
      final options = await _ref.read(optionsRepositoryProvider).getOptions();
      final earningRule = options['points_earning_rule']?.toString() ?? 'total_spent';
      
      int amount = 0;
      if (earningRule == 'total_spent') {
        final pointsPerCurrency = int.tryParse(options['points_per_currency']?.toString() ?? '1') ?? 1;
        amount = (order.totalPrice * pointsPerCurrency).floor();
        debugPrint('🏅 [LOYALTY] Rule: Total Spent. Mult: $pointsPerCurrency. Amount: $amount');
      } else {
        amount = int.tryParse(options['points_per_order']?.toString() ?? '10') ?? 10;
        debugPrint('🏅 [LOYALTY] Rule: Fixed. Amount: $amount');
      }

      debugPrint('🏅 [LOYALTY] Awarding $amount points to user ${order.userId} for order ${order.orderNumber}');

      // 3. Call award_loyalty_points RPC
      await _ref.read(loyaltyRepositoryProvider).awardPoints(
        userId: order.userId,
        amount: amount,
        reason: 'Order reward', 
        type: 'earn',
        relatedId: order.id,
      );

      final bool purchaseStreakEnabled = options['enable_purchase_streak']?.toString() == 'true';
      if (purchaseStreakEnabled) {
        await _handlePurchaseStreak(order.userId);
      }
      
      _ref.invalidate(userLoyaltyProvider);
      _ref.invalidate(pointsHistoryProvider);
    } catch (e) {
      debugPrint('🚨 Error awarding points for order $orderId: $e');
    }
  }

  Future<void> _handlePurchaseStreak(String userId) async {
    if (_ref == null) return;
    try {
      final profile = await _client.from('profiles').select('last_order_date, current_streak, max_streak').eq('id', userId).single();
      final lastOrderStr = profile['last_order_date'] as String?;
      final currentStreak = profile['current_streak'] as int? ?? 0;
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (lastOrderStr != null) {
        final lastOrder = DateTime.parse(lastOrderStr);
        final lastOrderDate = DateTime(lastOrder.year, lastOrder.month, lastOrder.day);
        
        final difference = todayDate.difference(lastOrderDate).inDays;

        if (difference == 1) {
          final newStreak = currentStreak + 1;
          await _client.from('profiles').update({
            'last_order_date': todayDate.toIso8601String(),
            'current_streak': newStreak,
            'max_streak': newStreak > (profile['max_streak'] ?? 0) ? newStreak : profile['max_streak'],
          }).eq('id', userId);
        } else if (difference > 1) {
          await _client.from('profiles').update({
            'last_order_date': todayDate.toIso8601String(),
            'current_streak': 1,
          }).eq('id', userId);
        }
      } else {
        await _client.from('profiles').update({
          'last_order_date': todayDate.toIso8601String(),
          'current_streak': 1,
        }).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error handling purchase streak: $e');
    }
  }
}

final sangakOrderRepositoryProvider = Provider((ref) => OrderRepository(ref));
