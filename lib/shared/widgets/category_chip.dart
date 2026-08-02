import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';
import '../../core/design_system/sangak_tokens.dart';

/// Sangak Design System Category Chip (v1.0.0)
class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
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
          vertical: SangakDimens.spacing12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? SangakColors.primary : SangakColors.surface,
          borderRadius: BorderRadius.circular(SangakDimens.radiusPill),
          border: Border.all(
            color: isSelected ? SangakColors.primary : SangakColors.border,
            width: 1,
          ),
          boxShadow: isSelected ? SangakDimens.shadowLow : null,
        ),
        child: Text(
          label,
          style: SangakTypography.title(context).copyWith(
            color: isSelected ? Colors.white : SangakColors.inkLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
