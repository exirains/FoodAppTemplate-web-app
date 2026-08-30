import 'package:flutter/material.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../../core/design_system/babka_colors.dart';
import '../../../core/design_system/babka_typography.dart';
import '../../../core/design_system/babka_dimens.dart';
import '../../../shared/widgets/babka_button.dart';
import 'package:go_router/go_router.dart';

class ProfileGuestView extends StatelessWidget {
  const ProfileGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: BabkaColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(BabkaDimens.spacing32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: BabkaColors.primary),
              const SizedBox(height: BabkaDimens.spacing32),
              Text(
                l10n.joinTheFamily,
                style: BabkaTypography.h2(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BabkaDimens.spacing12),
              Text(
                l10n.profileGuestMessage,
                style: BabkaTypography.bodyLarge(context).copyWith(color: BabkaColors.inkLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BabkaDimens.spacing40),
              BabkaButton.primary(
                label: l10n.createAccount,
                width: double.infinity,
                onPressed: () => context.push('/signup-choice'),
              ),
              const SizedBox(height: BabkaDimens.spacing12),
              BabkaButton.outlined(
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

