import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/design_system/sangak_dimens.dart';

/// Sangak Design System App Logo (v1.0.0)
///
/// Centered around the primary brand identity (favicon.svg).
/// Supports multiple sizes for different app locations.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showCircle;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showCircle = true,
  });

  const AppLogo.small({super.key})
      : size = 56,
        showCircle = true;

  const AppLogo.medium({super.key})
      : size = 100,
        showCircle = true;

  const AppLogo.large({super.key})
      : size = 160,
        showCircle = true;

  const AppLogo.nav({super.key})
      : size = 32,
        showCircle = false;

  @override
  Widget build(BuildContext context) {
    Widget logo = SvgPicture.asset(
      'lib/assets/branding/favicon.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (showCircle) {
      return Container(
        padding: EdgeInsets.all(size * 0.2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: SangakDimens.shadowLow,
        ),
        child: logo,
      );
    }

    return logo;
  }
}
