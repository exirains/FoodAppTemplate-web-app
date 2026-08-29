import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'sangak_colors.dart';

/// Sangak Design System Tokens (v1.1.0)
///
/// Semantic mappings for statuses and animations.
class BabkaTokens {
  // --- Freshness System ---
  
  static FreshnessToken get freshToday => const FreshnessToken(
    type: FreshnessType.freshToday,
    color: BabkaColors.freshToday,
    icon: Icons.eco_outlined,
  );

  static FreshnessToken get outOfOven => const FreshnessToken(
    type: FreshnessType.outOfOven,
    color: BabkaColors.outOfOven,
    icon: Icons.local_fire_department_outlined,
  );

  static FreshnessToken get limitedQuantity => const FreshnessToken(
    type: FreshnessType.limitedQuantity,
    color: BabkaColors.limited,
    icon: Icons.alarm_outlined,
  );

  // --- Animation Durations ---
  
  static const Duration animFast = Duration(milliseconds: 120);
  static const Duration animMedium = Duration(milliseconds: 180);
  static const Duration animSlow = Duration(milliseconds: 300);

  // --- Animation Curves ---
  
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveEmphasized = Curves.easeOutQuart;
}

enum FreshnessType { freshToday, outOfOven, limitedQuantity }

class FreshnessToken {
  final FreshnessType type;
  final Color color;
  final IconData icon;

  const FreshnessToken({
    required this.type,
    required this.color,
    required this.icon,
  });

  String localizedLabel(AppLocalizations l10n) {
    switch (type) {
      case FreshnessType.freshToday:
        return l10n.freshToday;
      case FreshnessType.outOfOven:
        return l10n.outOfOven;
      case FreshnessType.limitedQuantity:
        return l10n.limitedQuantity;
    }
  }
}
