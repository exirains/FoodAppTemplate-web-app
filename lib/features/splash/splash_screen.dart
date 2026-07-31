import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Artificial delay for the "Signature Brand Moment"
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // In a real app, check auth state here. 
      // For now, go to Gallery to show off the system, 
      // but the requirement says "the normal app should still start with the Splash screen".
      // I'll add a button or just navigate to a placeholder home.
      context.go('/gallery'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SangakColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Placeholder
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SangakColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bakery_dining,
                size: 80,
                color: SangakColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'SANGAK',
              style: SangakTypography.display.copyWith(
                letterSpacing: 4,
                color: SangakColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Artisan Persian Bakery',
              style: SangakTypography.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
