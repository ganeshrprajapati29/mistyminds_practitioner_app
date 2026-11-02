import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../navigation/app_routes.dart';
import '../widgets/status_timeline.dart';

class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({super.key, required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPadding,
                    AppSizes.xxxl,
                    AppSizes.screenPadding,
                    AppSizes.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Image.asset(AppAssets.cloudReady, height: 130),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      Text(
                        'Application submitted!',
                        textAlign: TextAlign.center,
                        style: AppTypography.displayMedium,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Thank you for choosing to make space for others. '
                        'We’ll review your details with care.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSizes.xl),
                      MistyCard(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: reference));
                          AppFeedback.toast(context, 'Reference copied');
                        },
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Application reference',
                                    style: AppTypography.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reference,
                                    style: AppTypography.body(
                                      17,
                                      weight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.copy_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      MistyCard(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.lg,
                          AppSizes.lg,
                          AppSizes.lg,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'What happens next',
                              style: AppTypography.headingSmall,
                            ),
                            const SizedBox(height: AppSizes.lg),
                            const StatusTimeline(
                              steps: <TimelineStep>[
                                TimelineStep(
                                  'Application received',
                                  'Just now',
                                  TimelineState.done,
                                ),
                                TimelineStep(
                                  'Document verification',
                                  'Usually 2–3 working days',
                                  TimelineState.active,
                                ),
                                TimelineStep(
                                  'Short video interview',
                                  'A 20-minute conversation with our clinical team',
                                  TimelineState.pending,
                                ),
                                TimelineStep(
                                  'Profile goes live',
                                  'Set your availability and start helping',
                                  TimelineState.pending,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.sm,
                  AppSizes.screenPadding,
                  AppSizes.lg,
                ),
                child: Column(
                  children: <Widget>[
                    MistyPrimaryButton(
                      label: 'Track Application',
                      onPressed: () => context.go(
                        Uri(
                          path: AppRoutes.verificationPending,
                          queryParameters: <String, String>{'ref': reference},
                        ).toString(),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    MistySecondaryButton(
                      label: 'Back to Welcome',
                      onPressed: () => context.go(AppRoutes.welcome),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
