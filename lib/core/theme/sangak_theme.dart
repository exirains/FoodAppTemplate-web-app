import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/sangak_colors.dart';
import '../design_system/sangak_dimens.dart';

/// Sangak Theme Configuration (v1.1.0)
class SangakTheme {
  static ThemeData light(Locale locale) {
    final isPersian = locale.languageCode == 'fa';
    
    // Choose font families based on locale
    final String baseFont = isPersian ? 'IRANYekanX' : GoogleFonts.plusJakartaSans().fontFamily!;
    final String headingFont = isPersian ? 'IRANYekanX' : GoogleFonts.fraunces().fontFamily!;

    final textTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: headingFont, fontSize: 48, fontWeight: FontWeight.w700, color: SangakColors.ink, height: 1.1),
      headlineLarge: TextStyle(fontFamily: headingFont, fontSize: 32, fontWeight: FontWeight.w700, color: SangakColors.ink, height: 1.2),
      headlineMedium: TextStyle(fontFamily: headingFont, fontSize: 24, fontWeight: FontWeight.w600, color: SangakColors.ink, height: 1.2),
      headlineSmall: TextStyle(fontFamily: headingFont, fontSize: 20, fontWeight: FontWeight.w600, color: SangakColors.ink, height: 1.3),
      titleLarge: TextStyle(fontFamily: baseFont, fontSize: 18, fontWeight: FontWeight.w600, color: SangakColors.ink),
      titleMedium: TextStyle(fontFamily: baseFont, fontSize: 16, fontWeight: FontWeight.w500, color: SangakColors.inkLight),
      bodyLarge: TextStyle(fontFamily: baseFont, fontSize: 16, fontWeight: FontWeight.w400, color: SangakColors.ink, height: 1.5),
      bodyMedium: TextStyle(fontFamily: baseFont, fontSize: 14, fontWeight: FontWeight.w400, color: SangakColors.ink, height: 1.5),
      bodySmall: TextStyle(fontFamily: baseFont, fontSize: 12, fontWeight: FontWeight.w400, color: SangakColors.inkLight),
      labelLarge: TextStyle(fontFamily: baseFont, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: isPersian ? 0 : 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: baseFont,
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
      textTheme: textTheme,
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
        titleTextStyle: textTheme.headlineSmall,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
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
