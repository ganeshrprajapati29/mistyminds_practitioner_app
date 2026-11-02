import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/status_timeline.dart';

/// The review stage of one application, read from the server.
final FutureProviderFamily<String, String> applicationStatusProvider =
    FutureProvider.family<String, String>(
      (Ref ref, String reference) =>
          ref.read(repositoryProvider).fetchApplicationStatus(reference),
    );

class VerificationPendingScreen extends ConsumerWidget {
  const VerificationPendingScreen({super.key, required this.reference});

  final String reference;

  static const List<String> _stages = <String>[
    'document_verification',
    'interview',
    'approved',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String status = reference.isEmpty
        ? 'document_verification'
        : ref.watch(applicationStatusProvider(reference)).valueOrNull ??
              'document_verification';
    final bool rejected = status == 'rejected';
    final int stage = _stages.indexOf(status).clamp(0, _stages.length - 1);
    TimelineState at(int step) => step < stage + 1
        ? TimelineState.done
        : step == stage + 1 && status != 'approved'
        ? TimelineState.active
        : TimelineState.pending;
    final (String chip, ChipTone tone, String title) = switch (status) {
      'interview' => (
        'Interview stage',
        ChipTone.violet,
        'Your documents are verified',
      ),
      'approved' => ('Approved', ChipTone.mint, 'Welcome to Misty Minds'),
      'rejected' => (
        'Not approved',
        ChipTone.coral,
        'We couldn’t approve this application',
      ),
      _ => (
        'Verification in progress',
        ChipTone.amber,
        'We’re reviewing your documents',
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            MistyAppBar(
              title: 'Application Status',
              onBack: () => context.go(AppRoutes.welcome),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.md,
                  AppSizes.screenPadding,
                  AppSizes.xxl,
                ),
                children: <Widget>[
                  MistyCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        // The listening cloud sits on its own white plate.
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSizes.radiusLg),
                          ),
                          child: Image.asset(
                            AppAssets.cloudListening,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.lg,
                            0,
                            AppSizes.lg,
                            AppSizes.xl,
                          ),
                          child: Column(
                            children: <Widget>[
                              MistyStatusChip(
                                label: chip,
                                tone: tone,
                                dot: true,
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: AppTypography.displaySmall,
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                rejected
                                    ? 'Our partner team will email you with the '
                                          'reasons and how to re-apply.'
                                    : 'You’ll get an email and SMS as soon as '
                                          'your profile is verified. Most reviews '
                                          'finish within 3 working days.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  MistyCard(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      AppSizes.xl,
                      AppSizes.lg,
                      0,
                    ),
                    child: StatusTimeline(
                      steps: <TimelineStep>[
                        TimelineStep(
                          'Application received',
                          reference.isEmpty
                              ? 'Received'
                              : 'Reference $reference',
                          TimelineState.done,
                        ),
                        TimelineStep(
                          'Document verification',
                          'Degree, ID and registration checks',
                          at(1),
                        ),
                        TimelineStep(
                          'Short video interview',
                          'We’ll invite you to pick a time',
                          at(2),
                        ),
                        TimelineStep(
                          'Profile goes live',
                          'Start accepting sessions',
                          status == 'approved'
                              ? TimelineState.done
                              : TimelineState.pending,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const MistyInfoNote(
                    text:
                        'Questions about your application? Write to '
                        'partners@mistyminds.in — we reply within a day.',
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  MistySecondaryButton(
                    label: 'Back to Welcome',
                    onPressed: () => context.go(AppRoutes.welcome),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Center(
                    child: Text(
                      'Once you’re verified, sign in from the welcome screen',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Center(
                    child: MistyLinkButton(
                      label: 'Continue as a verified partner',
                      arrow: true,
                      onPressed: () {
                        final GoRouter router = GoRouter.of(context);
                        router.go(AppRoutes.welcome);
                        router.push(AppRoutes.login);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
