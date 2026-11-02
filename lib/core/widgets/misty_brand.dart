import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The "Misty Minds" script wordmark, optionally with the brand tagline
/// set beneath it as in the dashboard reference. Scaled by height only, so
/// the mark is never stretched.
class MistyWordmark extends StatelessWidget {
  const MistyWordmark({super.key, this.height = 48, this.showTagline = false});

  final double height;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          AppAssets.wordmark,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: AppStrings.appName,
        ),
        if (showTagline)
          Text(
            AppStrings.tagline,
            style: AppTypography.body(
              height * 0.2,
              weight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.1,
            ),
          ),
      ],
    );
  }
}
