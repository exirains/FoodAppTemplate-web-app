import 'package:flutter/material.dart';
import '../design_system/sangak_colors.dart';
import '../design_system/sangak_typography.dart';
import '../design_system/sangak_dimens.dart';

/// Sangak Theme Configuration (v1.0.0)
class SangakTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SangakColors.primary,
        primary: SangakColors.primary,
        secondary: SangakColors.secondary,
        surface: SangakColors.surface,
        error: SangakColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SangakColors.ink,
      ),
      scaffoldBackgroundColor: SangakColors.background,
      dividerTheme: const DividerThemeData(
        color: SangakColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SangakColors.background,
        foregroundColor: SangakColors.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: SangakTypography.h3,
      ),
      // Extend the theme with Sangak-specific tokens
      extensions: [
        SangakThemeExtension(
          spacing8: SangakDimens.spacing8,
          spacing16: SangakDimens.spacing16,
          radiusM: SangakDimens.radiusM,
          shadowSoft: SangakDimens.shadowLow,
        ),
      ],
    );
  }
}

/// Custom Theme Extension for Sangak-specific design tokens.
class SangakThemeExtension extends ThemeExtension<SangakThemeExtension> {
  final double spacing8;
  final double spacing16;
  final double radiusM;
  final List<BoxShadow> shadowSoft;

  SangakThemeExtension({
    required this.spacing8,
    required this.spacing16,
    required this.radiusM,
    required this.shadowSoft,
  });

  @override
  ThemeExtension<SangakThemeExtension> copyWith({
    double? spacing8,
    double? spacing16,
    double? radiusM,
    List<BoxShadow>? shadowSoft,
  }) {
    return SangakThemeExtension(
      spacing8: spacing8 ?? this.spacing8,
      spacing16: spacing16 ?? this.spacing16,
      radiusM: radiusM ?? this.radiusM,
      shadowSoft: shadowSoft ?? this.shadowSoft,
    );
  }

  @override
  ThemeExtension<SangakThemeExtension> lerp(
    ThemeExtension<SangakThemeExtension>? other,
    double t,
  ) {
    if (other is! SangakThemeExtension) return this;
    return SangakThemeExtension(
      spacing8: t < 0.5 ? spacing8 : other.spacing8,
      spacing16: t < 0.5 ? spacing16 : other.spacing16,
      radiusM: t < 0.5 ? radiusM : other.radiusM,
      shadowSoft: t < 0.5 ? shadowSoft : other.shadowSoft,
    );
  }
}
