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
      debugPrint('Fetching orders for user $userId...');
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<OrderModel> orders = (response as List).map((json) {
        return OrderModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      debugPrint('Fetched ${orders.length} orders');
      return orders;
    } catch (e, stack) {
      debugPrint('Error fetching orders: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> watchOrderStatus(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .limit(1);
  }
}
