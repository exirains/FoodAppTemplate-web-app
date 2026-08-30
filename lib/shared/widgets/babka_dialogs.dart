import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';
import '../../core/design_system/babka_dimens.dart';
import 'babka_button.dart';

class BabkaConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const BabkaConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BabkaConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
      ),
      backgroundColor: BabkaColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(BabkaDimens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: BabkaTypography.h3(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BabkaDimens.spacing12),
            Text(
              message,
              style: BabkaTypography.bodyMedium(context).copyWith(color: BabkaColors.inkLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BabkaDimens.spacing32),
            Row(
              children: [
                Expanded(
                  child: BabkaButton.ghost(
                    label: cancelLabel,
                    padding: const EdgeInsets.symmetric(horizontal: BabkaDimens.spacing12),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: BabkaDimens.spacing12),
                Expanded(
                  child: BabkaButton.primary(
                    label: confirmLabel,
                    padding: const EdgeInsets.symmetric(horizontal: BabkaDimens.spacing12),
                    backgroundColor: isDestructive ? BabkaColors.error : null,
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context, true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

