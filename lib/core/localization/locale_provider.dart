import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;

  LocaleNotifier(this._ref) : super(const Locale('en')) {
    _init();
  }

  void _init() {
    final languageCode = _ref.read(storageServiceProvider).language;
    if (languageCode != null) {
      state = Locale(languageCode);
    } else {
      // Default to platform locale or English
      state = const Locale('en');
    }
  }

  Future<void> setLocale(String languageCode) async {
    await _ref.read(storageServiceProvider).setLanguage(languageCode);
    state = Locale(languageCode);
  }
}
