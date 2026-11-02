import 'package:flutter/material.dart';

/// Single source of truth for every colour in the Misty Minds partner app.
///
/// Shares its violet-on-white system with the Misty Minds client app so both
/// products read as one brand, and adds the mint "online" family the partner
/// reference screens lean on for availability.
///
/// Never hard-code a `Color(0x...)` in a screen — add it here instead.
abstract final class AppColors {
  // ---- Surfaces ------------------------------------------------------------
  static const Color background = Color(0xFFFBF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F0FF);

  // ---- Brand ---------------------------------------------------------------
  static const Color primary = Color(0xFF7654F7);
  static const Color primaryStrong = Color(0xFF5430E8);
  static const Color primaryDeep = Color(0xFF0B0848);

  /// The indigo of the welcome headline.
  static const Color headlineInk = Color(0xFF15127A);
  static const Color primarySoft = Color(0xFFF1EAFF);
  static const Color primaryMuted = Color(0xFFCDBDFF);
  static const Color lavender = Color(0xFFF4F1FF);
  static const Color lavenderStrong = Color(0xFFE7E0FF);

  /// The purple heart set inline after reassuring copy.
  static const Color lilacHeart = Color(0xFF8B6FE8);

  // ---- Online / mint -------------------------------------------------------
  static const Color online = Color(0xFF34C77B);
  static const Color mint = Color(0xFF5ECDA7);
  static const Color mintSoft = Color(0xFFE8FAF3);
  static const Color mintBorder = Color(0xFFBFEBD9);
  static const Color mintInk = Color(0xFF1E8A63);

  // ---- Accents -------------------------------------------------------------
  static const Color coral = Color(0xFFE8646A);
  static const Color coralSoft = Color(0xFFFDECEC);
  static const Color coralBorder = Color(0xFFF6C4C6);
  static const Color amber = Color(0xFFE7962A);
  static const Color amberSoft = Color(0xFFFEF4E3);
  static const Color skyBlue = Color(0xFF4E90F7);
  static const Color skySoft = Color(0xFFEDF5FF);
  static const Color star = Color(0xFFF5A623);

  // ---- Semantic ------------------------------------------------------------
  static const Color success = Color(0xFF2FB27C);
  static const Color successSoft = Color(0xFFE3F7EC);
  static const Color error = Color(0xFFE05B6B);
  static const Color errorSoft = Color(0xFFFCEAEC);

  // ---- Text ----------------------------------------------------------------
  static const Color textPrimary = Color(0xFF17152B);
  static const Color textSecondary = Color(0xFF6F7392);
  static const Color textTertiary = Color(0xFFA3A8C4);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ---- Lines ---------------------------------------------------------------
  static const Color border = Color(0xFFE9E4F5);
  static const Color divider = Color(0xFFF1EDFF);
  static const Color toggleOff = Color(0xFFE2DEEC);

  // ---- Video call ----------------------------------------------------------
  static const Color callStage = Color(0xFF1B1745);
  static const Color callStageEnd = Color(0xFF3A2C8F);

  /// Soft washes used for initials avatars. Stable per key.
  static const List<Color> pastels = <Color>[
    primarySoft,
    mintSoft,
    skySoft,
    amberSoft,
    coralSoft,
  ];
  static const List<Color> pastelInk = <Color>[
    primary,
    mintInk,
    skyBlue,
    Color(0xFFC2803A),
    coral,
  ];
  static Color pastelFor(String key) =>
      pastels[key.hashCode.abs() % pastels.length];
  static Color pastelInkFor(String key) =>
      pastelInk[key.hashCode.abs() % pastelInk.length];

  // ---- Gradients -----------------------------------------------------------

  /// The filled call-to-action: violet, deepening to the right.
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[Color(0xFF9278FF), Color(0xFF7654F7), Color(0xFF5B3BEA)],
  );

  /// Hero card wash (earnings, profile header).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF9B7BFF), Color(0xFF7654F7), Color(0xFF5631E9)],
  );

  /// The pale lavender used on the dashboard quote card.
  static const LinearGradient quoteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF1ECFF), Color(0xFFE9E2FF)],
  );

  /// Mint-to-white wash behind the "Go Online" card.
  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFEAFBF4), Color(0xFFF6FDFA)],
  );

  /// The pale sky behind calm, full-screen moments.
  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFF0F2FF), Color(0xFFF4EEFF), Color(0xFFFBF8FF)],
  );

  /// Fades the welcome scene into the page behind the call-to-action.
  static const LinearGradient welcomeFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0x00FBF8FF), Color(0xE6FBF8FF), Color(0xFFFBF8FF)],
    stops: <double>[0, 0.55, 1],
  );

  static const LinearGradient callGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[callStage, callStageEnd],
  );

  // ---- Elevation -----------------------------------------------------------

  /// Standard card elevation — a soft violet halo, never a grey band.
  static List<BoxShadow> get softShadow => <BoxShadow>[
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get liftedShadow => <BoxShadow>[
    BoxShadow(
      color: primary.withValues(alpha: 0.16),
      blurRadius: 34,
      spreadRadius: -8,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get buttonGlow => <BoxShadow>[
    BoxShadow(
      color: primary.withValues(alpha: 0.28),
      blurRadius: 20,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];
}
