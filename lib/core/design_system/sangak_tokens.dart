import 'package:flutter/material.dart';
import 'sangak_colors.dart';

/// Sangak Design System Tokens (v1.0.0)
///
/// Semantic mappings for statuses and animations.
class SangakTokens {
  // --- Freshness System ---
  
  static FreshnessToken get freshToday => const FreshnessToken(
    label: 'Fresh Today',
    color: SangakColors.freshToday,
    icon: Icons.eco_outlined,
  );

  static FreshnessToken get outOfOven => const FreshnessToken(
    label: 'Just Out of Oven',
    color: SangakColors.outOfOven,
    icon: Icons.local_fire_department_outlined,
  );

  static FreshnessToken get limitedQuantity => const FreshnessToken(
    label: 'Limited Quantity',
    color: SangakColors.limited,
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

class FreshnessToken {
  final String label;
  final Color color;
  final IconData icon;

  const FreshnessToken({
    required this.label,
    required this.color,
    required this.icon,
  });
}
