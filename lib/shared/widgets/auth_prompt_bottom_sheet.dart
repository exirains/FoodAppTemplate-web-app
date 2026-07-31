import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import 'sangak_button.dart';
import 'app_logo.dart';

class AuthPromptBottomSheet extends StatelessWidget {
  final String title;
  final String message;

  const AuthPromptBottomSheet({
    super.key,
    this.title = 'Create your Sangak account',
    this.message = 'Create an account to add products to your basket and manage orders.',
  });

  static Future<void> show(BuildContext context, {String? title, String? message}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AuthPromptBottomSheet(
        title: title ?? 'Create your Sangak account',
        message: message ?? 'Create an account to add products to your basket and manage orders.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SangakColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SangakDimens.radiusXL)),
      ),
      padding: const EdgeInsets.fromLTRB(
        SangakDimens.spacing24,
        SangakDimens.spacing16,
        SangakDimens.spacing24,
        SangakDimens.spacing48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SangakColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: SangakDimens.spacing32),
          const AppLogo.medium(),
          const SizedBox(height: SangakDimens.spacing24),
          Text(
            title,
            style: SangakTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SangakDimens.spacing12),
          Text(
            message,
            style: SangakTypography.bodyLarge.copyWith(color: SangakColors.inkLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SangakDimens.spacing40),
          SangakButton.primary(
            label: 'Create Account',
            width: double.infinity,
            onPressed: () {
              Navigator.pop(context);
              context.push('/register');
            },
          ),
          const SizedBox(height: SangakDimens.spacing12),
          SangakButton.ghost(
            label: 'Sign In',
            width: double.infinity,
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
          ),
        ],
      ),
    );
  }
}
