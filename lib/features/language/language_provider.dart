import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String?>((ref) {
  return LanguageNotifier(ref);
});

class LanguageNotifier extends StateNotifier<String?> {
  final Ref _ref;

  LanguageNotifier(this._ref) : super(null) {
    _init();
  }

  void _init() {
    state = _ref.read(storageServiceProvider).language;
  }

  Future<void> setLanguage(String code) async {
    await _ref.read(storageServiceProvider).setLanguage(code);
    state = code;
  }
}
