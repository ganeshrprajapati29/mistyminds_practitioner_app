import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx});

  final EarningTransaction tx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm + 2),
      child: Row(
        children: <Widget>[
          MistySvgIcon(tx.mode?.icon ?? AppAssets.iconWallet, size: 44),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(tx.title, style: AppTypography.title),
                const SizedBox(height: 2),
                Text(
                  '${tx.subtitle} · ${Fmt.shortDate(tx.date)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
                if (tx.grossAmount != null) ...<Widget>[
                  const SizedBox(height: 3),
                  if (tx.isCredit &&
                      tx.durationMinutes != null &&
                      tx.ratePerMinute != null)
                    Text(
                      '${tx.durationMinutes} min × ${Fmt.money(tx.ratePerMinute!)}/min = ${Fmt.money(tx.grossAmount!)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    )
                  else if (!tx.isCredit && tx.sessionCount != null)
                    Text(
                      '${tx.sessionCount} sessions · ${tx.durationMinutes ?? 0} min · ${Fmt.money(tx.grossAmount!)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                  Text(
                    'Misty Minds ${Fmt.money(tx.platformShare ?? 0)} · Your share ${Fmt.money(tx.doctorGross ?? 0)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    '− GST ${Fmt.money(tx.gstAmount ?? 0)} · − TDS ${Fmt.money(tx.tdsAmount ?? 0)}'
                    '${(tx.adjustment ?? 0) != 0 ? ' · ${tx.adjustment! > 0 ? '+ Bonus' : '− Deduction'} ${Fmt.money(tx.adjustment!.abs())}' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    '${tx.isCredit ? 'Net earned' : 'Net paid'} ${Fmt.money(tx.amount)}',
                    style: AppTypography.body(
                      12.5,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${tx.isCredit ? '+' : '−'} ${Fmt.money(tx.amount)}',
                style: AppTypography.body(
                  15,
                  weight: FontWeight.w700,
                  color: tx.isCredit
                      ? AppColors.mintInk
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              MistyStatusChip(
                label: tx.status.label,
                tone: tx.status == TransactionStatus.completed
                    ? ChipTone.grey
                    : ChipTone.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
