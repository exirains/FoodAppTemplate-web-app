import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PendingAction = void Function();

final pendingActionProvider = StateNotifierProvider<PendingActionNotifier, PendingAction?>((ref) {
  return PendingActionNotifier();
});

class PendingActionNotifier extends StateNotifier<PendingAction?> {
  PendingActionNotifier() : super(null);

  void set(PendingAction action) {
    state = action;
  }

  void execute() {
    if (state != null) {
      state!();
      state = null;
    }
  }

  void clear() {
    state = null;
  }
}
