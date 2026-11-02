import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../../data/models/session.dart';
import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'misty_cards.dart';
import 'misty_profile_avatar.dart';
import 'misty_status_chip.dart';
import 'misty_svg_icon.dart';

/// A light, scannable session row: who, when, how long, which mode, status.
class MistySessionCard extends StatelessWidget {
  const MistySessionCard({super.key, required this.session, this.onTap});

  final Session session;
  final VoidCallback? onTap;

  static ChipTone toneFor(SessionStatus s) => switch (s) {
    SessionStatus.upcoming => ChipTone.violet,
    SessionStatus.completed => ChipTone.mint,
    SessionStatus.cancelled => ChipTone.coral,
  };

  @override
  Widget build(BuildContext context) {
    final Session s = session;
    final bool today = Fmt.sameDay(s.start, DateTime.now());

    return MistyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSizes.md + 2),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              MistyProfileAvatar(
                name: s.clientName,
                photoUrl: s.clientPhotoUrl,
                anonymous: s.anonymous,
                size: 46,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      s.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.concern,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              MistyStatusChip(label: s.status.label, tone: toneFor(s.status)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              borderRadius: AppSizes.brMd,
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${today ? 'Today' : Fmt.dayDate(s.start)} · ${Fmt.time(s.start)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(13, weight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Text(
                  '${s.duration.inMinutes} min',
                  style: AppTypography.body(13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                MistySvgIcon(s.mode.icon, tile: false, size: 18),
                const SizedBox(width: 4),
                Text(
                  s.mode.label,
                  style: AppTypography.body(13, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
