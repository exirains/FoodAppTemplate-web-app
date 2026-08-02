import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sangak/l10n/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/sangak_theme.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';
import 'services/favorite_service.dart';
import 'services/cache_service.dart';
import 'core/update/update_service.dart';
import 'models/bread.dart';
import 'models/category.dart';

// Providers for services
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError();
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(BreadAdapter());
  Hive.registerAdapter(CategoryAdapter());
  final cacheBox = await Hive.openBox<List>('cache');
  await cacheBox.clear(); // Clear cache to ensure fresh schema data with descriptions
  
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

class SangakApp extends ConsumerWidget {
  const SangakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return Container(
      color: const Color(0xFFFDFCF8), // Natural Paper background to avoid black flash
      child: MaterialApp.router(
        title: 'Sangak',
        debugShowCheckedModeBanner: false,
        theme: SangakTheme.light,
        routerConfig: appRouter,
        locale: locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
