import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The lavender "You create a safer, kinder world." card that closes the
/// dashboard, with soft cloud puffs along its lower edge.
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, this.text = AppStrings.homeQuote});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppSizes.brCard,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.quoteGradient),
        child: Stack(
          children: <Widget>[
            // Cloud puffs: overlapping white ellipses at low opacity.
            for (final (double left, double bottom, double w, double h)
                in <(double, double, double, double)>[
                  (-30, -38, 150, 80),
                  (70, -46, 170, 86),
                  (190, -40, 150, 78),
                  (280, -48, 170, 90),
                ])
              Positioned(
                left: left,
                bottom: bottom,
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.all(Radius.elliptical(w, h)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.xl,
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.xxxl + 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '“',
                          style: AppTypography.display(
                            40,
                            weight: FontWeight.w700,
                            color: AppColors.primaryMuted,
                            height: 1,
                          ),
                        ),
                        Text(
                          text,
                          style: AppTypography.display(
                            19,
                            weight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 34),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
