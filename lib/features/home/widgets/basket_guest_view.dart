import 'package:flutter/material.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../../core/design_system/babka_colors.dart';
import '../../../core/design_system/babka_typography.dart';
import '../../../core/design_system/babka_dimens.dart';
import '../../../shared/widgets/babka_button.dart';
import '../../../shared/widgets/app_logo.dart';
import 'package:go_router/go_router.dart';

class BasketGuestView extends StatelessWidget {
  const BasketGuestView({super.key});

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
              const AppLogo.medium(),
              const SizedBox(height: BabkaDimens.spacing32),
              Text(
                l10n.yourBasketIsWaiting,
                style: BabkaTypography.h2(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BabkaDimens.spacing12),
              Text(
                l10n.basketGuestMessage,
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
              BabkaButton.ghost(
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

