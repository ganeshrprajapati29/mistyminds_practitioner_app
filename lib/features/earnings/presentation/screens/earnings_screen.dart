import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../data/models/transaction.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../widgets/transaction_tile.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  Future<void> _payout(BuildContext context, WidgetRef ref, double amount) async {
    if (amount <= 0) {
      AppFeedback.toast(context, 'There’s nothing waiting to be paid out yet.');
      return;
    }
    final BankDetails? bank = ref.read(profileProvider).valueOrNull?.bank;
    final String last4 = (bank?.accountMasked ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final String to = bank == null
        ? 'your bank account'
        : '${bank.bank}${last4.length >= 4 ? ' ••${last4.substring(last4.length - 4)}' : ''}';
    final bool confirmed = await AppFeedback.confirm(
      context,
      title: 'Request payout?',
      message:
          '${Fmt.money(amount)} will be sent to $to within 1–2 working days.',
      confirmLabel: 'Request',
    );
    if (!confirmed || !context.mounted) return;
    final bool ok = await AppFeedback.guard(
      context,
      () => ref.read(repositoryProvider).requestPayout(),
    );
    if (!ok || !context.mounted) return;
    ref
      ..invalidate(earningsSummaryProvider)
      ..invalidate(transactionsProvider)
      ..invalidate(notificationsProvider);
    AppFeedback.toast(context, 'Payout requested');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EarningsSummary> summary = ref.watch(
      earningsSummaryProvider,
    );
    final EarningsSummary? s = summary.valueOrNull;
    final List<EarningTransaction> txs =
        ref.watch(transactionsProvider).valueOrNull ??
        const <EarningTransaction>[];

    return SafeArea(
      bottom: false,
      child: s == null
          ? summary.hasError
                ? Center(
                    child: MistyErrorState(
                      onRetry: () => ref
                        ..invalidate(earningsSummaryProvider)
                        ..invalidate(transactionsProvider),
                    ),
                  )
                : const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSizes.xxl),
              children: <Widget>[
                const MistyPageTitle(
                  title: 'Earnings',
                  subtitle: 'Your practice at a glance',
                  trailing: MistySvgIcon(AppAssets.iconWallet, size: 52),
                ),
                Padding(
                  padding: AppSizes.pageInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      MistyGradientCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Total Earnings',
                              style: AppTypography.body(
                                14,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Fmt.money(s.total),
                              style: AppTypography.display(
                                36,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSizes.lg),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    'Payout available from your approved balance',
                                    style: AppTypography.body(
                                      13,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ),
                                FilledButton(
                                    onPressed: s.payoutDue && s.pendingPayout > 0
                                      ? () => _payout(context, ref, s.pendingPayout)
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primaryStrong,
                                    textStyle: AppTypography.body(
                                      13.5,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Request Payout'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Row(
                        children: <Widget>[
                          _StatTile(
                            label: 'Today',
                            value: Fmt.money(s.today),
                            icon: Icons.wb_sunny_outlined,
                          ),
                          const SizedBox(width: AppSizes.md),
                          _StatTile(
                            label: 'Current Earnings',
                            value: Fmt.money(s.thisMonth),
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: <Widget>[
                          _StatTile(
                            label: 'Completed Sessions',
                            value: '${s.completedSessions}',
                            icon: Icons.check_circle_outline_rounded,
                            mint: true,
                          ),
                          const SizedBox(width: AppSizes.md),
                          _StatTile(
                            label: 'Pending Payout',
                            value: Fmt.money(s.pendingPayout),
                            icon: Icons.schedule_rounded,
                            amber: true,
                          ),
                        ],
                      ),
                      if (s.ratePerMinute > 0) ...<Widget>[
                        const SizedBox(height: AppSizes.lg),
                        _MyRateTile(summary: s),
                      ],
                      if (s.thisMonthBreakdown != null) ...<Widget>[
                        const SizedBox(height: AppSizes.xl),
                        const MistySectionHeader(title: 'Earnings Split'),
                        _SplitCard(
                          summary: s,
                          split: s.thisMonthBreakdown!,
                        ),
                      ],
                      const SizedBox(height: AppSizes.xl),
                      MistySectionHeader(
                        title: 'Recent Transactions',
                        actionLabel: 'View all',
                        onAction: () => context.push(AppRoutes.transactions),
                      ),
                      MistyCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                          vertical: AppSizes.xs,
                        ),
                        child: Column(
                          children: <Widget>[
                            for (
                              int i = 0;
                              i < txs.length && i < 4;
                              i++
                            ) ...<Widget>[
                              if (i > 0) const Divider(),
                              TransactionTile(tx: txs[i]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      MistyInfoNote(
                        text:
                            'Misty Minds keeps ${_pct(s.platformSharePercent)}, and GST '
                            '(${_pct(s.gstPercent)}) and TDS '
                            '(${_pct(s.tdsPercent)}) are deducted from your '
                            '${_pct(s.doctorSharePercent)} share. Sessions are '
                            'billed per minute.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

String _pct(double v) =>
    '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}%';

/// Only the psychologist's own per-minute rate — the one for their years of
/// experience. The full rate chart for other bands is not shown.
class _MyRateTile extends StatelessWidget {
  const _MyRateTile({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final EarningsSummary s = summary;
    // Per-mode rates are listed only when they differ from one another.
    final Set<double> distinct = s.modeRates.values.toSet();
    final bool perMode = distinct.length > 1;
    final double rate = distinct.length == 1 ? distinct.first : s.ratePerMinute;

    return MistyCard(
      padding: const EdgeInsets.all(AppSizes.md + 2),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Your rate per minute', style: AppTypography.bodySmall),
                const SizedBox(height: 2),
                Text(
                  perMode
                      ? s.modeRates.entries
                            .map(
                              (MapEntry<ConsultMode, double> r) =>
                                  '${r.key.label} ${Fmt.money(r.value)}',
                            )
                            .join(' · ')
                      : 'Per-minute session rate',
                  style: AppTypography.body(13, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (!perMode)
            Text(
              '${Fmt.money(rate)} / min',
              style: AppTypography.body(
                19,
                weight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Session earnings → Misty Minds' share → your share → GST → TDS → net.
class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.summary, required this.split});

  final EarningsSummary summary;
  final EarningsBreakdown split;

  @override
  Widget build(BuildContext context) {
    Widget line(String label, double amount, {bool minus = false, bool strong = false}) {
      final TextStyle style = strong
          ? AppTypography.body(15, weight: FontWeight.w700)
          : AppTypography.body(13.5, color: AppColors.textSecondary);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: style)),
            Text(
              '${minus ? '− ' : ''}${Fmt.money(amount)}',
              style: strong
                  ? AppTypography.body(15, weight: FontWeight.w700, color: AppColors.mintInk)
                  : style,
            ),
          ],
        ),
      );
    }

    return MistyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${split.sessions} sessions · ${split.minutes} minutes',
            style: AppTypography.body(13, weight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.sm),
          line('Session earnings', split.grossAmount),
          line('Misty Minds (${_pct(summary.platformSharePercent)})', split.platformShare, minus: true),
          line('Your share (${_pct(summary.doctorSharePercent)})', split.doctorGross),
          line('GST (${_pct(summary.gstPercent)})', split.gstAmount, minus: true),
          line('TDS (${_pct(summary.tdsPercent)})', split.tdsAmount, minus: true),
          const Divider(),
          line('Net earnings', split.netAmount, strong: true),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.mint = false,
    this.amber = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool mint;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color ink) = mint
        ? (AppColors.mintSoft, AppColors.mintInk)
        : amber
        ? (AppColors.amberSoft, AppColors.amber)
        : (AppColors.lavender, AppColors.primary);
    return Expanded(
      child: MistyCard(
        padding: const EdgeInsets.all(AppSizes.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ink, size: 20),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(19, weight: FontWeight.w700),
            ),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}
