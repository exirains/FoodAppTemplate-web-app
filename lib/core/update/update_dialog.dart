import 'package:flutter/material.dart';
import 'package:babka/l10n/app_localizations.dart';
import '../design_system/babka_colors.dart';
import '../design_system/babka_typography.dart';
import '../design_system/babka_dimens.dart';
import '../../shared/widgets/babka_button.dart';
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BabkaDimens.radiusXL),
        ),
        backgroundColor: BabkaColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(BabkaDimens.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.newUpdateAvailable,
                style: BabkaTypography.h2(context),
              ),
              const SizedBox(height: BabkaDimens.spacing16),
              _buildVersionInfo(l10n, context),
              const SizedBox(height: BabkaDimens.spacing24),
              if (updateInfo.notes.isNotEmpty) ...[
                Text(
                  l10n.whatsNew,
                  style: BabkaTypography.title(context).copyWith(fontSize: 14),
                ),
                const SizedBox(height: BabkaDimens.spacing8),
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
                              style: BabkaTypography.bodySmall(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: BabkaDimens.spacing32),
              Row(
                children: [
                  if (!isMandatory)
                    Expanded(
                      child: BabkaButton.ghost(
                        label: l10n.later,
                        onPressed: onDismiss ?? () => Navigator.pop(context),
                      ),
                    ),
                  if (!isMandatory) const SizedBox(width: 12),
                  Expanded(
                    child: BabkaButton.primary(
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

  Widget _buildVersionInfo(AppLocalizations l10n, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: BabkaDimens.spacing12, horizontal: 8),
      decoration: BoxDecoration(
        color: BabkaColors.background,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusM),
      ),
      child: Row(
        children: [
          Expanded(child: _buildVersionColumn(l10n.currentVersion, currentVersion, context)),
          Icon(Icons.arrow_forward, size: 16, color: BabkaColors.inkLight.withValues(alpha: 0.5)),
          Expanded(child: _buildVersionColumn(l10n.newVersion, updateInfo.version, context)),
        ],
      ),
    );
  }

  Widget _buildVersionColumn(String label, String version, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: BabkaTypography.caption(context), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            version,
            style: BabkaTypography.title(context).copyWith(color: BabkaColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

