import 'package:flutter/material.dart';

/// Sangak Design System Colors (v1.0.0)
///
/// Follows the "Artisanal Precision" philosophy.
class SangakColors {
  // Brand Colors
  static const Color primary = Color(0xFFC68A2B); // Golden Crust
  static const Color secondary = Color(0xFF7D4F39); // Oven Stone
  static const Color accent = Color(0xFF919D7E); // Olive Sage

  // Neutral Colors
  static const Color background = Color(0xFFFBF6EE); // Warm parchment
  static const Color surface = Color(0xFFFFFFFF);    // Flour white
  static const Color ink = Color(0xFF2A241E); // Primary Text
  static const Color inkLight = Color(0xFF6D675F); // Secondary Text
  static const Color border = Color(0xFFE8E4D9); // Subtle Divider/Border
  
  // Semantic Colors
  static const Color success = Color(0xFF919D7E); // Same as accent
  static const Color warning = Color(0xFFE2A04E); // Warm Honey
  static const Color error = Color(0xFFC95A4A); // Brick Red
  static const Color info = Color(0xFF5A7D9A); // Slate Blue
  
  // Status Colors (Freshness System)
  static const Color freshToday = Color(0xFF919D7E);
  static const Color outOfOven = Color(0xFFE2A04E);
  static const Color limited = Color(0xFFC95A4A);

  // Overlay & Shadows
  static const Color shadow = Color(0x0D2A241E); // 5% Ink
  static const Color scrim = Color(0x662A241E); // 40% Ink for text over images
}
