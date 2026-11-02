import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_svg_icon.dart';
import '../../../../data/audio/request_sounds.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/talk_request.dart';
import '../../../../data/realtime/realtime_service.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../../../../state/realtime_bridge.dart';

/// "Someone needs to talk." — the fifth reference screen.
///
/// Pops with `true` when accepted and `false` when declined, so the waiting
/// screen knows whether to keep listening.
class IncomingRequestScreen extends ConsumerStatefulWidget {
  const IncomingRequestScreen({super.key, required this.request});

  final TalkRequest request;

  @override
  ConsumerState<IncomingRequestScreen> createState() =>
      _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends ConsumerState<IncomingRequestScreen> {
  StreamSubscription<RealtimeEvent>? _resolved;
  bool _busy = false;

  TalkRequest get request => widget.request;

  /// "Incoming video call" — what kind of session is being asked for.
  String get _headline => switch (request.mode) {
    ConsultMode.chat => 'Incoming chat request',
    ConsultMode.audio => 'Incoming audio call',
    ConsultMode.video => 'Incoming video call',
  };

  /// The tiles under the client's name; only what is actually known.
  List<_Detail> get _details {
    final RequestDetails d = request.details;
    return <_Detail>[
      (
        icon: request.mode.icon,
        label: 'Session type',
        value: request.mode.requestLabel,
        wide: false,
      ),
      (
        icon: AppAssets.iconClock,
        label: 'Duration',
        value: '~ ${request.expectedMinutes} min',
        wide: false,
      ),
      if (_concerns.isNotEmpty)
        (
          icon: AppAssets.iconSessions,
          label: 'Concern',
          value: _concerns,
          wide: _concerns.length > 16,
        ),
      if (d.intent != null)
        (
          icon: AppAssets.iconChat,
          label: 'Looking for',
          value: d.intent!,
          wide: d.intent!.length > 16,
        ),
      if (d.mood != null)
        (
          icon: AppAssets.iconHome,
          label: 'Feeling',
          value: d.mood!,
          wide: false,
        ),
      if (d.language != null)
        (
          icon: AppAssets.iconProfile,
          label: 'Language',
          value: d.language!,
          wide: false,
        ),
      if (d.fee != null)
        (
          icon: AppAssets.iconWallet,
          label: 'Session fee',
          value: Fmt.inr(d.fee!),
          wide: false,
        ),
      if (d.previousSessions != null)
        (
          icon: AppAssets.iconClients,
          label: AppStrings.client,
          value: switch (d.previousSessions!) {
            0 => 'New client · first session with you',
            1 => 'Returning · 1 session with you',
            final int n => 'Returning · $n sessions with you',
          },
          wide: true,
        ),
    ];
  }

  /// The concern for this session, then anything else they have shared.
  String get _concerns => <String>{
    if (request.concern.trim().isNotEmpty) request.concern.trim(),
    ...request.details.concerns,
  }.take(4).join(', ');

  @override
  void initState() {
    super.initState();
    activeTalkRequest.value = request.id;
    // Ring until the psychologist answers (or the request goes away).
    unawaited(RequestSounds.instance.startRinging());
    // If the request lapses (the client left, or 2 minutes passed) while it
    // is on screen, close it rather than let the psychologist accept a ghost.
    _resolved = ref
        .read(realtimeProvider)
        ?.on('talk:resolved')
        .where((RealtimeEvent e) => e.data['id'] == request.id)
        .listen((RealtimeEvent e) {
          if (!mounted || _busy || e.data['status'] != 'expired') return;
          AppFeedback.toast(context, 'The client is no longer waiting.');
          context.pop(false);
        });
  }

  @override
  void dispose() {
    unawaited(_resolved?.cancel());
    unawaited(RequestSounds.instance.stopRinging());
    if (activeTalkRequest.value == request.id) activeTalkRequest.value = null;
    super.dispose();
  }

  Future<void> decline() async {
    if (_busy) return;
    _busy = true;
    unawaited(RequestSounds.instance.stopRinging());
    unawaited(RequestSounds.instance.playDeclined());
    // The client is refunded in full; the psychologist stays online.
    await AppFeedback.guard(
      context,
      () => ref.read(repositoryProvider).declineRequest(request.id),
    );
    if (mounted) context.pop(false);
  }

  Future<void> accept() async {
    if (_busy) return;
    _busy = true;
    unawaited(RequestSounds.instance.stopRinging());
    AcceptedTalk? accepted;
    final bool ok = await AppFeedback.guard(context, () async {
      accepted = await ref.read(repositoryProvider).acceptRequest(request.id);
    });
    if (ok) unawaited(RequestSounds.instance.playAccepted());
    if (!mounted) return;
    final GoRouter router = GoRouter.of(context);
    router.pop(ok);
    // Accepted → the paid session opens straight away. If the client had
    // already gone (request expired), we simply return to waiting.
    if (ok) router.push(AppRoutes.requestAccepted, extra: accepted);
    ref.invalidate(sessionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).height < 720;

    // Its own full-screen page (above tabs, summaries and anything else), so
    // it brings its own Scaffold; the system back button declines, like the
    // back arrow, instead of leaving the client waiting.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) decline();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _content(compact),
      ),
    );
  }

  Widget _content(bool compact) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          MistyAppBar(onBack: decline),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                0,
                AppSizes.screenPadding,
                AppSizes.lg,
              ),
              children: <Widget>[
                Center(child: _NewRequestChip(label: _headline)),
                const SizedBox(height: AppSizes.md),
                Text.rich(
                  TextSpan(
                    text:
                        '${AppStrings.someoneNeedsToTalk.replaceAll('\n', ' ')} ',
                    children: const <InlineSpan>[
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.lilacHeart,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.display(
                    compact ? 22 : 25,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                MistyCard(
                  radius: AppSizes.radiusCard,
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: AppSizes.xs),
                      MistyProfileAvatar(
                        name: request.clientName,
                        photoUrl: request.clientPhotoUrl,
                        anonymous: request.anonymous,
                        size: compact ? 60 : 72,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Who is asking.
                      Text(
                        request.anonymous
                            ? AppStrings.anonymous
                            : request.clientName,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          19,
                          weight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      if (request.details.identityLine.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          request.details.identityLine,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.sm + 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                        ),
                        child: Text(
                          '“${request.message}”',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(
                            16.5,
                            weight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested ${Fmt.ago(request.requestedAt)}',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSizes.md),
                      // Everything known about the request, two to a row.
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints box) {
                          final double half = (box.maxWidth - AppSizes.sm) / 2;
                          return Wrap(
                            spacing: AppSizes.sm,
                            runSpacing: AppSizes.sm,
                            children: <Widget>[
                              for (final _Detail d in _details)
                                SizedBox(
                                  width: d.wide ? box.maxWidth : half,
                                  child: _DetailRow(
                                    icon: d.icon,
                                    label: d.label,
                                    value: d.value,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.xs,
              AppSizes.screenPadding,
              AppSizes.md,
            ),
            child: Column(
              children: <Widget>[
                MistyPrimaryButton(
                  label: AppStrings.acceptRequest,
                  onPressed: accept,
                ),
                const SizedBox(height: AppSizes.sm + 2),
                MistySecondaryButton(
                  label: AppStrings.notNow,
                  height: 50,
                  color: AppColors.textSecondary,
                  onPressed: decline,
                ),
                const SizedBox(height: AppSizes.sm + 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.info_rounded,
                      size: 18,
                      color: AppColors.primaryMuted,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        AppStrings.declineNote,
                        style: AppTypography.body(
                          12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewRequestChip extends StatelessWidget {
  const _NewRequestChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 16, 7),
      decoration: const BoxDecoration(
        color: AppColors.lavender,
        borderRadius: AppSizes.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const MistySvgIcon(AppAssets.iconTalkNow, tile: false, size: 20),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.body(13.5, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// One fact about the request: an icon, what it is, and its value.
typedef _Detail = ({String icon, String label, String value, bool wide});

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm + 2,
        vertical: AppSizes.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.lavender,
        borderRadius: AppSizes.brMd,
      ),
      child: Row(
        children: <Widget>[
          MistySvgIcon(icon, tile: false, size: 22),
          const SizedBox(width: AppSizes.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    11.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    13.5,
                    weight: FontWeight.w600,
                    height: 1.3,
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
