import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import 'lifecycle_service.dart';

class OptionsRepository {
  final _client = SupabaseService.client;

  Future<Map<String, dynamic>> getOptions() async {
    try {
      final List<dynamic> response = await _client.from('options').select('name, value');
      return _parseOptions(response);
    } catch (e) {
      debugPrint('🚨 Error fetching options: $e');
      return {};
    }
  }

  Stream<Map<String, dynamic>> watchOptions() {
    return _client
        .from('options')
        .stream(primaryKey: ['id'])
        .map((data) => _parseOptions(data));
  }

  Future<void> updateOption(String name, dynamic value) async {
    try {
      await _client
          .from('options')
          .upsert({'name': name, 'value': value}, onConflict: 'name');
    } catch (e) {
      debugPrint('🚨 Error updating option $name: $e');
      rethrow;
    }
  }

  Future<void> updateOptions(Map<String, dynamic> updates) async {
    try {
      final List<Map<String, dynamic>> upsertData = updates.entries
          .map((e) => {'name': e.key, 'value': e.value})
          .toList();
      
      await _client.from('options').upsert(upsertData, onConflict: 'name');
    } catch (e) {
      debugPrint('🚨 Error updating multiple options: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseOptions(List<dynamic> data) {
    debugPrint('📡 DB DATA RECEIVED: $data');
    final Map<String, dynamic> options = {};
    for (var row in data) {
      final name = row['name']?.toString().trim(); // Trim to prevent space bugs
      final value = row['value'];
      if (name != null) {
        options[name] = value;
      }
    }
    debugPrint('PARSED OPTIONS MAP: $options');
    return options;
  }
}

final optionsRepositoryProvider = Provider((ref) => OptionsRepository());

final appOptionsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  // Watch for app resume to recover stale realtime connections
  ref.listen(appLifecycleProvider, (previous, next) {
    if (next.value == AppLifecycleState.resumed) {
      debugPrint('♻️ App Resumed: Invalidating App Options Realtime Provider');
      ref.invalidateSelf();
    }
  });

  return ref.read(optionsRepositoryProvider).watchOptions();
});
