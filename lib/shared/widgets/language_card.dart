import 'package:flutter/material.dart';
import '../../core/design_system/babka_colors.dart';
import '../../core/design_system/babka_typography.dart';

/// Babka Design System Language Card (v1.1.0)
///
/// Refined with 200ms animation and tactile selection feel.
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected 
                  ? BabkaColors.primary.withValues(alpha: 0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? BabkaColors.primary 
                    : BabkaColors.border.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: BabkaTypography.title(context).copyWith(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? BabkaColors.primary : BabkaColors.ink,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: BabkaColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

