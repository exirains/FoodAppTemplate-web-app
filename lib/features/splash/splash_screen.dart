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
import '../auth/profile_provider.dart';
import '../auth/auth_provider.dart';

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
    // 1. Signature Brand Moment
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // 2. Check for Updates
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
      if (updateInfo.forceUpdate) return; 
    }

    if (!mounted) return;

    // 3. Logic Redirect
    final storage = ref.read(storageServiceProvider);
    
    if (storage.isFirstLaunch || storage.language == null) {
      await storage.setFirstLaunch(false);
      if (mounted) context.go('/language');
      return;
    }

    final pendingReferral = ref.read(pendingReferralProvider);
    if (pendingReferral != null && pendingReferral.isNotEmpty) {
      if (mounted) context.go('/signup-choice');
      return;
    }

    // Role-based initial redirect for logged-in users
    try {
      final profile = await ref.read(userProfileProvider.future).timeout(const Duration(seconds: 3));
      if (mounted) {
        if (profile != null) {
          switch (profile.role) {
            case 'admin':
              context.go('/admin');
              break;
            case 'staff':
              context.go('/staff');
              break;
            case 'delivery':
              context.go('/delivery');
              break;
            default:
              context.go('/home');
          }
        } else {
          context.go('/home');
        }
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
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
                const SizedBox(height: 56), 
                /*
                Text(
                  l10n.appName.toUpperCase(),
                  style: BabkaTypography.display(context).copyWith(
                    letterSpacing: 8, 
                    color: BabkaColors.primary,
                    fontSize: 48, 
                  ),
                ),
                */
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
