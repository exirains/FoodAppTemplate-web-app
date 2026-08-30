import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'auth_error_handler.dart';
import 'auth_rate_limiter.dart';
import 'auth_validators.dart';

import '../../services/referral_repository.dart';
import '../../core/localization/locale_provider.dart';
import '../../main.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});

/// Provider for a pending referral code entered during signup
final pendingReferralProvider = StateProvider<String?>((ref) {
  // Initialize from storage if available
  try {
    final storage = ref.read(storageServiceProvider);
    return storage.referralCode;
  } catch (_) {
    return null;
  }
});

/// Tracks if the automatic redirect for a referral link has already occurred
/// to prevent infinite redirect loops.
final referralRedirectHandledProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final session = SupabaseService.client.auth.currentSession;
    state = AsyncValue.data(session?.user);

    // Listen to auth changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      // Ensure we don't accidentally preserve an error state if a session exists
      state = AsyncValue.data(user);
    }, onError: (e) {
      state = AsyncValue.error(e, StackTrace.current);
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
      
      if (response.user == null) {
        throw AuthException(message: 'invalidCredentials', isLocalizedKey: true);
      }
      
      // Record successful attempt
      authRateLimiter.recordSuccess(email);
      
      if (response.user != null) {
        await _handlePendingReferral(response.user!.id);
      }
      
      state = AsyncValue.data(response.user);
      return response.user;
    } catch (e) {
      // Record failed attempt for rate limiting
      authRateLimiter.recordFailure(email);
      
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final authError = AuthException(
        message: messageKey,
        originalError: e,
        isLocalizedKey: true,
      );
      
      // Keep previous state to avoid breaking the whole UI with an error state
      state = AsyncValue.data(state.asData?.value);
      throw authError;
    }
  }

  /// Sign up with email, password, name, and optional phone/referral
  /// Includes validation and friendly error handling
  Future<User?> signUp(
    String email,
    String password,
    String fullName, {
    String? phone,
    String? referralCode,
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
        if (phone != null) 'phone': phone,
        if (referralCode != null) 'referral_code': referralCode,
      };
      
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      
      // Record successful attempt
      authRateLimiter.recordSuccess(email);
      
      if (response.user != null) {
        // We still call this for immediate reward processing if the DB trigger didn't handle it
        // or for backwards compatibility.
        await _handlePendingReferral(response.user!.id, manualCode: referralCode);
      }
      
      state = AsyncValue.data(response.user);
      return response.user;
    } catch (e) {
      // Record failed attempt for rate limiting
      authRateLimiter.recordFailure(email);
      
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final authError = AuthException(
        message: messageKey,
        originalError: e,
        isLocalizedKey: true,
      );
      
      // Keep previous state to avoid breaking the whole UI with an error state
      state = AsyncValue.data(state.asData?.value);
      throw authError;
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
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final redirectUrl = 'https://app.Babka.tr';
        await SupabaseService.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
        return null; // Redirect happens
      } else {
        // Native Google Sign-In for Android/iOS
        final googleWebClientId = SupabaseService.googleWebClientId;
        
        if (googleWebClientId == null || googleWebClientId.isEmpty) {
          debugPrint('CRITICAL: GOOGLE_WEB_CLIENT_ID is missing in .env file!');
          throw AuthException(
            message: 'Configuration Error: Google Client ID not found. Please check your setup.',
            isLocalizedKey: false,
          );
        }
        
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: googleWebClientId,
        );
        
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null; // User cancelled

        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw AuthException(message: 'No ID Token found.');
        }

        final response = await SupabaseService.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (response.user != null) {
          // Sync/Create profile after successful Google Login
          try {
            final lang = _ref.read(localeProvider).languageCode;
            await SupabaseService.client.from('profiles').upsert({
              'id': response.user!.id,
              'full_name': response.user!.userMetadata?['full_name'] ?? response.user!.email?.split('@')[0] ?? 'User',
              'email': response.user!.email,
              'preferred_language': lang,
            });
          } catch (e) {
            debugPrint('Non-critical: Error syncing profile after Google login: $e');
          }

          // Check if this is a new user for referral processing
          final user = response.user!;
          final isNewUser = user.lastSignInAt == null || 
              (DateTime.tryParse(user.lastSignInAt!)?.difference(DateTime.parse(user.createdAt)).inSeconds.abs() ?? 10) < 5;
          
          if (isNewUser) {
            await _handlePendingReferral(user.id);
          }

          return response.user;
        }
        return null;
      }
    } catch (e) {
      // Check if it's a user cancellation vs real error
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('cancel') ||
          errorString.contains('user_cancelled') ||
          errorString.contains('popup_closed')) {
        // User cancelled - don't show as error
        return null;
      }
      
      final (_, messageKey) = AuthErrorHandler.handleAuthError(e);
      final authError = AuthException(
        message: messageKey,
        originalError: e,
        isLocalizedKey: true,
      );
      
      // Keep previous state to avoid breaking the whole UI with an error state
      state = AsyncValue.data(state.asData?.value);
      throw authError;
    }
  }

  /// Processes a pending referral code for a newly created user
  Future<void> _handlePendingReferral(String userId, {String? manualCode}) async {
    final referralCode = manualCode ?? _ref.read(pendingReferralProvider);
    if (referralCode == null || referralCode.isEmpty) return;

    try {
      final result = await _ref.read(referralRepositoryProvider).processReferralReward(
            referredUserId: userId,
            referralCode: referralCode,
          );

      if (result['success'] == true) {
        debugPrint('✅ Referral processed successfully for user: $userId');
        // Clear the pending referral code after successful processing
        _ref.read(pendingReferralProvider.notifier).state = null;
        await _ref.read(storageServiceProvider).setReferralCode(null);
      } else {
        final error = result['error'] ?? 'unknown_error';
        debugPrint('ℹ️ Referral not processed: $error');
        
        // If it's already referred or invalid, we clear the pending state 
        // to prevent repeated attempts on subsequent logins
        if (error == 'already_referred' || error == 'invalid_code' || error == 'self_referral') {
          _ref.read(pendingReferralProvider.notifier).state = null;
          await _ref.read(storageServiceProvider).setReferralCode(null);
        }
      }
    } catch (e) {
      debugPrint('🚨 Error in _handlePendingReferral: $e');
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

