import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/sangak_colors.dart';
import '../design_system/sangak_dimens.dart';

/// Sangak Theme Configuration (v1.1.0)
class BabkaTheme {
  static ThemeData light(Locale locale) {
    final isPersian = locale.languageCode == 'fa';
    
    // Choose font families based on locale
    final String baseFont = isPersian ? 'IranYekan' : GoogleFonts.plusJakartaSans().fontFamily!;
    final String headingFont = isPersian ? 'Peyda' : GoogleFonts.montserrat().fontFamily!;

    final textTheme = TextTheme(
      // Note: All display and headline styles should be All-Caps in the UI
      displayLarge: TextStyle(fontFamily: headingFont, fontSize: 48, fontWeight: FontWeight.bold, color: BabkaColors.ink, height: 1.1),
      displayMedium: TextStyle(fontFamily: headingFont, fontSize: 40, fontWeight: FontWeight.bold, color: BabkaColors.ink, height: 1.1),
      displaySmall: TextStyle(fontFamily: headingFont, fontSize: 32, fontWeight: FontWeight.bold, color: BabkaColors.ink, height: 1.1),
      headlineLarge: TextStyle(fontFamily: headingFont, fontSize: 32, fontWeight: FontWeight.bold, color: BabkaColors.ink, height: 1.2),
      headlineMedium: TextStyle(fontFamily: headingFont, fontSize: 24, fontWeight: FontWeight.bold, color: BabkaColors.ink, height: 1.2),
      headlineSmall: TextStyle(fontFamily: headingFont, fontSize: 20, fontWeight: FontWeight.bold, color: BabkaColors.ink, height: 1.3),
      titleLarge: TextStyle(fontFamily: isPersian ? 'Peyda' : baseFont, fontSize: 18, fontWeight: isPersian ? FontWeight.w600 : FontWeight.w600, color: BabkaColors.ink),
      titleMedium: TextStyle(fontFamily: baseFont, fontSize: 16, fontWeight: FontWeight.w500, color: BabkaColors.inkLight),
      bodyLarge: TextStyle(fontFamily: baseFont, fontSize: 16, fontWeight: FontWeight.w400, color: BabkaColors.ink, height: 1.5),
      bodyMedium: TextStyle(fontFamily: baseFont, fontSize: 14, fontWeight: FontWeight.w400, color: BabkaColors.ink, height: 1.5),
      bodySmall: TextStyle(fontFamily: baseFont, fontSize: 12, fontWeight: FontWeight.w400, color: BabkaColors.inkLight),
      labelLarge: TextStyle(fontFamily: baseFont, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: isPersian ? 0 : 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: baseFont,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BabkaColors.primary,
        primary: BabkaColors.primary,
        secondary: BabkaColors.secondary,
        surface: BabkaColors.surface,
        error: BabkaColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BabkaColors.ink,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: BabkaColors.background,
      dividerTheme: const DividerThemeData(
        color: BabkaColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BabkaColors.background,
        foregroundColor: BabkaColors.ink,
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
        BabkaThemeExtension(
          spacing8: BabkaDimens.spacing8,
          spacing16: BabkaDimens.spacing16,
          radiusM: BabkaDimens.radiusM,
          shadowSoft: BabkaDimens.shadowLow,
        ),
      ],
    );
  }
}

/// Custom Theme Extension for Sangak-specific design tokens.
class BabkaThemeExtension extends ThemeExtension<BabkaThemeExtension> {
  final double spacing8;
  final double spacing16;
  final double radiusM;
  final List<BoxShadow> shadowSoft;

  BabkaThemeExtension({
    required this.spacing8,
    required this.spacing16,
    required this.radiusM,
    required this.shadowSoft,
  });

  @override
  ThemeExtension<BabkaThemeExtension> copyWith({
    double? spacing8,
    double? spacing16,
    double? radiusM,
    List<BoxShadow>? shadowSoft,
  }) {
    return BabkaThemeExtension(
      spacing8: spacing8 ?? this.spacing8,
      spacing16: spacing16 ?? this.spacing16,
      radiusM: radiusM ?? this.radiusM,
      shadowSoft: shadowSoft ?? this.shadowSoft,
    );
  }

  @override
  ThemeExtension<BabkaThemeExtension> lerp(
    ThemeExtension<BabkaThemeExtension>? other,
    double t,
  ) {
    if (other is! BabkaThemeExtension) return this;
    return BabkaThemeExtension(
      spacing8: t < 0.5 ? spacing8 : other.spacing8,
      spacing16: t < 0.5 ? spacing16 : other.spacing16,
      radiusM: t < 0.5 ? radiusM : other.radiusM,
      shadowSoft: t < 0.5 ? shadowSoft : other.shadowSoft,
    );
  }
}
