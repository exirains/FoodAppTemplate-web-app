import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/sangak_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: Supabase initialization would go here in a full app.
  // For this design system phase, we focus on the UI foundation.
  
  runApp(
    const ProviderScope(
      child: SangakApp(),
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
