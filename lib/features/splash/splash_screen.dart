import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_tokens.dart';
import '../../main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../shared/widgets/app_logo.dart';
import '../../core/update/update_dialog.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SangakTokens.curveEmphasized,
      ),
    );

    _controller.forward();
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Artificial delay for the "Signature Brand Moment"
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Check for Updates
    final updateService = ref.read(updateServiceProvider);
    final updateInfo = await updateService.checkForUpdates();

    if (updateInfo != null && mounted) {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: !updateInfo.forceUpdate,
        builder: (context) => UpdateDialog(
          updateInfo: updateInfo,
          currentVersion: packageInfo.version,
          onUpdate: () => updateService.launchUpdateUrl(updateInfo.apkUrl),
          onDismiss: updateInfo.forceUpdate ? null : () => Navigator.pop(context),
        ),
      );
      if (updateInfo.forceUpdate) return; // Halt if forced and not updated
    }

    if (!mounted) return;

    final storage = ref.read(storageServiceProvider);
    final language = storage.language;
    final isFirstLaunch = storage.isFirstLaunch;

    if (isFirstLaunch || language == null) {
      // Mark first launch as done when they reach language selection
      await storage.setFirstLaunch(false);
      if (mounted) context.go('/language');
      return;
    }

    // Guest flow: Always go home
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: SangakColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Hero(
                  tag: 'app_logo',
                  child: AppLogo.large(),
                ),
                const SizedBox(height: 56), // More space
                Text(
                  l10n.appName.toUpperCase(),
                  style: SangakTypography.display(context).copyWith(
                    letterSpacing: 8, // Heroic spacing
                    color: SangakColors.primary,
                    fontSize: 48, // Flagship size
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.bakerySubtitle.toUpperCase(),
                  style: SangakTypography.subtitle(context).copyWith(
                    letterSpacing: 4,
                    fontSize: 16,
                    color: SangakColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
