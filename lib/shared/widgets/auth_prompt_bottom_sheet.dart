import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import 'babka_button.dart';
import 'app_logo.dart';

class AuthPromptBottomSheet extends StatelessWidget {
  final String? title;
  final String? message;
  final String? imageUrl;
  final VoidCallback? onMaybeLater;
  final bool showMaybeLater;
  final bool showLogo;

  const AuthPromptBottomSheet({
    super.key,
    this.title,
    this.message,
    this.imageUrl,
    this.onMaybeLater,
    this.showMaybeLater = true,
    this.showLogo = true,
  });

  static Future<String?> show(
    BuildContext context, {
    String? title,
    String? message,
    String? imageUrl,
    VoidCallback? onMaybeLater,
    bool showMaybeLater = true,
    bool showLogo = true,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AuthPromptBottomSheet(
        title: title,
        message: message,
        imageUrl: imageUrl,
        onMaybeLater: onMaybeLater,
        showMaybeLater: showMaybeLater,
        showLogo: showLogo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(BabkaDimens.spacing24)),
      ),
      padding: EdgeInsets.fromLTRB(
        BabkaDimens.spacing24,
        BabkaDimens.spacing16,
        BabkaDimens.spacing24,
        mediaQuery.viewInsets.bottom + BabkaDimens.spacing24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: BabkaDimens.spacing24),
            // Logo or Icon
            if (showLogo)
              const AppLogo.medium()
            else if (imageUrl != null)
              Image.asset(
                imageUrl!,
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: BabkaColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BabkaDimens.spacing16),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  size: 40,
                  color: BabkaColors.primary,
                ),
              ),
            const SizedBox(height: BabkaDimens.spacing24),
            // Title
            Text(
              title ?? l10n.createAccount,
              style: BabkaTypography.h2(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BabkaDimens.spacing12),
            // Message
            Text(
              message ?? l10n.basketGuestMessage,
              style: BabkaTypography.bodyLarge(context).copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BabkaDimens.spacing40),
            // Create Account button
            BabkaButton.primary(
              label: l10n.createAccount,
              width: double.infinity,
              onPressed: () {
                context.pop('register');
              },
            ),
            const SizedBox(height: BabkaDimens.spacing12),
            // Sign In button
            BabkaButton.outlined(
              label: l10n.signIn,
              width: double.infinity,
              onPressed: () {
                context.pop('login');
              },
            ),
            if (showMaybeLater) ...[
              const SizedBox(height: BabkaDimens.spacing12),
              TextButton(
                onPressed: () {
                  onMaybeLater?.call();
                  context.pop();
                },
                child: Text(
                  l10n.maybeLater,
                  style: BabkaTypography.bodyMedium(context).copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

