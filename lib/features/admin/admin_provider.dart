import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../services/lifecycle_service.dart';
import '../../core/localization/locale_provider.dart';

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

final revenueDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateTimeRange(start: today, end: today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)));
});

final adminStatsProvider = Provider<AsyncValue<AdminStats>>((ref) {
  final ordersAsync = ref.watch(adminOrdersProvider);
  final filterRange = ref.watch(revenueDateRangeProvider);
  final lang = ref.watch(localeProvider).languageCode;
  
  return ordersAsync.whenData((orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    double filteredRevenue = 0;
    int filteredOrdersCount = 0;
    
    // Weekly Trend (last 7 days fixed for chart context, or dynamic based on filter?)
    // Requirement says "inspect revenue for any specific period", so we'll make the chart dynamic
    final int daysInRange = filterRange.duration.inDays.abs() + 1;
    Map<DateTime, double> trendRevenue = {};
    
    // To prevent giant charts, we'll cap trend data or group by week/month if range is large
    // For now, let's stick to daily breakdown for the selected range
    for (int i = 0; i < daysInRange; i++) {
      final day = DateTime(filterRange.start.year, filterRange.start.month, filterRange.start.day).add(Duration(days: i));
      if (day.isBefore(filterRange.end) || day.isAtSameMomentAs(DateTime(filterRange.end.year, filterRange.end.month, filterRange.end.day))) {
        trendRevenue[day] = 0.0;
      }
    }

    int pendingCount = 0;
    int preparingCount = 0;
    int confirmedCount = 0;
    int readyCount = 0;
    int outForDeliveryCount = 0;
    int deliveredCount = 0;
    int cancelledCount = 0;

    int activeOrdersCount = 0;
    double totalDeliveryTimeMinutes = 0;
    int deliveredCountForAvg = 0;
    
    Map<String, int> productSales = {};
    Map<String, double> paymentBreakdown = {};

    for (var o in orders) {
      final localCreatedAt = o.createdAt.toLocal();
      final isInRange = localCreatedAt.isAfter(filterRange.start.subtract(const Duration(seconds: 1))) && 
                       localCreatedAt.isBefore(filterRange.end.add(const Duration(seconds: 1)));

      if (isInRange) {
        if (o.status != OrderStatus.cancelled) {
          filteredRevenue += o.totalPrice;
          filteredOrdersCount++;
          
          final orderDay = DateTime(localCreatedAt.year, localCreatedAt.month, localCreatedAt.day);
          if (trendRevenue.containsKey(orderDay)) {
            trendRevenue[orderDay] = (trendRevenue[orderDay] ?? 0) + o.totalPrice;
          }
          
          // Top Products
          if (o.items != null) {
            for (var item in o.items!) {
              final localizedName = item.localizedName(lang);
              productSales[localizedName] = (productSales[localizedName] ?? 0) + item.quantity;
            }
          }
          
          // Payment Breakdown
          paymentBreakdown[o.paymentMethod] = (paymentBreakdown[o.paymentMethod] ?? 0) + o.totalPrice;
        }
      }
      
      // Global live stats (always current)
      switch (o.status) {
        case OrderStatus.pending:
          pendingCount++;
          activeOrdersCount++;
          break;
        case OrderStatus.confirmed:
          confirmedCount++;
          activeOrdersCount++;
          break;
        case OrderStatus.preparing:
          preparingCount++;
          activeOrdersCount++;
          break;
        case OrderStatus.ready:
          readyCount++;
          activeOrdersCount++;
          break;
        case OrderStatus.outForDelivery:
          outForDeliveryCount++;
          activeOrdersCount++;
          break;
        case OrderStatus.delivered:
          deliveredCount++;
          if (localCreatedAt.year == today.year && localCreatedAt.month == today.month && localCreatedAt.day == today.day) {
             final diff = o.updatedAt.difference(o.createdAt).inMinutes;
             if (diff > 0) {
               totalDeliveryTimeMinutes += diff;
               deliveredCountForAvg++;
             }
          }
          break;
        case OrderStatus.cancelled:
          cancelledCount++;
          break;
      }
    }

    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AdminStats(
      todayTotalOrders: filteredOrdersCount, // Renamed in usage to "Period Orders"
      todayRevenue: filteredRevenue, // Renamed in usage to "Period Revenue"
      pendingCount: pendingCount,
      preparingCount: preparingCount + confirmedCount,
      readyCount: readyCount,
      deliveredCount: deliveredCount,
      weeklyRevenue: trendRevenue,
      activeOrdersCount: activeOrdersCount,
      averageDeliveryTimeMinutes: deliveredCountForAvg > 0 ? totalDeliveryTimeMinutes / deliveredCountForAvg : 0.0,
      statusBreakdown: {
        OrderStatus.pending: pendingCount,
        OrderStatus.confirmed: confirmedCount,
        OrderStatus.preparing: preparingCount,
        OrderStatus.ready: readyCount,
        OrderStatus.outForDelivery: outForDeliveryCount,
        OrderStatus.delivered: deliveredCount,
        OrderStatus.cancelled: cancelledCount,
      },
      topSellingProducts: topProducts.take(5).map((e) => MapEntry(e.key, e.value)).toList(),
      paymentBreakdown: paymentBreakdown,
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
  final Map<DateTime, double> weeklyRevenue;
  final int activeOrdersCount;
  final double averageDeliveryTimeMinutes;
  final Map<OrderStatus, int> statusBreakdown;
  final List<MapEntry<String, int>> topSellingProducts;
  final Map<String, double> paymentBreakdown;

  AdminStats({
    required this.todayTotalOrders,
    required this.todayRevenue,
    required this.pendingCount,
    required this.preparingCount,
    required this.readyCount,
    required this.deliveredCount,
    required this.weeklyRevenue,
    required this.activeOrdersCount,
    required this.averageDeliveryTimeMinutes,
    required this.statusBreakdown,
    required this.topSellingProducts,
    required this.paymentBreakdown,
  });
}

final deliveryStaffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(sangakOrderRepositoryProvider).getDeliveryStaff();
});
