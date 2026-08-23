// Handles Supabase authentication errors and converts them to user-friendly messages.
// Provides internationalization-ready error messages using localization keys.

class AuthErrorHandler {
  /// Converts Supabase auth exceptions to user-friendly messages
  /// Returns a tuple of (isNetworkError, messageKey)
  /// messageKey is used with AppLocalizations for i18n
  static (bool isNetworkError, String messageKey) handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection refused') ||
        errorString.contains('failed to connect') ||
        errorString.contains('timeout')) {
      return (true, 'networkError');
    }

    // Invalid credentials / Wrong password
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_grant') ||
        errorString.contains('wrong password') ||
        errorString.contains('unauthorized')) {
      return (false, 'invalidCredentials');
    }

    // Email not confirmed
    if (errorString.contains('email_not_confirmed') ||
        errorString.contains('email not confirmed') ||
        errorString.contains('verify your email')) {
      return (false, 'emailNotVerified');
    }

    // Email already in use
    if (errorString.contains('user already exists') ||
        errorString.contains('duplicate') ||
        errorString.contains('email already in use') ||
        errorString.contains('user_already_exists') ||
        errorString.contains('phone number already registered') ||
        errorString.contains('phone_number_already_registered')) {
      return (false, 'emailAlreadyInUse');
    }

    // Too many requests / Rate limiting
    if (errorString.contains('too_many_requests') ||
        errorString.contains('too many requests') ||
        errorString.contains('rate limit') ||
        errorString.contains('429')) {
      return (false, 'tooManyAttempts');
    }

    // Invalid email format
    if (errorString.contains('invalid email') ||
        errorString.contains('invalid_email')) {
      return (false, 'invalidEmail');
    }

    // Weak password
    if (errorString.contains('password') && 
        (errorString.contains('weak') || errorString.contains('too short'))) {
      return (false, 'passwordTooShort');
    }

    // Diagnostic log for unexpected errors
    // debugPrint('DEBUG AUTH ERROR: $error');

    // Generic auth error fallback
    return (false, 'invalidCredentials');
  }

  /// Determines if an error is temporary (network/rate limit) vs permanent
  static bool isTemporaryError(dynamic error) {
    final (isNetworkError, messageKey) = handleAuthError(error);
    return isNetworkError || messageKey == 'tooManyAttempts';
  }

  /// Determines if user should retry
  static bool shouldRetry(dynamic error) {
    return isTemporaryError(error);
  }
}
