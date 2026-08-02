import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'auth_error_handler.dart';
import 'auth_rate_limiter.dart';
import 'auth_validators.dart';

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

  /// Sign in with email and password
  /// Includes rate limiting and friendly error handling
  Future<User?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    
    // Sanitize and validate inputs
    email = AuthValidators.sanitizeEmail(email);
    
    try {
      // Check rate limiting
      if (!authRateLimiter.isAllowed(email)) {
        final secondsLeft = authRateLimiter.getSecondsUntilRetry(email);
        throw AuthRateLimitException(
          'Too many login attempts. Try again in $secondsLeft seconds.',
        );
      }

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Record successful attempt
      authRateLimiter.recordSuccess(email);
      
      state = AsyncValue.data(response.user);
      return response.user;
    } catch (e, stack) {
      // Record failed attempt for rate limiting
      authRateLimiter.recordFailure(email);
      
      // Convert to user-friendly error
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final error = AuthException(
        message: messageKey,
        originalError: e,
        isLocalizedKey: true,
      );
      
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Sign up with email, password, name, and optional phone
  /// Includes validation and friendly error handling
  Future<User?> signUp(
    String email,
    String password,
    String fullName, {
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    
    // Sanitize and validate inputs
    email = AuthValidators.sanitizeEmail(email);
    fullName = AuthValidators.sanitizeName(fullName);
    if (phone != null) {
      phone = AuthValidators.sanitizePhoneNumber(phone);
    }
    
    try {
      // Check rate limiting
      if (!authRateLimiter.isAllowed(email)) {
        final secondsLeft = authRateLimiter.getSecondsUntilRetry(email);
        throw AuthRateLimitException(
          'Too many registration attempts. Try again in $secondsLeft seconds.',
        );
      }

      final data = {
        'full_name': fullName,
        ...?phone == null ? null : {'phone': phone},
      };
      
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      
      // Record successful attempt
      authRateLimiter.recordSuccess(email);
      
      state = AsyncValue.data(response.user);
      return response.user;
    } catch (e, stack) {
      // Record failed attempt for rate limiting
      authRateLimiter.recordFailure(email);
      
      // Convert to user-friendly error
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final error = AuthException(
        message: messageKey,
        originalError: e,
        isLocalizedKey: true,
      );
      
      state = AsyncValue.error(error, stack);
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

  /// Sign in with Google OAuth
  /// Includes error handling for cancellation and network failures
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
      // Check if it's a user cancellation vs real error
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('cancel') ||
          errorString.contains('user_cancelled') ||
          errorString.contains('popup_closed')) {
        // User cancelled - don't show as error
        return;
      }
      
      // Convert to user-friendly error
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final error = AuthException(
        message: messageKey,
        originalError: e,
        isLocalizedKey: true,
      );
      
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

/// Custom exception for auth errors with localization support
class AuthException implements Exception {
  /// Message key for localization (e.g., 'invalidCredentials')
  final String message;
  
  /// Original error from Supabase or other source
  final dynamic originalError;
  
  /// Whether message is a localization key (true) or plain text (false)
  final bool isLocalizedKey;

  AuthException({
    required this.message,
    this.originalError,
    this.isLocalizedKey = true,
  });

  @override
  String toString() => message;
}

/// Exception for rate limiting
class AuthRateLimitException implements Exception {
  final String message;

  AuthRateLimitException(this.message);

  @override
  String toString() => message;
}
