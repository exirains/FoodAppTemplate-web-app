import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

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
    debugPrint('📊 PARSED OPTIONS MAP: $options');
    return options;
  }
}

final optionsRepositoryProvider = Provider((ref) => OptionsRepository());

final appOptionsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.read(optionsRepositoryProvider).watchOptions();
});
