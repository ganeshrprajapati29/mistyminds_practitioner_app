import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../data/models/transaction.dart';
import '../../../../state/providers.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  static const List<String> _filters = <String>['All', 'Sessions', 'Payouts'];
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final List<EarningTransaction> all =
        ref.watch(transactionsProvider).valueOrNull ??
        const <EarningTransaction>[];
    final List<EarningTransaction> shown = all
        .where(
          (EarningTransaction t) =>
              _filter == 0 || (_filter == 1 ? t.isCredit : !t.isCredit),
        )
        .toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const MistyAppBar(title: 'Transactions'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.sm,
              AppSizes.screenPadding,
              AppSizes.md,
            ),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _filters.length; i++) ...<Widget>[
                  MistyChip(
                    label: _filters[i],
                    selected: _filter == i,
                    onTap: () => setState(() => _filter = i),
                  ),
                  const SizedBox(width: AppSizes.sm),
                ],
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? const MistyEmptyState(
                    title: 'Nothing here yet',
                    message: 'Transactions will appear after your sessions.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      0,
                      AppSizes.screenPadding,
                      AppSizes.xxl,
                    ),
                    children: <Widget>[
                      MistyCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                          vertical: AppSizes.xs,
                        ),
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < shown.length; i++) ...<Widget>[
                              if (i > 0) const Divider(),
                              TransactionTile(tx: shown[i]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
