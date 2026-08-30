// Authentication validation utilities for Babka.
// Provides production-level validation for email, password, name, and phone fields.

class AuthValidators {
  /// Maximum length for name field
  static const int maxNameLength = 100;

  /// Minimum length for password
  static const int minPasswordLength = 4;

  /// Maximum length for password
  static const int maxPasswordLength = 128;

  /// Email regex pattern (RFC 5322 simplified)
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  /// Validates email address
  /// - Trims whitespace
  /// - Converts to lowercase
  /// - Checks for valid format
  /// Returns null if valid, error message otherwise
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'required_field'; // Key for localization
    }

    email = email.trim().toLowerCase();

    if (!_emailRegex.hasMatch(email)) {
      return 'invalid_email'; // Key for localization
    }

    return null;
  }

  /// Sanitizes email for authentication
  /// - Trims whitespace
  /// - Converts to lowercase
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Validates password strength
  /// - Minimum 8 characters
  /// - Must contain uppercase letter
  /// - Must contain lowercase letter
  /// - Must contain number
  /// Returns null if valid, error message otherwise
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'required_field'; // Key for localization
    }

    if (password.length < minPasswordLength) {
      return 'password_too_short'; // Key for localization
    }

    if (password.length > maxPasswordLength) {
      return 'password_too_long'; // Key for localization (optional)
    }

    return null;
  }

  /// Calculates password strength (0.0 to 1.0)
  /// 0.0 = very weak, 1.0 = very strong
  static double calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    if (password.length < minPasswordLength) return 0.2;

    double strength = 0.4; // Base strength for meeting requirements

    // Bonus for length
    if (password.length >= 12) strength += 0.2;
    if (password.length >= 16) strength += 0.1;

    // Bonus for special characters
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:''",.<>?/\\|`~]').hasMatch(password)) {
      strength += 0.3;
    }

    return strength.clamp(0.0, 1.0);
  }

  /// Gets password strength label
  /// Returns one of: 'weak', 'fair', 'good', 'strong'
  static String getPasswordStrengthLabel(String password) {
    final strength = calculatePasswordStrength(password);

    if (strength < 0.4) return 'weak';
    if (strength < 0.6) return 'fair';
    if (strength < 0.8) return 'good';
    return 'strong';
  }

  /// Validates that two passwords match
  /// Returns null if valid, error message otherwise
  static String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (password == null || confirmPassword == null) {
      return 'required_field'; // Key for localization
    }

    if (password != confirmPassword) {
      return 'passwords_do_not_match'; // Key for localization
    }

    return null;
  }

  /// Validates name/full name
  /// - Required
  /// - Minimum 2 characters
  /// - Maximum 100 characters
  /// - Cannot be only whitespace
  /// - Trims extra spaces
  /// Returns null if valid, error message otherwise
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'required_field'; // Key for localization
    }

    name = name.trim();

    if (name.isEmpty || name.replaceAll(RegExp(r'\s'), '').isEmpty) {
      return 'required_field'; // Key for localization
    }

    if (name.length < 2) {
      return 'name_too_short'; // Key for localization
    }

    if (name.length > maxNameLength) {
      return 'name_too_long'; // Key for localization
    }

    return null;
  }

  /// Sanitizes name by trimming extra spaces
  /// Converts multiple spaces to single space
  static String sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validates phone number.
  /// - Required
  /// - Removes all non-digit characters for validation
  /// - Must be between 7 and 15 digits (International Standard)
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty || isDefaultPrefixOnly(phone)) {
      return 'required_field'; // Key for localization
    }

    // Remove all non-digits (including spaces and +)
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 7 || digits.length > 15) {
      return 'invalid_phone_number'; // Key for localization
    }

    return null;
  }

  /// Checks if the phone number string only contains the default prefix (+90)
  static bool isDefaultPrefixOnly(String phone) {
    final sanitized = phone.trim().replaceAll(' ', '');
    return sanitized == '+90' || sanitized == '90' || sanitized == '+90 ' || sanitized == '0';
  }

  /// Checks if a profile has a valid phone number linked
  static bool hasValidPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    // Basic check: must have more than just the prefix digits (Turkey = 2 digits '90')
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10; // Standard Turkish mobile is 12 digits (90 + 10)
  }

  /// Sanitizes phone number by trimming whitespace
  static String sanitizePhoneNumber(String phone) {
    return phone.trim();
  }
}

/// Password strength levels for UI display
enum PasswordStrengthLevel {
  weak,
  fair,
  good,
  strong,
}

/// Extension to easily access strength level from double
extension PasswordStrengthExtension on double {
  PasswordStrengthLevel get strengthLevel {
    if (this < 0.4) return PasswordStrengthLevel.weak;
    if (this < 0.6) return PasswordStrengthLevel.fair;
    if (this < 0.8) return PasswordStrengthLevel.good;
    return PasswordStrengthLevel.strong;
  }
}

