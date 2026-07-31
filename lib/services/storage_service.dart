import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyLanguage = 'selected_language';
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyCart = 'local_cart';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_keyLanguage, languageCode);
  }

  String? get language => _prefs.getString(_keyLanguage);

  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool(_keyFirstLaunch, isFirstLaunch);
  }

  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;

  Future<void> saveCart(String cartJson) async {
    await _prefs.setString(_keyCart, cartJson);
  }

  String? get cart => _prefs.getString(_keyCart);
}
