import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../auth/auth_provider.dart';
import '../basket/checkout_provider.dart';

final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return [];
  
  return ref.read(orderRepositoryProvider).getMyOrders(user.id);
});

final orderStatusProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.read(orderRepositoryProvider).watchOrderStatus(orderId).map((list) {
    if (list.isEmpty) return null;
    return OrderModel.fromJson(list.first);
  });
});
