import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../features/auth/profile_provider.dart';
import '../../main.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;

  LocaleNotifier(this._ref) : super(const Locale('en')) {
    _init();
    _listenToProfileSync();
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

  /// Listens to profile changes and updates local locale if it differs from cloud preference.
  /// This handles multi-device synchronization and fresh logins.
  void _listenToProfileSync() {
    _ref.listen(userProfileProvider, (previous, next) {
      final profile = next.asData?.value;
      if (profile != null) {
        final cloudLang = profile.preferredLanguage;
        final localLang = state.languageCode;

        // Only update local if cloud differs from local
        if (cloudLang != localLang) {
          debugPrint('🌐 LocaleNotifier: Cloud preference ($cloudLang) differs from local ($localLang).');
          
          // CRITICAL: We adopt the cloud value as the source of truth for logged-in users.
          // This ensures that if they change language on one device, it reflects on others.
          state = Locale(cloudLang);
          _ref.read(storageServiceProvider).setLanguage(cloudLang);
          debugPrint('✅ LocaleNotifier: Local locale updated to match cloud');
        }
      }
    });
  }

  Future<void> setLocale(String languageCode) async {
    // 1. Validation
    if (!['en', 'tr', 'fa'].contains(languageCode)) {
      debugPrint('🚨 LocaleNotifier: Invalid language code attempted: $languageCode');
      return;
    }

    // 2. Update local state and storage
    try {
      final currentStored = _ref.read(storageServiceProvider).language;
      
      // Even if state matches, we must ensure storage is populated 
      // (Fixes bug where first language selection screen "Continue" does nothing for English)
      if (currentStored != languageCode) {
        await _ref.read(storageServiceProvider).setLanguage(languageCode);
      }
      
      if (state.languageCode != languageCode) {
        state = Locale(languageCode);
      }
    } catch (e) {
      debugPrint('🚨 LocaleNotifier: Local storage update failed: $e');
      state = Locale(languageCode);
    }

    // 3. Sync to Supabase profile for localized notifications
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        debugPrint('🌐 LocaleNotifier: Syncing new locale "$languageCode" to Supabase for user ${user.id}');
        
        // We use .update().select() to verify the update happened and trigger the stream provider
        final response = await SupabaseService.client
            .from('profiles')
            .update({'preferred_language': languageCode})
            .eq('id', user.id)
            .select('id, preferred_language');
        
        if (response.isEmpty) {
          debugPrint('⚠️ LocaleNotifier: Supabase update successful but profile row not found/updated.');
        } else {
          debugPrint('✅ LocaleNotifier: Successfully synced locale to Supabase: ${response.first['preferred_language']}');
        }
      } else {
        debugPrint('ℹ️ LocaleNotifier: User not logged in, skipping Supabase sync.');
      }
    } catch (e) {
      debugPrint('🚨 LocaleNotifier: Supabase sync error: $e');
      if (e is PostgrestException) {
        debugPrint('   - Message: ${e.message}');
        debugPrint('   - Code: ${e.code}');
        debugPrint('   - Hint: ${e.hint}');
        debugPrint('   - Details: ${e.details}');
      }
      // We DO NOT revert the local state on failure, as per requirements.
    }
  }
}
