import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final session = SupabaseService.client.auth.currentSession;
    state = AsyncValue.data(session?.user);

    // Listen to auth changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = AsyncValue.data(user);
    });
  }

  Future<User?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
      return response.user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password, String fullName) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      state = AsyncValue.data(response.user);
      return response.user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  Future<void> updateMetadata(Map<String, dynamic> data) async {
    await SupabaseService.client.auth.updateUser(UserAttributes(data: data));
    // The session listener in _init will trigger a state update
  }

  Future<void> signInWithGoogle() async {
    final redirectUrl = kIsWeb
        ? 'https://sangak.tr'
        : 'com.sangak.app://login-callback';

    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
