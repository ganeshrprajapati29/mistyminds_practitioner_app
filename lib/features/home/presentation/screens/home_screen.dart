import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_dashboard_card.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../data/models/session.dart';
import '../../../../data/models/transaction.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../../../guide/presentation/widgets/guide_video_tiles.dart';
import '../widgets/earnings_insight_card.dart';
import '../widgets/home_header.dart';
import '../widgets/presence_card.dart';
import '../widgets/quote_card.dart';

/// The psychologist dashboard, reproduced from the first reference screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static final Uri _relaxationUri = Uri.parse(
    'https://youtube.com/@mistyminds1?si=EQ5lZBtfZcytw8JI',
  );

  Future<void> _openRelaxation() {
    return launchUrl(_relaxationUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Psychologist? profile = ref.watch(profileProvider).valueOrNull;
    final List<Session> today = ref.watch(todaysSessionsProvider);
    final EarningsSummary? earnings = ref
        .watch(earningsSummaryProvider)
        .valueOrNull;
    final AsyncValue<List<EarningTransaction>> transactions = ref.watch(
      transactionsProvider,
    );

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(sessionsProvider)
            ..invalidate(earningsSummaryProvider)
            ..invalidate(transactionsProvider)
            ..invalidate(notificationsProvider)
            ..invalidate(guideVideosProvider);
          await ref.read(sessionsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            AppSizes.md,
            AppSizes.screenPadding,
            AppSizes.xxl,
          ),
          children: <Widget>[
            const HomeBrandBar(),
            const SizedBox(height: AppSizes.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: profile == null
                  ? const SizedBox(height: 92)
                  : HomeIdentity(profile: profile),
            ),
            const SizedBox(height: AppSizes.xl),
            const PresenceCard(),
            const SizedBox(height: AppSizes.md + 2),
            _Grid(
              children: <Widget>[
                MistyDashboardCard(
                  icon: AppAssets.iconCalendar,
                  title: AppStrings.setAvailability,
                  subtitle: AppStrings.setAvailabilityHint,
                  onTap: () => context.go(AppRoutes.calendar),
                ),
                MistyDashboardCard(
                  icon: AppAssets.iconTalkNow,
                  title: AppStrings.talkNow,
                  subtitle: AppStrings.talkNowHint,
                  onTap: () => context.push(AppRoutes.goOnline),
                ),
                MistyDashboardCard(
                  icon: AppAssets.iconSessions,
                  title: AppStrings.upcomingSessions,
                  value: '${today.length} today',
                  onTap: () => context.push(AppRoutes.sessions),
                ),
                MistyDashboardCard(
                  icon: AppAssets.iconWallet,
                  title: AppStrings.earnings,
                  value: earnings == null ? '—' : Fmt.money(earnings.thisMonth),
                  valueCaption: AppStrings.thisMonth,
                  onTap: () => context.go(AppRoutes.earnings),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            EarningsInsightCard(
              summary: earnings,
              transactions:
                  transactions.valueOrNull ?? const <EarningTransaction>[],
              todaysSessions: today,
              loading: transactions.isLoading || earnings == null,
              onTap: () => context.go(AppRoutes.earnings),
            ),
            const SizedBox(height: AppSizes.lg),
            const HomeGuideVideos(),
            _RelaxationCard(onTap: _openRelaxation),
            const SizedBox(height: AppSizes.lg),
            const QuoteCard(),
          ],
        ),
      ),
    );
  }
}

class _RelaxationCard extends StatelessWidget {
  const _RelaxationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mintSoft,
      borderRadius: AppSizes.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.brCard,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.mintSoft,
            borderRadius: AppSizes.brCard,
            border: Border.all(color: AppColors.mintBorder),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  color: AppColors.mintInk,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'A Moment for You',
                      style: AppTypography.body(
                        16,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You are always there for others. Take a little time to pause, breathe, and reconnect with yourself.',
                      style: AppTypography.body(
                        13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      children: const <Widget>[
                        _RelaxationChip(label: 'Start Relaxation (English)'),
                        _RelaxationChip(label: 'Start Relaxation (Hindi)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: AppColors.mintInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelaxationChip extends StatelessWidget {
  const _RelaxationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: AppSizes.brPill,
        border: Border.all(color: AppColors.mintBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm + 2,
          vertical: 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.play_arrow_rounded,
              size: 15,
              color: AppColors.mintInk,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.body(
                12,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two equal columns whose rows take the height of their tallest card.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < children.length; i += 2) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSizes.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: children[i]),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
