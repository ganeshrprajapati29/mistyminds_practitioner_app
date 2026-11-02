import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/misty_brand.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../navigation/app_routes.dart';

/// The psychologist welcome from the reference: the cloud-room scene full
/// bleed, the wordmark and serif headline over its sky, and the two calls to
/// action over the pale floor.
class PsychologistWelcomeScreen extends StatelessWidget {
  const PsychologistWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    // Scale type with the screen so the composition holds on small phones.
    final double scale = (size.width / 390).clamp(0.85, 1.12);
    final bool compact = size.height < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // The scene: anchored slightly below centre so the arch, beanbag and
          // floor keep their place as the viewport's aspect ratio changes.
          Image.asset(
            AppAssets.welcomeBackground,
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.25),
            filterQuality: FilterQuality.medium,
          ),
          // A soft floor fade keeps the calls to action legible.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 260,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.welcomeFade),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                children: <Widget>[
                  SizedBox(height: compact ? AppSizes.sm : AppSizes.xl),
                  MistyWordmark(height: 62 * scale),
                  // Kept close under the wordmark so the headline sits a little
                  // higher, clear of the arch in the scene.
                  SizedBox(height: compact ? AppSizes.sm : AppSizes.md),
                  Text(
                    AppStrings.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: (compact ? 32 : 38) * scale,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    AppStrings.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      16.5 * scale,
                      color: AppColors.headlineInk.withValues(alpha: 0.72),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  MistyPrimaryButton(
                    label: AppStrings.loginAsPsychologist,
                    height: 62,
                    trailingIcon: Icons.arrow_forward_rounded,
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const MistySvgIcon(
                        AppAssets.iconClients,
                        tile: false,
                        size: 24,
                        color: Colors.white,
                        hollowColor: Colors.white,
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.login),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Divider(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    indent: AppSizes.sm,
                    endIndent: AppSizes.sm,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    AppStrings.newHere,
                    style: AppTypography.body(
                      14.5,
                      weight: FontWeight.w500,
                      color: AppColors.headlineInk,
                    ),
                  ),
                  MistyLinkButton(
                    label: AppStrings.applyToJoin,
                    arrow: true,
                    style: AppTypography.body(
                      16,
                      weight: FontWeight.w600,
                      color: AppColors.primaryStrong,
                    ),
                    onPressed: () => context.push(AppRoutes.apply),
                  ),
                  SizedBox(height: compact ? AppSizes.xs : AppSizes.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
