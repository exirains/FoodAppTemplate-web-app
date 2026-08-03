import 'package:flutter/material.dart';
import '../../core/design_system/sangak_colors.dart';
import '../../core/design_system/sangak_typography.dart';

enum ProductTagType {
  traditional,
  popular,
  newItem,
  organic,
  general,
}

class ProductTag extends StatelessWidget {
  final String label;
  final ProductTagType? type;
  final IconData? icon;

  const ProductTag({
    super.key,
    required this.label,
    this.type,
    this.icon,
  });

  factory ProductTag.fromText(String tag, {BuildContext? context}) {
    final lower = tag.toLowerCase();
    // Use the actual text from DB but normalized for checking
    if (lower.contains('traditional')) {
      return ProductTag(
        label: 'Traditional',
        type: ProductTagType.traditional,
      );
    } else if (lower.contains('popular')) {
      return ProductTag(
        label: 'Popular',
        type: ProductTagType.popular,
      );
    } else if (lower.contains('new')) {
      return ProductTag(
        label: 'New',
        type: ProductTagType.newItem,
      );
    } else if (lower.contains('organic')) {
      return ProductTag(
        label: 'Organic',
        type: ProductTagType.organic,
      );
    }
    return ProductTag(label: tag, type: ProductTagType.general);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.color.withValues(alpha: 0.45), // Increased opacity for "sticker" feel
        borderRadius: BorderRadius.circular(10), // Softer rounded rectangle
        border: Border.all(color: theme.color.withValues(alpha: 0.25)), // Softer border
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (theme.icon != null) ...[
            Icon(theme.icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label, // Removed .toUpperCase()
            style: SangakTypography.caption(context).copyWith(
              color: Colors.white, // Creamy white for better contrast
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  _TagTheme _getTheme() {
    switch (type ?? ProductTagType.general) {
      case ProductTagType.traditional:
        return _TagTheme(
          color: const Color(0xFF7D4F39), // Oven Brown
          icon: null,
        );
      case ProductTagType.popular:
        return _TagTheme(
          color: const Color(0xFFC68A2B), // Golden
          icon: Icons.local_fire_department_rounded,
        );
      case ProductTagType.newItem:
        return _TagTheme(
          color: const Color(0xFF919D7E), // Sage
          icon: Icons.auto_awesome_rounded,
        );
      case ProductTagType.organic:
        return _TagTheme(
          color: const Color(0xFF6F8F5B), // Deeper Green
          icon: null,
        );
      case ProductTagType.general:
        return _TagTheme(color: SangakColors.accent);
    }
  }
}

class _TagTheme {
  final Color color;
  final IconData? icon;
  const _TagTheme({required this.color, this.icon});
}
