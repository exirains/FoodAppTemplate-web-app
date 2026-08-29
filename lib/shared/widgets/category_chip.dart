import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';
import '../../core/design_system/sangak_dimens.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: BabkaDimens.spacing24,
            vertical: BabkaDimens.spacing12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? BabkaColors.primary : BabkaColors.surface,
            borderRadius: BorderRadius.circular(BabkaDimens.radiusPill),
            border: Border.all(
              color: isSelected ? BabkaColors.primary : BabkaColors.border,
              width: 1,
            ),
            boxShadow: isSelected ? BabkaDimens.shadowLow : null,
          ),
          child: Text(
            label,
            style: BabkaTypography.title(context).copyWith(
              color: isSelected ? Colors.white : BabkaColors.inkLight,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
