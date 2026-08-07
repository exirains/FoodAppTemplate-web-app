import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/profile_provider.dart';
import '../../features/auth/models/user_profile.dart';

/// A notifier that bridges auth and profile state changes to the GoRouter.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterNotifier(this._ref) {
    // Listen to auth changes and notify the router
    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });

    // Also listen to profile changes (roles)
    _ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});
