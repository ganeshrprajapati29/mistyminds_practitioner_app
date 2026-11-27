import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../../state/app_content_provider.dart';
import '../../../../state/providers.dart';
import '../../../guide/presentation/widgets/guide_video_tiles.dart';
import '../widgets/earnings_insight_card.dart';
import '../widgets/home_header.dart';
import '../widgets/presence_card.dart';
import '../widgets/push_health_banner.dart';
import '../widgets/quote_card.dart';

/// The psychologist dashboard, reproduced from the first reference screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String _relaxationUrl =
      'https://youtube.com/@mistyminds1?si=EQ5lZBtfZcytw8JI';

  /// Content page for this screen (admin console → App content).
  static const String _page = 'dashboard';

  /// Runs [normal] — unless the admin attached a link to this card.
  static VoidCallback _tap(AppContent c, String key, VoidCallback normal) {
    final String? url = c.link(_page, key);
    return url == null ? normal : () => openContentLink(url);
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
    final AppContent c = ref.watch(appContentProvider);
    String t(String key, String fallback) => c.text(_page, key, fallback);
    final List<ContentLink> extraLinks = c.links(_page);

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
          await ref.read(appContentProvider.notifier).refresh();
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
            const PushHealthBanner(),
            const PresenceCard(),
            const SizedBox(height: AppSizes.md + 2),
            _Grid(
              children: <Widget>[
                MistyDashboardCard(
                  icon: AppAssets.iconCalendar,
                  title: t('availability.title', AppStrings.setAvailability),
                  subtitle: t(
                    'availability.hint',
                    AppStrings.setAvailabilityHint,
                  ),
                  onTap: _tap(
                    c,
                    'availability.url',
                    () => context.go(AppRoutes.calendar),
                  ),
                ),
                MistyDashboardCard(
                  icon: AppAssets.iconTalkNow,
                  title: t('talkNow.title', AppStrings.talkNow),
                  subtitle: t('talkNow.hint', AppStrings.talkNowHint),
                  onTap: _tap(
                    c,
                    'talkNow.url',
                    () => context.push(AppRoutes.goOnline),
                  ),
                ),
                MistyDashboardCard(
                  icon: AppAssets.iconSessions,
                  title: t('sessions.title', AppStrings.upcomingSessions),
                  value: '${today.length} today',
                  onTap: _tap(
                    c,
                    'sessions.url',
                    () => context.push(AppRoutes.sessions),
                  ),
                ),
                MistyDashboardCard(
                  icon: AppAssets.iconWallet,
                  title: t('earnings.title', AppStrings.earnings),
                  value: earnings == null ? '—' : Fmt.money(earnings.thisMonth),
                  valueCaption: AppStrings.thisMonth,
                  onTap: _tap(
                    c,
                    'earnings.url',
                    () => context.go(AppRoutes.earnings),
                  ),
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
            _RelaxationCard(
              title: t('relaxation.title', 'A Moment for You'),
              body: t(
                'relaxation.body',
                'You are always there for others. Take a little time to pause, breathe, and reconnect with yourself.',
              ),
              chips: <String>[
                c.optional(
                  _page,
                  'relaxation.chip1',
                  'Start Relaxation (English)',
                ),
                c.optional(
                  _page,
                  'relaxation.chip2',
                  'Start Relaxation (Hindi)',
                ),
              ].where((String s) => s.isNotEmpty).toList(),
              onTap: () => openContentLink(
                c.link(_page, 'relaxation.url', fallback: _relaxationUrl) ??
                    _relaxationUrl,
              ),
            ),
            if (extraLinks.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSizes.lg),
              Text(
                t('links.title', 'Helpful resources'),
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSizes.sm),
              for (final ContentLink l in extraLinks) ...<Widget>[
                _LinkCard(link: l),
                const SizedBox(height: AppSizes.sm),
              ],
            ],
            const SizedBox(height: AppSizes.lg),
            QuoteCard(text: t('quote.text', AppStrings.homeQuote)),
          ],
        ),
      ),
    );
  }
}

class _RelaxationCard extends StatelessWidget {
  const _RelaxationCard({
    required this.title,
    required this.body,
    required this.chips,
    required this.onTap,
  });

  final String title;
  final String body;
  final List<String> chips;
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
                      title,
                      style: AppTypography.body(
                        16,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: AppTypography.body(
                        13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    if (chips.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSizes.md),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: <Widget>[
                          for (final String label in chips)
                            _RelaxationChip(label: label),
                        ],
                      ),
                    ],
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

/// One of the admin's own link cards (App content → Home dashboard).
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link});

  final ContentLink link;

  @override
  Widget build(BuildContext context) {
    final bool video = RegExp(
      r'youtu\.?be',
      caseSensitive: false,
    ).hasMatch(link.url);
    return Material(
      color: AppColors.surface,
      borderRadius: AppSizes.brCard,
      child: InkWell(
        onTap: () => openContentLink(link.url),
        borderRadius: AppSizes.brCard,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md + 2),
          decoration: BoxDecoration(
            borderRadius: AppSizes.brCard,
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                video
                    ? Icons.play_circle_outline_rounded
                    : Icons.link_rounded,
                color: AppColors.mintInk,
                size: 26,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(link.title, style: AppTypography.title),
                    if (link.subtitle.isNotEmpty)
                      Text(link.subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
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
