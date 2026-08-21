import 'package:flutter/material.dart';

/// Sangak Responsive Layout Utility (v1.0.0)
///
/// Provides a consistent way to handle adaptive layouts across Mobile, Web, and Desktop.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool usePadding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth,
    this.usePadding = true,
  });

  // --- Breakpoints ---
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;
  static const double breakpointDesktop = 1440.0;

  // --- Max Widths ---
  static const double mobileMaxWidth = 600.0;
  static const double workstationMaxWidth = 1440.0;
  static const double desktopMaxWidth = 1200.0;

  // --- Helper Methods ---
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointMobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointMobile &&
      MediaQuery.of(context).size.width < breakpointTablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointTablet;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointDesktop;

  /// Returns a value based on the current screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) return largeDesktop;
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    // Intelligent max width
    double? effectiveMaxWidth = maxWidth;
    if (effectiveMaxWidth == null) {
      if (isMobile(context)) {
        effectiveMaxWidth = double.infinity;
      } else if (isTablet(context)) {
        effectiveMaxWidth = 900.0;
      } else {
        effectiveMaxWidth = desktopMaxWidth;
      }
    }

    final horizontalPadding = usePadding ? value<double>(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
      largeDesktop: 48.0,
    ) : 0.0;

    return Material(
      color: const Color(0xFFFDFCF8),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
