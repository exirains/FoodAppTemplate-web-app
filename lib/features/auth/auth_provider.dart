import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    // Also sign out from Google if applicable
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
  }

  Future<void> updateMetadata(Map<String, dynamic> data) async {
    await SupabaseService.client.auth.updateUser(UserAttributes(data: data));
    // The session listener in _init will trigger a state update
  }

  /// Sign in with Google OAuth (Web) or Native (Android)
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final redirectUrl = 'https://app.sangak.tr';
        await SupabaseService.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
      } else {
        // Native Google Sign-In for Android/iOS
        final googleWebClientId = SupabaseService.googleWebClientId;
        
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: googleWebClientId,
        );
        
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return; // User cancelled

        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw AuthException(message: 'No ID Token found.');
        }

        await SupabaseService.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }
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
