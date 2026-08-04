// User profile model for Sangak.
// Represents user data with progressive completion support.

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String role;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.role = 'customer',
    this.phoneVerified = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if profile has minimum required information
  bool get isMinimallyComplete => email.isNotEmpty;

  /// Check if profile is fully complete
  bool get isFullyComplete =>
      email.isNotEmpty &&
      fullName != null &&
      fullName!.isNotEmpty &&
      phoneNumber != null &&
      phoneNumber!.isNotEmpty;

  /// Create a copy with modified fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? role,
    bool? phoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'phone_verified': phoneVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON (Supabase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'customer',
      phoneVerified: (json['phone_verified'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

/// Address model for delivery
class UserAddress {
  final String id;
  final String userId;
  final String title;
  final String address;
  final String city;
  final String? phoneNumber;
  final bool isDefault;
  final DateTime createdAt;

  UserAddress({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    required this.city,
    this.phoneNumber,
    this.isDefault = false,
    required this.createdAt,
  });

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'address': address,
      'city': city,
      'phone_number': phoneNumber,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON (Supabase)
  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      phoneNumber: json['phone_number'] as String?,
      isDefault: (json['is_default'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Guest user state tracking
/// Stores data that should be preserved when guest converts to account
class GuestUserData {
  final List<String> favoriteProductIds;
  final Map<String, int> basketItems; // productId -> quantity
  final String? preferredLanguage;
  final String? selectedCityForDelivery;
  final DateTime createdAt;

  GuestUserData({
    this.favoriteProductIds = const [],
    this.basketItems = const {},
    this.preferredLanguage,
    this.selectedCityForDelivery,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'favorite_product_ids': favoriteProductIds,
      'basket_items': basketItems,
      'preferred_language': preferredLanguage,
      'selected_city_for_delivery': selectedCityForDelivery,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory GuestUserData.fromJson(Map<String, dynamic> json) {
    return GuestUserData(
      favoriteProductIds: List<String>.from(json['favorite_product_ids'] as List? ?? []),
      basketItems: Map<String, int>.from(json['basket_items'] as Map? ?? {}),
      preferredLanguage: json['preferred_language'] as String?,
      selectedCityForDelivery: json['selected_city_for_delivery'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Copy with modifications
  GuestUserData copyWith({
    List<String>? favoriteProductIds,
    Map<String, int>? basketItems,
    String? preferredLanguage,
    String? selectedCityForDelivery,
  }) {
    return GuestUserData(
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      basketItems: basketItems ?? this.basketItems,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      selectedCityForDelivery: selectedCityForDelivery ?? this.selectedCityForDelivery,
      createdAt: createdAt,
    );
  }
}
