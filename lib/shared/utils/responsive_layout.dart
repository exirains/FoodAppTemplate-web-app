import 'package:flutter/material.dart';

/// Sangak Responsive Layout Utility (v1.0.0)
///
/// Provides a consistent way to handle adaptive layouts across Mobile, Web, and Desktop.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth,
  });

  /// Standard max width for a mobile-first app on desktop
  static const double mobileMaxWidth = 600.0;

  /// Max width for desktop workstation interfaces
  static const double workstationMaxWidth = 1440.0;

  /// Static helper to check if the screen is "large"
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  @override
  Widget build(BuildContext context) {
    // Determine the constraint: use provided maxWidth or default to mobileMaxWidth
    final constraint = maxWidth ?? mobileMaxWidth;

    return Material(
      color: const Color(0xFFFDFCF8), // Match Sangak Theme background
      child: Center(
        child: Container(
          clipBehavior: Clip.none,
          constraints: BoxConstraints(maxWidth: constraint),
          child: child,
        ),
      ),
    );
  }
}

/// A builder that provides different widgets based on screen width.
class AdaptiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth > 600 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}
