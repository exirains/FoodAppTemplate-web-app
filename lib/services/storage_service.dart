import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyLanguage = 'selected_language';
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyBasket = 'local_basket';
  static const String _keyAddresses = 'saved_addresses';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> setLanguage(String languageCode) async {
    await _tryWrite(() => _prefs.setString(_keyLanguage, languageCode));
  }

  String? get language => _prefs.getString(_keyLanguage);

  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _tryWrite(() => _prefs.setBool(_keyFirstLaunch, isFirstLaunch));
  }

  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> saveBasket(String basketJson) async {
    await _tryWrite(() => _prefs.setString(_keyBasket, basketJson));
  }

  String? get basket => _prefs.getString(_keyBasket);

  Future<void> saveAddresses(String addressesJson) async {
    await _tryWrite(() => _prefs.setString(_keyAddresses, addressesJson));
  }

  String? get addresses => _prefs.getString(_keyAddresses);

  Future<void> _tryWrite(Future<bool> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('Storage access blocked: $e');
    }
  }
}
