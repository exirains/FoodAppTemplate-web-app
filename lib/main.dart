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
import 'models/address.dart';

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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('SANGAK: Initializing app...');
    
    // Initialize Hive
    await Hive.initFlutter();
    debugPrint('SANGAK: Hive initialized.');
    
    Hive.registerAdapter(BreadAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(AddressAdapter());
    
    final cacheBox = await Hive.openBox<List>('cache');
    await cacheBox.clear(); 
    debugPrint('SANGAK: Hive box opened and cleared.');
    
    // Initialize Supabase
    try {
      await SupabaseService.initialize();
      debugPrint('SANGAK: Supabase initialized.');
    } catch (e) {
      debugPrint('SANGAK ERROR: Supabase init failed: $e');
      // On web, this might be due to .env issues
    }
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    debugPrint('SANGAK: SharedPrefs initialized.');
    
    runApp(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageService(prefs)),
        ],
        child: const SangakApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('SANGAK CRITICAL ERROR: $e');
    debugPrint('STACK TRACE: $stack');
    
    // Fallback to minimal app to show error if possible
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('App failed to start: $e')),
      ),
    ));
  }
}

class SangakApp extends ConsumerWidget {
  const SangakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return Container(
      color: const Color(0xFFFDFCF8), // Natural Paper background to avoid black flash
      child: MaterialApp.router(
        title: 'Sangak',
        debugShowCheckedModeBanner: false,
        theme: SangakTheme.light(locale),
        routerConfig: router,
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
