import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sangak Design System App Logo (v1.0.0)
///
/// Centered around the primary brand identity (favicon.svg).
/// Supports multiple sizes for different app locations.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 80,
  });

  const AppLogo.small({super.key}) : size = 56;

  const AppLogo.medium({super.key}) : size = 80;

  const AppLogo.large({super.key}) : size = 160;

  const AppLogo.nav({super.key}) : size = 32;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'lib/assets/branding/favicon.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
