import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../services/lifecycle_service.dart';

export '../../services/order_repository.dart';

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final repo = ref.read(sangakOrderRepositoryProvider);

  // Watch for app resume to recover stale realtime connections
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating Admin Realtime Provider');
      ref.invalidateSelf();
    }
  });

  return repo.watchAllOrders().asyncMap((list) async {
    // Standard stream doesn't join profiles, so we refetch full data when change detected
    return await repo.getAllOrders();
  });
});

final adminOrderDetailProvider = FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final response = await ref.read(sangakOrderRepositoryProvider).getOrderById(orderId);
  return response;
});

final adminStatsProvider = Provider<AsyncValue<AdminStats>>((ref) {
  final ordersAsync = ref.watch(adminOrdersProvider);
  
  return ordersAsync.whenData((orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    double totalRevenue = 0;
    int pendingCount = 0;
    int preparingCount = 0;
    int readyCount = 0;
    int deliveredCount = 0;
    int todayOrdersCount = 0;

    for (var o in orders) {
      final localCreatedAt = o.createdAt.toLocal();
      // Compare ignoring time, just date
      final isToday = localCreatedAt.year == today.year && 
                     localCreatedAt.month == today.month && 
                     localCreatedAt.day == today.day;

      if (isToday) {
        todayOrdersCount++;
        if (o.status != OrderStatus.cancelled) {
          totalRevenue += o.totalPrice;
        }
      }
      
      switch (o.status) {
        case OrderStatus.pending:
          pendingCount++;
          break;
        case OrderStatus.preparing:
        case OrderStatus.confirmed:
          preparingCount++;
          break;
        case OrderStatus.ready:
          readyCount++;
          break;
        case OrderStatus.delivered:
          deliveredCount++;
          break;
        default:
          break;
      }
    }

    return AdminStats(
      todayTotalOrders: todayOrdersCount,
      todayRevenue: totalRevenue,
      pendingCount: pendingCount,
      preparingCount: preparingCount,
      readyCount: readyCount,
      deliveredCount: deliveredCount,
    );
  });
});

class AdminStats {
  final int todayTotalOrders;
  final double todayRevenue;
  final int pendingCount;
  final int preparingCount;
  final int readyCount;
  final int deliveredCount;

  AdminStats({
    required this.todayTotalOrders,
    required this.todayRevenue,
    required this.pendingCount,
    required this.preparingCount,
    required this.readyCount,
    required this.deliveredCount,
  });
}

final deliveryStaffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(sangakOrderRepositoryProvider).getDeliveryStaff();
});
