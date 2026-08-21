import 'package:flutter/material.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../shared/widgets/sangak_button.dart';
import 'package:go_router/go_router.dart';

class ProfileGuestView extends StatelessWidget {
  const ProfileGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: SangakColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(SangakDimens.spacing32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: SangakColors.primary),
              const SizedBox(height: SangakDimens.spacing32),
              Text(
                l10n.joinTheFamily,
                style: SangakTypography.h2(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing12),
              Text(
                l10n.profileGuestMessage,
                style: SangakTypography.bodyLarge(context).copyWith(color: SangakColors.inkLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing40),
              SangakButton.primary(
                label: l10n.createAccount,
                width: double.infinity,
                onPressed: () => context.push('/signup-choice'),
              ),
              const SizedBox(height: SangakDimens.spacing12),
              SangakButton.outlined(
                label: l10n.signIn,
                width: double.infinity,
                onPressed: () => context.push('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
