import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to monitor App Lifecycle and expose it via Riverpod.
/// Used to recover Realtime connections and refresh data when app resumes.
final lifecycleServiceProvider = Provider((ref) {
  final service = LifecycleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final appLifecycleProvider = StreamProvider<AppLifecycleState>((ref) {
  final service = ref.watch(lifecycleServiceProvider);
  return service.lifecycleStream;
});

class LifecycleService extends WidgetsBindingObserver {
  final _controller = StreamController<AppLifecycleState>.broadcast();
  Stream<AppLifecycleState> get lifecycleStream => _controller.stream;
  
  AppLifecycleState _lastState = AppLifecycleState.resumed;
  AppLifecycleState get lastState => _lastState;

  LifecycleService() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 App Lifecycle Changed: $state');
    _lastState = state;
    _controller.add(state);
  }
}
