import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../services/alert_service.dart';
import '../../services/lifecycle_service.dart';

final staffOrdersProvider = StateNotifierProvider<StaffOrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  final repository = ref.read(sangakOrderRepositoryProvider);
  final alertService = ref.read(alertServiceProvider);
  
  // Watch for app resume to recover stale realtime connections
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating Staff Realtime Provider');
      ref.invalidateSelf();
    }
  });

  return StaffOrdersNotifier(repository, alertService);
});

class StaffOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository _repo;
  final AlertService _alertService;
  StreamSubscription? _subscription;
  final Set<String> _notifiedOrderIds = {};

  StaffOrdersNotifier(this._repo, this._alertService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _subscription = _repo.watchAllOrders().listen(
      (event) async {
        try {
          final orders = await _repo.getAllOrders();
          if (mounted) {
            state = AsyncValue.data(orders);
            _checkNewOrders(orders);
          }
        } catch (e, st) {
          if (mounted) state = AsyncValue.error(e, st);
        }
      },
      onError: (e, st) {
        if (mounted) state = AsyncValue.error(e, st);
      },
    );
  }

  void _checkNewOrders(List<OrderModel> orders) {
    final pendingOrders = orders.where((o) => o.status == OrderStatus.pending).toList();
    bool hasNew = false;
    
    for (var o in pendingOrders) {
      if (!_notifiedOrderIds.contains(o.id)) {
        _notifiedOrderIds.add(o.id);
        hasNew = true;
      }
    }

    if (hasNew) {
      _triggerAlert();
    }
  }

  void _triggerAlert() {
    _alertService.triggerNewOrderAlert();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final activeBakeryOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final allOrdersAsync = ref.watch(staffOrdersProvider);
  
  return allOrdersAsync.whenData((orders) {
    return orders.where((o) => 
      o.status == OrderStatus.pending || 
      o.status == OrderStatus.confirmed || 
      o.status == OrderStatus.preparing || 
      o.status == OrderStatus.ready
    ).toList();
  });
});

final pendingOrdersCountProvider = Provider<int>((ref) {
  final ordersAsync = ref.watch(activeBakeryOrdersProvider);
  return ordersAsync.value?.where((o) => o.status == OrderStatus.pending).length ?? 0;
});
