import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/basket_item.dart';
import '../models/address.dart';
import 'supabase_service.dart';

class OrderRepository {
  final SupabaseClient _client = SupabaseService.client;

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
          .select('*, customer:profiles(*), order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching my orders: $e');
      return [];
    }
  }

  /// Admin/Staff: Fetch all orders with customer info
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, customer:profiles(*), order_items(*)')
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
          .select('*, customer:profiles(*), order_items(*)')
          .eq('id', orderId)
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching order by ID: $e');
      return null;
    }
  }

  /// Delivery: Fetch assigned orders
  Future<List<OrderModel>> getAssignedOrders(String driverId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, customer:profiles(*), order_items(*)')
          .eq('assigned_delivery_person', driverId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching assigned orders: $e');
      return [];
    }
  }

  /// Delivery: Confirm delivery using PIN via RPC
  Future<void> confirmDelivery({
    required String orderId,
    required String pin,
  }) async {
    try {
      await _client.rpc('confirm_delivery', params: {
        'p_order_id': orderId,
        'p_pin': pin,
      });
      // The RPC handles status update and history insertion
      debugPrint('Delivery confirmed via RPC');
    } catch (e) {
      debugPrint('Error confirming delivery: $e');
      rethrow;
    }
  }

  /// Update order status and record history
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    required String changedBy,
  }) async {
    try {
      // 1. Update order status
      await _client.from('orders').update({
        'status': status.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // 2. Record history
      await _client.from('order_status_history').insert({
        'order_id': orderId,
        'status': status.toString(),
        'changed_by': changedBy,
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  /// Admin: Assign delivery person
  Future<void> assignDeliveryPerson(String orderId, String driverId) async {
    try {
      await _client.from('orders').update({
        'assigned_delivery_person': driverId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
    } catch (e) {
      debugPrint('Error assigning delivery person: $e');
      rethrow;
    }
  }

  /// Admin: Get all staff with delivery role
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

  /// Customer: Watch own orders in real-time
  Stream<List<OrderModel>> watchMyOrders(String userId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((list) async {
          // Stream join is limited, so we fetch full data on every change signal
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

  /// Stream all orders for real-time dashboard
  Stream<List<Map<String, dynamic>>> watchAllOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}
