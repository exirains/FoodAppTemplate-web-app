import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';

final staffOrdersProvider = StateNotifierProvider<StaffOrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  final repository = ref.read(sangakOrderRepositoryProvider);
  return StaffOrdersNotifier(repository);
});

class StaffOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository _repo;
  StreamSubscription? _subscription;
  final Set<String> _notifiedOrderIds = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _debounceTimer;

  StaffOrdersNotifier(this._repo) : super(const AsyncValue.loading()) {
    // AudioPlayers 6.x defaults to 'assets/' prefix. We use 'lib/assets/'
    _audioPlayer.audioCache.prefix = '';
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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        debugPrint('🔔 [STAFF] New order alert triggered!');
        // AudioPlayers 6.x: AssetSource path relative to prefix.
        // We set prefix to empty, so we use the full asset path registered in pubspec.
        await _audioPlayer.play(
          AssetSource('lib/assets/audio/sangak_chime.mp3'), 
          volume: 1.0,
        );
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 500);
        }
      } catch (e) {
        debugPrint('🚨 [STAFF] Audio alert failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    _audioPlayer.dispose();
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
