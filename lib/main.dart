import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sangak/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/sangak_theme.dart';
import 'services/supabase_service.dart';
import 'services/storage_service.dart';
import 'services/favorite_service.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'core/update/update_service.dart';
import 'features/auth/auth_provider.dart';
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

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('SANGAK: Firebase ready.');
    
    // 1. Initialize Hive (Essential for local state)
    await Hive.initFlutter();
    Hive.registerAdapter(BreadAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(AddressAdapter());
    
    // Clear cache box safely
    try {
      final cacheBox = await Hive.openBox('cache');
      await cacheBox.clear();
    } catch (e) {
      debugPrint('Hive Cache Error: $e');
    }
    
    // 2. Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    
    // 2.5 Handle Deep Links (Referral Links)
    final appLinks = AppLinks();
    
    // Check for initial link (Cold Start)
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        final refCode = initialUri.queryParameters['ref']?.trim();
        if (refCode != null && refCode.isNotEmpty) {
          await storage.setReferralCode(refCode);
          debugPrint('SANGAK: Initial referral code captured: $refCode');
        }
      }
    } catch (e) {
      debugPrint('SANGAK: Deep link error: $e');
    }

    // 3. Initialize Critical Services (Must await Supabase to avoid FCM null-check errors)
    await SupabaseService.initialize();
    debugPrint('SANGAK: Supabase ready.');

    // 4. Initialize background services
    NotificationService.initialize().catchError((e) => debugPrint('SANGAK ERROR: Firebase init failed: $e'));
    
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
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Initialization Error: $e')),
      ),
    ));
  }
}

class SangakApp extends ConsumerStatefulWidget {
  const SangakApp({super.key});

  @override
  ConsumerState<SangakApp> createState() => _SangakAppState();
}

class _SangakAppState extends ConsumerState<SangakApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      final refCode = uri.queryParameters['ref']?.trim();
      if (refCode != null && refCode.isNotEmpty) {
        debugPrint('SANGAK: Incoming stream referral code: $refCode');
        // Update both the provider and persistent storage
        ref.read(pendingReferralProvider.notifier).state = refCode;
        ref.read(storageServiceProvider).setReferralCode(refCode);
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

        return Material(
          color: const Color(0xFFFDFCF8),
          child: child,
        );
      },
    );
  }
}
