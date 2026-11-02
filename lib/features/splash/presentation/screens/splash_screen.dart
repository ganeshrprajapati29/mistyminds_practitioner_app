import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/splash_clouds.dart';

/// The same splash as the MistyMinds client app, screen for screen: the misty
/// gradient with drifting clouds, the wordmark fading in dead centre, the
/// tagline centred under it and the handwritten note near the foot.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Must match the wordmark width baked into `assets/brand/splash_logo*.png`
  /// by `tool/prepare_assets.dart` (700 px at 4x).
  static const double logoWidth = 175;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );

  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    _route();
  }

  /// Restores a remembered session while the logo shows — never faster than
  /// the splash animation, never waiting on it longer than needed.
  Future<void> _route() async {
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      ref.read(authProvider.notifier).restore(),
      Future<void>.delayed(const Duration(milliseconds: 2100)),
    ]);
    if (!mounted) return;
    final bool signedIn = results.first == true;
    context.go(signedIn ? AppRoutes.home : AppRoutes.welcome);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFF6F1FF),
                  Color(0xFFFBF8FF),
                  Color(0xFFFFF7F0),
                ],
                stops: <double>[0, 0.58, 1],
              ),
            ),
            child: SizedBox.expand(),
          ),
          // Layered drifting blobs, largest and palest first, so the mark
          // sits in mist rather than on flat paper.
          const Positioned(
            top: -70,
            left: -60,
            child: CloudBlob(
              width: 300,
              height: 210,
              color: SplashPalette.softLilac,
              opacity: 0.96,
            ),
          ),
          const Positioned(
            top: 40,
            right: -70,
            child: CloudBlob(
              width: 250,
              height: 180,
              color: SplashPalette.softPink,
              opacity: 0.82,
            ),
          ),
          const Positioned(
            bottom: 120,
            left: -50,
            child: CloudBlob(
              width: 220,
              height: 150,
              color: SplashPalette.softLavender,
              opacity: 0.84,
            ),
          ),
          const Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: AnimatedCloudBackdrop(height: 260, opacity: 0.72),
          ),
          Positioned(
            bottom: -60,
            left: 0,
            right: 0,
            child: Transform.flip(
              flipY: true,
              child: const CloudBackdrop(
                height: 220,
                tint: SplashPalette.softLavender,
                accent: SplashPalette.mintGreen,
                opacity: 0.76,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double wordmarkHeight = (constraints.maxWidth * 0.18)
                    .clamp(64.0, 82.0)
                    .toDouble();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                  ),
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _logoFade,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      // Same layout as the client app's splash: the wordmark
                      // sits slightly above centre, the tagline stays centred
                      // under it, and the handwritten note sits near the foot.
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Align(
                            alignment: const Alignment(0, -0.12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                // An invisible twin of the tagline keeps the
                                // wordmark exactly in the middle.
                                const Visibility(
                                  visible: false,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: _SplashTagline(),
                                ),
                                Image.asset(
                                  AppAssets.wordmark,
                                  height: wordmarkHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  semanticLabel: AppStrings.appName,
                                ),
                                FadeTransition(
                                  opacity: _taglineFade,
                                  child: const _SplashTagline(),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, 0.76),
                            child: FadeTransition(
                              opacity: _taglineFade,
                              child: const _SplashScript(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The brand tagline under the wordmark: one centred block, the full width of
/// the screen less the page gutters, so it sits evenly on every phone.
class _SplashTagline extends StatelessWidget {
  const _SplashTagline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          AppStrings.splashTagline,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppTypography.body(
            16.5,
            weight: FontWeight.w600,
            height: 1.45,
            color: AppColors.primaryDeep,
          ),
        ),
      ),
    );
  }
}

/// The handwritten note near the foot of the screen, tilted a few degrees.
class _SplashScript extends StatelessWidget {
  const _SplashScript();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: -0.035 * 6.28318,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              AppStrings.splashScript,
              textAlign: TextAlign.center,
              style: AppTypography.script(28),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 28 * 0.62,
                color: AppColors.primaryDeep.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
