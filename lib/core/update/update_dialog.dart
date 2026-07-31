import 'package:flutter/material.dart';
import 'package:sangak/l10n/app_localizations.dart';
import '../design_system/sangak_colors.dart';
import '../design_system/sangak_typography.dart';
import '../design_system/sangak_dimens.dart';
import '../../shared/widgets/sangak_button.dart';
import 'update_model.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateModel updateInfo;
  final String currentVersion;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersion,
    required this.onUpdate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isMandatory = updateInfo.forceUpdate;
    final l10n = AppLocalizations.of(context);

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
                l10n.newUpdateAvailable,
                style: SangakTypography.h2,
              ),
              const SizedBox(height: SangakDimens.spacing16),
              _buildVersionInfo(l10n),
              const SizedBox(height: SangakDimens.spacing24),
              if (updateInfo.notes.isNotEmpty) ...[
                Text(
                  l10n.whatsNew,
                  style: SangakTypography.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: SangakDimens.spacing8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: updateInfo.notes.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              updateInfo.notes[index],
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
                        label: l10n.later,
                        onPressed: onDismiss ?? () => Navigator.pop(context),
                      ),
                    ),
                  if (!isMandatory) const SizedBox(width: SangakDimens.spacing12),
                  Expanded(
                    child: SangakButton.primary(
                      label: l10n.updateNow,
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

  Widget _buildVersionInfo(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(SangakDimens.spacing12),
      decoration: BoxDecoration(
        color: SangakColors.background,
        borderRadius: BorderRadius.circular(SangakDimens.radiusM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVersionColumn(l10n.currentVersion, currentVersion),
          const Icon(Icons.arrow_forward, size: 16, color: SangakColors.inkLight),
          _buildVersionColumn(l10n.newVersion, updateInfo.version),
        ],
      ),
    );
  }

  Widget _buildVersionColumn(String label, String version) {
    return Column(
      children: [
        Text(label, style: SangakTypography.caption),
        Text(version, style: SangakTypography.title.copyWith(color: SangakColors.primary)),
      ],
    );
  }
}
