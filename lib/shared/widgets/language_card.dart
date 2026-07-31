import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';

class LanguageCard extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SangakTokens.animFast,
        padding: const EdgeInsets.symmetric(
          horizontal: SangakDimens.spacing24,
          vertical: SangakDimens.spacing24,
        ),
        decoration: BoxDecoration(
          color: isSelected ? SangakColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(SangakDimens.radiusL),
          border: Border.all(
            color: isSelected ? SangakColors.primary : SangakColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? SangakDimens.shadowLow : null,
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: SangakDimens.spacing16),
            Text(
              label,
              style: SangakTypography.title.copyWith(
                color: isSelected ? SangakColors.primary : SangakColors.ink,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: SangakColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
