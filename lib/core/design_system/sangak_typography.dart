import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sangak_colors.dart';

/// Sangak Design System Typography (v1.0.0)
///
/// Combines Fraunces (Headlines) and Plus Jakarta Sans (UI/Body).
class SangakTypography {
  // --- Headline Styles (Fraunces) ---
  
  static TextStyle display = GoogleFonts.fraunces(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: SangakColors.ink,
    height: 1.1,
  );

  static TextStyle h1 = GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: SangakColors.ink,
    height: 1.2,
  );

  static TextStyle h2 = GoogleFonts.fraunces(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: SangakColors.ink,
    height: 1.2,
  );

  static TextStyle h3 = GoogleFonts.fraunces(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: SangakColors.ink,
    height: 1.3,
  );

  // --- UI & Body Styles (Plus Jakarta Sans) ---

  static TextStyle title = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: SangakColors.ink,
  );

  static TextStyle subtitle = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: SangakColors.inkLight,
  );

  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: SangakColors.ink,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: SangakColors.ink,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SangakColors.inkLight,
  );

  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle price = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SangakColors.ink,
  );

  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: SangakColors.inkLight,
    letterSpacing: 0.5,
  );
}
