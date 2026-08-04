import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await dotenv.load();
    } catch (e) {
      // ignore: avoid_print
      print('SupabaseService: .env load failed, checking fallback: $e');
    }
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Missing Supabase configuration. Check your .env file.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  
  static String? get googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'];
}
