import 'package:flutter/material.dart';

/// Sangak Design System Colors (v1.0.0)
///
/// Follows the "Artisanal Precision" philosophy.
class BabkaColors {
  // Brand Colors
  static const Color primary = Color(0xFF1F3C44); // Deep Dark Slate Teal
  static const Color secondary = Color(0xFF23393F); // Alternative Teal
  static const Color accent = Color(0xFF919D7E); // Olive Sage (keep for now or adjust)

  // Neutral Colors
  static const Color background = Color(0xFFF8F6F0); // Warm Cream
  static const Color surface = Color(0xFFF8F6F0);    // Warm Cream
  static const Color ink = Color(0xFF1A1A1A); // Dark Charcoal
  static const Color inkLight = Color(0xFF6D675F); // Secondary Text
  static const Color border = Color(0xFFE8E4D9); // Subtle Divider/Border
  
  // Semantic ColorFs
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
