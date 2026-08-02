// Service to track and manage user profile completion.
// Used to determine what information is missing and guide users through progressive completion.

import '../models/user_profile.dart';

class ProfileCompletionService {
  /// Get completion percentage (0.0 to 1.0)
  static double getCompletionPercentage(UserProfile? profile) {
    if (profile == null) return 0.0;

    int completedFields = 0;
    int totalFields = 4; // email, name, phone, address

    // Email (required)
    if (profile.email.isNotEmpty) completedFields++;

    // Full name (required for orders)
    if (profile.fullName != null && profile.fullName!.isNotEmpty) completedFields++;

    // Phone number (required for orders)
    if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) {
      completedFields++;
    }

    // Phone verified (optional but good to have)
    if (profile.phoneVerified) completedFields++;

    return completedFields / totalFields;
  }

  /// Get missing required fields
  static List<MissingField> getMissingFields(UserProfile? profile) {
    if (profile == null) {
      return [
        MissingField.email,
        MissingField.name,
        MissingField.phone,
      ];
    }

    final missing = <MissingField>[];

    if (profile.email.isEmpty) missing.add(MissingField.email);
    if (profile.fullName == null || profile.fullName!.isEmpty) missing.add(MissingField.name);
    if (profile.phoneNumber == null || profile.phoneNumber!.isEmpty) {
      missing.add(MissingField.phone);
    }

    return missing;
  }

  /// Get next field that needs completion
  /// Returns null if profile is complete
  static MissingField? getNextMissingField(UserProfile? profile) {
    final missing = getMissingFields(profile);
    if (missing.isEmpty) return null;

    // Priority order
    if (missing.contains(MissingField.email)) return MissingField.email;
    if (missing.contains(MissingField.name)) return MissingField.name;
    if (missing.contains(MissingField.phone)) return MissingField.phone;

    return missing.firstOrNull;
  }

  /// Check if profile is ready for checkout
  static bool isReadyForCheckout(UserProfile? profile) {
    if (profile == null) return false;

    return profile.email.isNotEmpty &&
        profile.fullName != null &&
        profile.fullName!.isNotEmpty &&
        profile.phoneNumber != null &&
        profile.phoneNumber!.isNotEmpty;
  }

  /// Check if profile needs completion before action
  static bool needsCompletion(UserProfile? profile) {
    return getMissingFields(profile).isNotEmpty;
  }

  /// Get completion status summary
  static ProfileCompletionStatus getStatus(UserProfile? profile) {
    final percentage = getCompletionPercentage(profile);

    if (percentage == 0.0) {
      return ProfileCompletionStatus.notStarted;
    } else if (percentage < 0.5) {
      return ProfileCompletionStatus.minimal;
    } else if (percentage < 1.0) {
      return ProfileCompletionStatus.partial;
    } else {
      return ProfileCompletionStatus.complete;
    }
  }
}

/// Enum for missing profile fields
enum MissingField {
  email,
  name,
  phone,
  address,
}

/// Enum for profile completion status
enum ProfileCompletionStatus {
  notStarted,
  minimal,
  partial,
  complete,
}

/// Extension for profile completion status
extension ProfileCompletionStatusX on ProfileCompletionStatus {
  bool get isComplete => this == ProfileCompletionStatus.complete;
  bool get isPartial => this == ProfileCompletionStatus.partial;
  bool get isMinimal => this == ProfileCompletionStatus.minimal;
  bool get isNotStarted => this == ProfileCompletionStatus.notStarted;
}
