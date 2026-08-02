import 'package:flutter/material.dart';

/// Sangak Design System Typography (v1.1.0)
///
/// This class now acts as a bridge to the [ThemeData.textTheme],
/// ensuring that the correct font family (Fraunces/Jakarta or IranYekan)
/// is applied automatically based on the current locale.
class SangakTypography {
  static TextTheme _of(BuildContext context) => Theme.of(context).textTheme;

  static TextStyle display(BuildContext context) => _of(context).displayLarge!;
  static TextStyle h1(BuildContext context) => _of(context).headlineLarge!;
  static TextStyle h2(BuildContext context) => _of(context).headlineMedium!;
  static TextStyle h3(BuildContext context) => _of(context).headlineSmall!;

  static TextStyle title(BuildContext context) => _of(context).titleLarge!;
  static TextStyle subtitle(BuildContext context) => _of(context).titleMedium!;

  static TextStyle bodyLarge(BuildContext context) => _of(context).bodyLarge!;
  static TextStyle bodyMedium(BuildContext context) => _of(context).bodyMedium!;
  static TextStyle bodySmall(BuildContext context) => _of(context).bodySmall!;

  static TextStyle button(BuildContext context) => _of(context).labelLarge!;
  static TextStyle price(BuildContext context) => _of(context).titleLarge!.copyWith(fontWeight: FontWeight.w700);
  static TextStyle caption(BuildContext context) => _of(context).bodySmall!.copyWith(fontSize: 11, letterSpacing: 0.5);
}
