import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import 'babka_button.dart';

/// Babka Design System Empty States (v1.0.0)
class BabkaEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BabkaEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BabkaDimens.spacing48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(BabkaDimens.spacing24),
            decoration: BoxDecoration(
              color: BabkaColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: BabkaColors.primary),
          ),
          const SizedBox(height: BabkaDimens.spacing24),
          Text(title, style: BabkaTypography.h2(context), textAlign: TextAlign.center),
          const SizedBox(height: BabkaDimens.spacing8),
          Text(
            message,
            style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: BabkaDimens.spacing32),
            BabkaButton.primary(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}


