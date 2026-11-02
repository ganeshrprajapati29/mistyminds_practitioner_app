import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/availability.dart';

/// "1h 42m remaining today · Today's window 6:00 PM – 8:00 PM" (ready
/// screen) or "1h 42m remaining in your slot" with a progress bar (online
/// screen).
class RemainingTimeCard extends StatelessWidget {
  const RemainingTimeCard({
    super.key,
    required this.window,
    this.showProgress = false,
  });

  final TalkWindow window;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final Widget timer = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        Fmt.hm(window.remaining),
        key: ValueKey<Duration>(window.remaining),
        style: AppTypography.timer,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.lg + 2,
        AppSizes.lg,
        AppSizes.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: AppSizes.brCard,
        border: Border.all(color: AppColors.lavenderStrong),
      ),
      child: showProgress
          ? Column(
              children: <Widget>[
                timer,
                Text(
                  AppStrings.remainingInSlot,
                  style: AppTypography.body(14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                ClipRRect(
                  borderRadius: AppSizes.brPill,
                  child: LinearProgressIndicator(
                    value: window.progressLeft,
                    minHeight: 5,
                    backgroundColor: AppColors.lavenderStrong,
                  ),
                ),
                const SizedBox(height: AppSizes.sm + 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${AppStrings.endsAt} ${Fmt.timeOfDay(window.end)}',
                    style: AppTypography.body(
                      13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const MistySvgIcon(
                      AppAssets.iconClock,
                      tile: false,
                      size: 34,
                    ),
                    const SizedBox(width: AppSizes.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        timer,
                        Text(
                          AppStrings.remainingToday,
                          style: AppTypography.body(
                            14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Divider(color: AppColors.primary.withValues(alpha: 0.10)),
                const SizedBox(height: AppSizes.md),
                Text(
                  '${AppStrings.todaysWindow} · '
                  '${Fmt.timeOfDay(window.start)} – ${Fmt.timeOfDay(window.end)}',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}
