import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/sangak_theme.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';

import 'services/update_service.dart';

// Providers for services
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError();
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: const SangakApp(),
    ),
  );
}

class SangakApp extends StatelessWidget {
  const SangakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sangak',
      debugShowCheckedModeBanner: false,
      theme: SangakTheme.light,
      routerConfig: appRouter,
    );
  }
}
