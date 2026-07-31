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

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    // Note: This requires native configuration for google_sign_in
    // and setting up Google provider in Supabase dashboard.
    // For now, providing the basic trigger.
    try {
      await SupabaseService.client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
