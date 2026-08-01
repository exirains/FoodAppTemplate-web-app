import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import 'sangak_button.dart';

class SangakConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const SangakConfirmDialog({
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
      builder: (context) => SangakConfirmDialog(
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
        borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
      ),
      backgroundColor: SangakColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(SangakDimens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: SangakTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SangakDimens.spacing12),
            Text(
              message,
              style: SangakTypography.bodyMedium.copyWith(color: SangakColors.inkLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SangakDimens.spacing32),
            Row(
              children: [
                Expanded(
                  child: SangakButton.ghost(
                    label: cancelLabel,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: SangakDimens.spacing12),
                Expanded(
                  child: SangakButton.primary(
                    label: confirmLabel,
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
