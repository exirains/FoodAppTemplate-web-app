import 'package:flutter/material.dart';

/// Sangak Responsive Layout Utility (v1.0.0)
///
/// Provides a consistent way to handle adaptive layouts across Mobile, Web, and Desktop.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 600.0, // Standard max width for a mobile-first app on desktop
  });

  /// Static helper to check if the screen is "large"
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBF6EE), // Inlined SangakColors.background to fix import issue
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: isLargeScreen(context) 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 4))]
              : null,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
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
