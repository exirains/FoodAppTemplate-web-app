import 'package:flutter/material.dart';

/// Sangak Design System Dimensions (v1.0.0)
///
/// Based on an 8pt grid system.
class SangakDimens {
  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Radii
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusPill = 999.0;

  // Elevations (Custom Shadow Tokens)
  static List<BoxShadow> get shadowLow => [
        BoxShadow(
          color: const Color(0xFF2A241E).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: const Color(0xFF2A241E).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowHigh => [
        BoxShadow(
          color: const Color(0xFF2A241E).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
