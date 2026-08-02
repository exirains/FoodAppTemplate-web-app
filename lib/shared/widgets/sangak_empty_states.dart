import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import 'sangak_button.dart';

/// Sangak Design System Empty States (v1.0.0)
class SangakEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SangakEmptyState({
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
      padding: const EdgeInsets.all(SangakDimens.spacing48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SangakDimens.spacing24),
            decoration: BoxDecoration(
              color: SangakColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: SangakColors.primary),
          ),
          const SizedBox(height: SangakDimens.spacing24),
          Text(title, style: SangakTypography.h2(context), textAlign: TextAlign.center),
          const SizedBox(height: SangakDimens.spacing8),
          Text(
            message,
            style: SangakTypography.bodyMedium(context).copyWith(color: SangakColors.inkLight),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: SangakDimens.spacing32),
            SangakButton.primary(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
