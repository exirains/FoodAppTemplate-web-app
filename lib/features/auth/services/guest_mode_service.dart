// Guest mode service for managing guest user data.
// Handles local storage of guest data and migration to account.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

class GuestModeService {
  static const String _guestDataKey = 'sangak_guest_user_data';
  static const String _isGuestKey = 'sangak_is_guest_mode';

  /// Check if user is in guest mode
  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? true; // Default to guest mode
  }

  /// Enter guest mode (store preferences)
  static Future<void> enterGuestMode() async {
    await _tryWrite((prefs) => prefs.setBool(_isGuestKey, true));
  }

  /// Exit guest mode (convert to account)
  static Future<void> exitGuestMode() async {
    await _tryWrite((prefs) => prefs.setBool(_isGuestKey, false));
  }

  /// Get current guest data
  static Future<GuestUserData> getGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_guestDataKey);

    if (jsonString == null) {
      return GuestUserData();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GuestUserData.fromJson(json);
    } catch (e) {
      // If data is corrupted, return fresh instance
      return GuestUserData();
    }
  }

  /// Save guest data
  static Future<void> saveGuestData(GuestUserData data) async {
    final json = jsonEncode(data.toJson());
    await _tryWrite((prefs) => prefs.setString(_guestDataKey, json));
  }

  /// Add item to guest basket
  static Future<void> addToGuestBasket(String productId, int quantity) async {
    final guestData = await getGuestData();
    final basketItems = Map<String, int>.from(guestData.basketItems);
    basketItems[productId] = (basketItems[productId] ?? 0) + quantity;

    await saveGuestData(guestData.copyWith(basketItems: basketItems));
  }

  /// Remove item from guest basket
  static Future<void> removeFromGuestBasket(String productId) async {
    final guestData = await getGuestData();
    final basketItems = Map<String, int>.from(guestData.basketItems);
    basketItems.remove(productId);

    await saveGuestData(guestData.copyWith(basketItems: basketItems));
  }

  /// Add product to guest favorites
  static Future<void> addToGuestFavorites(String productId) async {
    final guestData = await getGuestData();
    final favorites = List<String>.from(guestData.favoriteProductIds);

    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await saveGuestData(guestData.copyWith(favoriteProductIds: favorites));
    }
  }

  /// Remove product from guest favorites
  static Future<void> removeFromGuestFavorites(String productId) async {
    final guestData = await getGuestData();
    final favorites = List<String>.from(guestData.favoriteProductIds);
    favorites.remove(productId);

    await saveGuestData(guestData.copyWith(favoriteProductIds: favorites));
  }

  /// Check if product is in guest favorites
  static Future<bool> isInGuestFavorites(String productId) async {
    final guestData = await getGuestData();
    return guestData.favoriteProductIds.contains(productId);
  }

  /// Get guest basket items
  static Future<Map<String, int>> getGuestBasketItems() async {
    final guestData = await getGuestData();
    return guestData.basketItems;
  }

  /// Get guest favorites
  static Future<List<String>> getGuestFavorites() async {
    final guestData = await getGuestData();
    return guestData.favoriteProductIds;
  }

  /// Set preferred language for guest
  static Future<void> setPreferredLanguage(String languageCode) async {
    final guestData = await getGuestData();
    await saveGuestData(guestData.copyWith(preferredLanguage: languageCode));
  }

  /// Set preferred city for delivery
  static Future<void> setPreferredCity(String city) async {
    final guestData = await getGuestData();
    await saveGuestData(guestData.copyWith(selectedCityForDelivery: city));
  }

  /// Get guest data for migration to account
  /// This should be called when user creates an account
  static Future<GuestUserData> getGuestDataForMigration() async {
    return await getGuestData();
  }

  /// Clear guest data after successful account migration
  static Future<void> clearGuestData() async {
    await _tryWrite((prefs) async {
      await prefs.remove(_guestDataKey);
      return prefs.remove(_isGuestKey);
    });
  }

  /// Reset guest mode (clears all data and re-enters guest mode)
  static Future<void> resetGuestMode() async {
    await clearGuestData();
    await enterGuestMode();
  }

  /// Get guest session duration
  /// Useful for analytics and determining if we should prompt for account creation
  static Future<Duration> getGuestSessionDuration() async {
    final guestData = await getGuestData();
    return DateTime.now().difference(guestData.createdAt);
  }

  /// Check if guest has made significant interactions
  /// Used to determine if we should show account prompt
  static Future<bool> hasSignificantInteractions() async {
    final guestData = await getGuestData();

    // Significant interaction = at least one of:
    // - 3+ items in basket
    // - 2+ favorites
    // - Session longer than 5 minutes
    final basketSize = guestData.basketItems.values.fold(0, (a, b) => a + b);
    final favoritesCount = guestData.favoriteProductIds.length;
    final duration = DateTime.now().difference(guestData.createdAt);

    return basketSize >= 3 || favoritesCount >= 2 || duration.inMinutes >= 5;
  }

  static Future<void> _tryWrite(
    Future<bool> Function(SharedPreferences prefs) write,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await write(prefs);
    } catch (e) {
      debugPrint('Storage access blocked: $e');
    }
  }
}
