import 'package:flutter/material.dart';
import '../../../core/design_system/sangak_colors.dart';
import '../../../core/design_system/sangak_typography.dart';
import '../../../core/design_system/sangak_dimens.dart';
import '../../../shared/widgets/sangak_button.dart';
import 'package:go_router/go_router.dart';

class ProfileGuestView extends StatelessWidget {
  const ProfileGuestView({super.key});

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
              const Icon(Icons.person_outline, size: 80, color: SangakColors.primary),
              const SizedBox(height: SangakDimens.spacing32),
              Text(
                'Join the Sangak family',
                style: SangakTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing12),
              Text(
                'Sign in to manage your profile, view order history, and access exclusive bakery offers.',
                style: SangakTypography.bodyLarge.copyWith(color: SangakColors.inkLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangakDimens.spacing40),
              SangakButton.primary(
                label: 'Sign In / Register',
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
