import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/supabase_service.dart';
import '../../services/order_repository.dart';
import '../../services/lifecycle_service.dart';
import '../auth/auth_provider.dart';
import '../../services/rating_repository.dart';

final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value([]);
  
  // Watch for app resume to recover stale realtime connections
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating My Orders Realtime Provider');
      ref.invalidateSelf();
    }
  });

  return ref.read(sangakOrderRepositoryProvider).watchMyOrders(user.id);
});

final isOrderRatedProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  final rating = await ref.read(ratingRepositoryProvider).getOrderRating(orderId);
  return rating != null;
});

final orderStatusProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  // Watch for app resume to recover stale realtime connections
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating Order Status Realtime Provider ($orderId)');
      ref.invalidateSelf();
    }
  });

  return ref.read(sangakOrderRepositoryProvider).watchOrderStatus(orderId).map((list) {
    if (list.isEmpty) return null;
    return OrderModel.fromJson(list.first);
  });
});

final orderHistoryProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, orderId) {
  // Watch for app resume to recover stale realtime connections
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating Order History Realtime Provider ($orderId)');
      ref.invalidateSelf();
    }
  });

  return SupabaseService.client
      .from('order_status_history')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .order('created_at', ascending: true);
});
