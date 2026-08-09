import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/supabase_service.dart';
import '../auth/auth_provider.dart';
import '../basket/checkout_provider.dart';

final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value([]);
  
  return ref.read(orderRepositoryProvider).watchMyOrders(user.id);
});

final orderStatusProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.read(orderRepositoryProvider).watchOrderStatus(orderId).map((list) {
    if (list.isEmpty) return null;
    return OrderModel.fromJson(list.first);
  });
});

final orderHistoryProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, orderId) {
  return SupabaseService.client
      .from('order_status_history')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .order('created_at', ascending: true);
});
