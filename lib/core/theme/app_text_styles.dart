import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography pairing shared with the Misty Minds client app: Playfair Display
/// for editorial hero moments, Inter for everything a person reads or acts
/// on, and Dancing Script for the occasional handwritten brand note.
///
/// Screens use the named styles below (or the builders for a one-off size)
/// rather than declaring raw `TextStyle`s.
abstract final class AppTypography {
  static const String _serif = 'PlayfairDisplay';
  static const String _sans = 'Inter';
  static const String _script = 'DancingScript';

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? height,
  }) => TextStyle(
    fontFamily: _serif,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height ?? 1.22,
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: _sans,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height ?? 1.42,
    letterSpacing: letterSpacing,
  );

  static TextStyle script(double size, {Color color = AppColors.primaryDeep}) =>
      TextStyle(
        fontFamily: _script,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.25,
      );

  // ---- Named styles --------------------------------------------------------

  /// "Healing happens together." — welcome hero.
  static TextStyle get displayLarge =>
      display(38, weight: FontWeight.w700, color: AppColors.headlineInk);

  /// "Set Your Availability", "Ready when you are."
  static TextStyle get displayMedium => display(29);

  /// "Waiting for a request...", card heroes.
  static TextStyle get displaySmall => display(21);

  /// "1h 42m" — big timer numerals.
  static TextStyle get timer => display(32);

  static TextStyle get headingLarge =>
      body(21, weight: FontWeight.w700, height: 1.3);
  static TextStyle get headingMedium =>
      body(18, weight: FontWeight.w600, height: 1.3);
  static TextStyle get headingSmall =>
      body(16, weight: FontWeight.w600, height: 1.3);
  static TextStyle get title => body(15, weight: FontWeight.w600, height: 1.3);

  static TextStyle get bodyLarge => body(16);
  static TextStyle get bodyMedium => body(14.5, color: AppColors.textSecondary);
  static TextStyle get bodySmall => body(13, color: AppColors.textSecondary);

  static TextStyle get buttonText =>
      body(16.5, weight: FontWeight.w600, color: AppColors.textOnPrimary);
  static TextStyle get label => body(14, weight: FontWeight.w600);
  static TextStyle get link =>
      body(14.5, weight: FontWeight.w600, color: AppColors.primary);
  static TextStyle get caption =>
      body(12, weight: FontWeight.w500, color: AppColors.textTertiary);

  static TextTheme build() => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineMedium: display(24),
    headlineSmall: headingLarge,
    titleLarge: headingMedium,
    titleMedium: headingSmall,
    titleSmall: title,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: body(15, weight: FontWeight.w600),
    labelMedium: body(
      13,
      weight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    labelSmall: caption,
  );
}
