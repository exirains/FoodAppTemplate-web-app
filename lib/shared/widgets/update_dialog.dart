import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../models/update_model.dart';
import 'sangak_button.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateModel updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isMandatory = updateInfo.forceUpdate;

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SangakDimens.radiusXL),
        ),
        backgroundColor: SangakColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(SangakDimens.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Update Available',
                style: SangakTypography.h2,
              ),
              const SizedBox(height: SangakDimens.spacing8),
              Text(
                'A new version (${updateInfo.version}) of Sangak is available. Update now to enjoy the latest features and improvements.',
                style: SangakTypography.bodyMedium,
              ),
              const SizedBox(height: SangakDimens.spacing16),
              if (updateInfo.changelog.isNotEmpty) ...[
                Text(
                  "What's New:",
                  style: SangakTypography.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: SangakDimens.spacing8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: updateInfo.changelog.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              updateInfo.changelog[index],
                              style: SangakTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: SangakDimens.spacing32),
              Row(
                children: [
                  if (!isMandatory)
                    Expanded(
                      child: SangakButton.ghost(
                        label: 'Later',
                        onPressed: onDismiss ?? () => Navigator.pop(context),
                      ),
                    ),
                  if (!isMandatory) const SizedBox(width: SangakDimens.spacing12),
                  Expanded(
                    child: SangakButton.primary(
                      label: 'Update Now',
                      onPressed: onUpdate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
