import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum TimelineState { done, active, pending }

class TimelineStep {
  const TimelineStep(this.title, this.subtitle, this.state);

  final String title;
  final String subtitle;
  final TimelineState state;
}

/// A vertical progress timeline (application review stages).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 32,
                  child: Column(
                    children: <Widget>[
                      _Marker(state: steps[i].state),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: steps[i].state == TimelineState.done
                                ? AppColors.mint
                                : AppColors.lavenderStrong,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 4),
                        Text(
                          steps[i].title,
                          style: AppTypography.body(
                            15,
                            weight: FontWeight.w600,
                            color: steps[i].state == TimelineState.pending
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(steps[i].subtitle, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.state});

  final TimelineState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          TimelineState.done => AppColors.mint,
          TimelineState.active => AppColors.primary,
          TimelineState.pending => AppColors.surface,
        },
        border: state == TimelineState.pending
            ? Border.all(color: AppColors.lavenderStrong, width: 2)
            : null,
        boxShadow: state == TimelineState.active ? AppColors.buttonGlow : null,
      ),
      child: switch (state) {
        TimelineState.done => const Icon(
          Icons.check_rounded,
          size: 16,
          color: Colors.white,
        ),
        TimelineState.active => const Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: Colors.white,
        ),
        TimelineState.pending => null,
      },
    );
  }
}
