import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await dotenv.load();
    } catch (e) {
      debugPrint('SupabaseService: .env load failed, using hardcoded fallback for Web.');
    }
    
    // Prioritize .env, then fallback to your specific project values
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://oaxgcbuqmhdvmmkrusrv.supabase.co';
    final supabaseKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? 'sb_publishable_0BKyasZ1vCjfm_82735_dw_R6B1Fwgl';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('Missing Supabase configuration.');
    }

    // CRITICAL: Ensure we don't pass the key name as part of the URL
    final cleanUrl = supabaseUrl.contains('=') ? supabaseUrl.split('=').last.trim() : supabaseUrl;
    final cleanKey = supabaseKey.contains('=') ? supabaseKey.split('=').last.trim() : supabaseKey;


    await Supabase.initialize(
      url: cleanUrl,
      publishableKey: cleanKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  
  static String? get googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'];
}
