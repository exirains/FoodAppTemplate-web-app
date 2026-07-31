import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://obealvlqkffozfigtobc.supabase.co',
      publishableKey: 'sb_publishable_TNlYa89a1LyOQ4Z3janYFQ_1lc5gkSk',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
