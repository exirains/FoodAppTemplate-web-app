import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../services/alert_service.dart';
import '../../services/analytics_service.dart';
import '../auth/auth_provider.dart';

final deliveryDashboardProvider = StateNotifierProvider<DeliveryDashboardNotifier, DeliveryDashboardState>((ref) {
  final repo = ref.read(sangakOrderRepositoryProvider);
  final alertService = ref.read(alertServiceProvider);
  final analyticsService = ref.read(analyticsServiceProvider);
  final userId = ref.watch(authProvider).value?.id;
  return DeliveryDashboardNotifier(repo, alertService, analyticsService, userId);
});

class DeliveryDashboardState {
  final List<OrderModel> availableOrders;
  final List<OrderModel> myTasks;
  final bool isLoading;

  DeliveryDashboardState({
    this.availableOrders = const [],
    this.myTasks = const [],
    this.isLoading = false,
  });

  DeliveryDashboardState copyWith({
    List<OrderModel>? availableOrders,
    List<OrderModel>? myTasks,
    bool? isLoading,
  }) {
    return DeliveryDashboardState(
      availableOrders: availableOrders ?? this.availableOrders,
      myTasks: myTasks ?? this.myTasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DeliveryDashboardNotifier extends StateNotifier<DeliveryDashboardState> {
  final OrderRepository _repo;
  final AlertService _alertService;
  final AnalyticsService _analytics;
  final String? _userId;
  StreamSubscription? _availableSubscription;
  StreamSubscription? _tasksSubscription;
  final Set<String> _notifiedReadyOrderIds = {};

  DeliveryDashboardNotifier(this._repo, this._alertService, this._analytics, this._userId) 
      : super(DeliveryDashboardState(isLoading: true)) {
    _init();
  }

  void _init() {
    if (_userId == null) return;

    // Watch for unassigned READY orders
    _availableSubscription = _repo.watchAvailableOrders().listen(
      (orders) {
        // Only trigger alert for READY orders (not out_for_delivery which might be in the stream)
        final readyOrders = orders.where((o) => o.status == OrderStatus.ready).toList();
        _checkNewReadyOrders(readyOrders);
        state = state.copyWith(availableOrders: orders, isLoading: false);
      },
      onError: (e) => debugPrint('🚨 Available Orders Stream Error: $e'),
    );

    // Watch for driver's active tasks
    _tasksSubscription = _repo.watchDriverOrders(_userId).listen(
      (orders) {
        state = state.copyWith(myTasks: orders);
      },
      onError: (e) => debugPrint('🚨 Driver Tasks Stream Error: $e'),
    );
  }

  void _checkNewReadyOrders(List<OrderModel> orders) {
    bool hasNew = false;
    for (var o in orders) {
      if (!_notifiedReadyOrderIds.contains(o.id)) {
        _notifiedReadyOrderIds.add(o.id);
        hasNew = true;
      }
    }

    if (hasNew && state.availableOrders.isNotEmpty) {
      _alertService.triggerNewOrderAlert();
      
      // Log received for foreground orders
      for (var o in orders) {
        _analytics.logDeliveryNotificationReceived(
          orderId: o.id,
          orderStatus: o.status.toString(),
        );
      }
    }
  }

  Future<void> pickupOrder(String orderId) async {
    if (_userId == null) return;
    
    // Assign to current user
    final success = await _repo.assignDeliveryPerson(orderId, _userId, ifUnassigned: true);
    if (!success) {
      throw Exception('orderAlreadyAssigned');
    }

    // Update status to out_for_delivery
    await _repo.updateOrderStatus(
      orderId: orderId,
      status: OrderStatus.outForDelivery,
      changedBy: _userId,
    );

    // Log pickup
    _analytics.logDeliveryPickupStarted(orderId: orderId);
  }

  @override
  void dispose() {
    _availableSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
