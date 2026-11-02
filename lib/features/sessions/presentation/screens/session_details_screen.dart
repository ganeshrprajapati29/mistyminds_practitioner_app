import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_empty_state.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_session_card.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/session.dart';
import '../../../../data/models/talk_request.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../../../consultation/presentation/consultation_args.dart';

class SessionDetailsScreen extends ConsumerWidget {
  const SessionDetailsScreen({super.key, required this.sessionId});

  final String sessionId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final String? reason = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          0,
          AppSizes.screenPadding,
          AppSizes.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Why are you cancelling?', style: AppTypography.displaySmall),
            const SizedBox(height: AppSizes.xs),
            Text(
              'The client is notified and fully refunded.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSizes.lg),
            for (final String r in <String>[
              'Personal emergency',
              'Feeling unwell',
              'Scheduling conflict',
              'Other',
            ])
              MistyMenuTileLite(
                label: r,
                onTap: () => Navigator.of(context).pop(r),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !context.mounted) return;
    final bool ok = await AppFeedback.guard(
      context,
      () => ref.read(sessionsProvider.notifier).cancel(sessionId, reason),
    );
    if (ok && context.mounted) {
      AppFeedback.toast(context, 'Session cancelled · your client is refunded');
    }
  }

  Future<void> _reschedule(
    BuildContext context,
    WidgetRef ref,
    Session s,
  ) async {
    final bool ok = await AppFeedback.guard(
      context,
      () => ref.read(sessionsProvider.notifier).requestReschedule(s.id),
    );
    if (ok && context.mounted) {
      AppFeedback.toast(context, 'Reschedule request sent to ${s.clientName}');
    }
  }

  /// Opens the session on the server first — it only opens from 15 minutes
  /// before the start time — then shows the right consultation screen.
  Future<void> _start(BuildContext context, WidgetRef ref, Session s) async {
    ConsultationRoom? room;
    final bool ok = await AppFeedback.guard(context, () async {
      room = await ref.read(repositoryProvider).startSession(s.id);
    });
    if (!ok || !context.mounted) return;
    final ConsultationRoom opened = room ?? ConsultationRoom(session: s);
    final String route = switch (opened.session.mode) {
      ConsultMode.chat => AppRoutes.chat,
      ConsultMode.audio => AppRoutes.audio,
      ConsultMode.video => AppRoutes.video,
    };
    context.push(route, extra: ConsultationArgs.fromRoom(opened));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session? s = ref.watch(sessionByIdProvider(sessionId));

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const MistyAppBar(title: 'Session Details'),
          Expanded(
            child: s == null
                ? const MistyEmptyState(
                    title: 'Session not found',
                    message: 'It may have been removed.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      AppSizes.sm,
                      AppSizes.screenPadding,
                      AppSizes.xxl,
                    ),
                    children: <Widget>[
                      MistyCard(
                        radius: AppSizes.radiusCard,
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: Column(
                          children: <Widget>[
                            MistyProfileAvatar(
                              name: s.clientName,
                              photoUrl: s.clientPhotoUrl,
                              anonymous: s.anonymous,
                              size: 84,
                            ),
                            const SizedBox(height: AppSizes.md),
                            Text(
                              s.clientName,
                              style: AppTypography.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(s.concern, style: AppTypography.bodyMedium),
                            const SizedBox(height: AppSizes.md),
                            MistyStatusChip(
                              label: s.status.label,
                              tone: MistySessionCard.toneFor(s.status),
                              dot: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      MistyCard(
                        child: Column(
                          children: <Widget>[
                            MistyInfoRow(
                              label: 'Date',
                              value: Fmt.longDate(s.start),
                            ),
                            MistyInfoRow(
                              label: 'Time',
                              value:
                                  '${Fmt.time(s.start)} – ${Fmt.time(s.end)}',
                            ),
                            MistyInfoRow(
                              label: 'Duration',
                              value: '${s.duration.inMinutes} minutes',
                            ),
                            MistyInfoRow(
                              label: 'Mode',
                              value: s.mode.label,
                              leading: MistySvgIcon(
                                s.mode.icon,
                                tile: false,
                                size: 20,
                              ),
                            ),
                            MistyInfoRow(label: 'Fee', value: Fmt.inr(s.fee)),
                            if (s.anonymous)
                              const MistyInfoRow(
                                label: 'Identity',
                                value: 'Anonymous',
                              ),
                          ],
                        ),
                      ),
                      if (s.cancelReason != null) ...<Widget>[
                        const SizedBox(height: AppSizes.md),
                        MistyInfoNote(
                          text: s.cancelReason!,
                          icon: Icons.event_busy_rounded,
                          iconColor: AppColors.coral,
                          color: AppColors.coralSoft,
                        ),
                      ],
                      if (s.notes != null) ...<Widget>[
                        const SizedBox(height: AppSizes.md),
                        MistyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Your private notes',
                                    style: AppTypography.title,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(s.notes!, style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                      if (s.status == SessionStatus.upcoming) ...<Widget>[
                        const SizedBox(height: AppSizes.xl),
                        MistyPrimaryButton(
                          label: 'Start Session',
                          onPressed: () => _start(context, ref, s),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: MistySecondaryButton(
                                label: 'Reschedule',
                                height: 50,
                                onPressed: () => _reschedule(context, ref, s),
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: MistySecondaryButton.danger(
                                label: 'Cancel',
                                height: 50,
                                onPressed: () => _cancel(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!s.anonymous) ...<Widget>[
                        const SizedBox(height: AppSizes.md),
                        Center(
                          child: MistyLinkButton(
                            label: 'View client history',
                            arrow: true,
                            onPressed: () =>
                                context.go(AppRoutes.clientDetails(s.clientId)),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// A plain tappable option row for small pickers.
class MistyMenuTileLite extends StatelessWidget {
  const MistyMenuTileLite({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSizes.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md + 2,
          horizontal: AppSizes.xs,
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: AppTypography.bodyLarge)),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
