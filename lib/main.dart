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
import 'services/notification_service.dart';
import 'core/update/update_service.dart';
import 'shared/utils/responsive_layout.dart';
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
    
    // Initialize background services (Non-blocking)
    SupabaseService.initialize().catchError((e) => debugPrint('SANGAK ERROR: Supabase init failed: $e'));
    NotificationService.initialize().catchError((e) => debugPrint('SANGAK ERROR: Firebase init failed: $e'));
    
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
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('An error occurred while starting the app.')),
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

    // Sync navigator key for push notification handling
    NotificationService.setNavigatorKey(router.configuration.navigatorKey);

    return MaterialApp.router(
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
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        // Safely determine if we are in a workstation route (staff/admin)
        bool isWorkstation = false;
        try {
          // GoRouter 14+ safe URI extraction
          final String path = router.routerDelegate.currentConfiguration.uri.path;
          isWorkstation = path.startsWith('/staff') || path.startsWith('/admin');
        } catch (_) {
          // Fallback to mobile width during initial load or error
        }
        
        return ResponsiveLayout(
          maxWidth: isWorkstation ? ResponsiveLayout.workstationMaxWidth : ResponsiveLayout.mobileMaxWidth,
          child: child,
        );
      },
    );
  }
}
