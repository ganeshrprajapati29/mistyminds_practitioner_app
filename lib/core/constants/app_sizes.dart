import 'package:flutter/widgets.dart';

/// 4/8-point spacing scale, radii and shared metrics.
abstract final class AppSizes {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusCard = 22;
  static const double radiusPill = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius brCard = BorderRadius.all(
    Radius.circular(radiusCard),
  );
  static const BorderRadius brPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  static const double screenPadding = 20;
  static const double buttonHeight = 54;
  static const double minTapTarget = 48;
  static const double navHeight = 64;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 26;
  static const double iconTile = 46;

  static const EdgeInsets pageInsets = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );
  static const EdgeInsets cardInsets = EdgeInsets.all(lg);

  /// Scroll padding so content clears a pinned footer button.
  static const double footerScrollInset = 110;
}
