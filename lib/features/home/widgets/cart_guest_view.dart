import 'package:flutter/material.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../shared/widgets/sangak_button.dart';
import '../../../shared/widgets/app_logo.dart';
import 'package:go_router/go_router.dart';

class CartGuestView extends StatelessWidget {
  const CartGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SangakColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(SangakDimens.spacing32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo.medium(),
              const SizedBox(height: SangakDimens.spacing32),
              Text(
                'Your basket is waiting',
                style: SangakTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing12),
              Text(
                'Create an account to save your items, track orders, and complete your checkout effortlessly.',
                style: SangakTypography.bodyLarge.copyWith(color: SangakColors.inkLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing40),
              SangakButton.primary(
                label: 'Create Account',
                width: double.infinity,
                onPressed: () => context.push('/register'),
              ),
              const SizedBox(height: SangakDimens.spacing12),
              SangakButton.ghost(
                label: 'Sign In',
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
