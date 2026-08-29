import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/google_mark.dart';
import '../../shared/utils/sangak_toast.dart';
import '../../l10n/app_localizations.dart';
import 'auth_provider.dart';

class LoginChoiceScreen extends ConsumerWidget {
  const LoginChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BabkaDimens.spacing24,
            BabkaDimens.spacing24,
            BabkaDimens.spacing24,
            BabkaDimens.spacing48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppLogo.medium()),
              const SizedBox(height: 48),
              Text(l10n.welcomeBack, style: BabkaTypography.h1(context)),
              const SizedBox(height: 8),
              Text(
                l10n.signInSubtitle,
                style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight),
              ),
              const SizedBox(height: 48),
              
              BabkaButton.outlined(
                label: l10n.continueWithGoogle,
                width: double.infinity,
                leading: const GoogleMark(),
                onPressed: () async {
                  try {
                    final user = await ref.read(authProvider.notifier).signInWithGoogle();
                    if (user != null && context.mounted) {
                      BabkaToast.show(context, l10n.loginSuccessful);
                      context.go('/home');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      BabkaToast.show(context, e.toString());
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              BabkaButton.primary(
                label: l10n.email,
                width: double.infinity,
                icon: Icons.email_outlined,
                onPressed: () => context.push('/login-details'),
              ),
              const SizedBox(height: 32),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.dontHaveAccount, style: BabkaTypography.bodyMedium(context)),
                    GestureDetector(
                      onTap: () => context.push('/signup-choice'),
                      child: Text(
                        l10n.createOne,
                        style: BabkaTypography.title(context).copyWith(
                          color: BabkaColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
