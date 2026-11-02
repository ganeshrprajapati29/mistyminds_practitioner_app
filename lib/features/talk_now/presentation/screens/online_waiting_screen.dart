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
import '../../../../core/widgets/misty_app_bar.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_cards.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../core/widgets/misty_toggle.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/talk_request.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../../../../state/realtime_bridge.dart';
import '../widgets/remaining_time_card.dart';

/// "You're Online · Waiting for a request..." — the fourth reference screen.
///
/// While online, the server is asked every few seconds whether a client is
/// waiting (`GET /practitioner/talk-requests/next`); the first one opens the
/// incoming-request screen.
class OnlineWaitingScreen extends ConsumerStatefulWidget {
  const OnlineWaitingScreen({super.key});

  @override
  ConsumerState<OnlineWaitingScreen> createState() =>
      _OnlineWaitingScreenState();
}

class _OnlineWaitingScreenState extends ConsumerState<OnlineWaitingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  /// A safety net only — requests normally arrive instantly over the
  /// socket (see state/realtime_bridge.dart).
  static const Duration _pollEvery = Duration(seconds: 8);

  Timer? _poll;

  /// True while a request is on screen or being fetched.
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(_pollEvery, (_) => _checkForRequest());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _breath.dispose();
    super.dispose();
  }

  Future<void> _checkForRequest() async {
    final PresenceState p = ref.read(presenceProvider);
    if (_handling || !mounted || !p.isOnline || !p.acceptTalkNow) return;
    // Not while a session is live. (The request screen opens above every
    // other screen, so anything else — e.g. a session summary — is fine.)
    if (inLiveConsultation) return;

    if (activeTalkRequest.value != null) return; // already on screen
    _handling = true;
    try {
      final TalkRequest? request = await ref
          .read(repositoryProvider)
          .nextTalkRequest();
      if (request == null || !mounted || activeTalkRequest.value != null) {
        return;
      }
      activeTalkRequest.value = request.id;
      await context.push<Object?>(AppRoutes.incomingRequest, extra: request);
      if (activeTalkRequest.value == request.id) activeTalkRequest.value = null;
      // Accepted → the session opens on its own route; declined or dismissed
      // → keep waiting for the next client.
    } catch (_) {
      // A missed poll is harmless; the next tick tries again.
    } finally {
      _handling = false;
    }
  }

  Future<void> _end() async {
    final bool ok = await AppFeedback.confirm(
      context,
      title: 'End availability?',
      message:
          'You’ll go offline and stop receiving Talk Now requests for today’s '
          'window.',
      confirmLabel: AppStrings.endSession,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final bool offline = await AppFeedback.guard(
      context,
      () => ref.read(presenceProvider.notifier).goOffline(),
    );
    if (!offline || !mounted) return;
    _poll?.cancel();
    context.go(AppRoutes.home);
    AppFeedback.toast(
      context,
      'You’re offline. Thank you for your time today.',
    );
  }

  Future<void> _togglePause(PresenceState p) async {
    final PresenceController c = ref.read(presenceProvider.notifier);
    await AppFeedback.guard(
      context,
      () => p.status == PresenceStatus.paused ? c.resume() : c.pause(),
    );
  }

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) => Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final PresenceState p = ref.watch(presenceProvider);
          return Padding(
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
                Text('Talk Now settings', style: AppTypography.displaySmall),
                const SizedBox(height: AppSizes.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        AppStrings.acceptTalkNow,
                        style: AppTypography.title,
                      ),
                    ),
                    MistyToggle(
                      value: p.acceptTalkNow,
                      onChanged: (bool v) => AppFeedback.guard(
                        context,
                        () => ref
                            .read(presenceProvider.notifier)
                            .setAcceptTalkNow(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                MistySecondaryButton(
                  label: 'Edit today’s availability',
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.context.go(AppRoutes.calendar);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PresenceState presence = ref.watch(presenceProvider);
    final bool paused = presence.status == PresenceStatus.paused;
    final bool compact = MediaQuery.sizeOf(context).height < 720;

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          MistyAppBar(
            trailing: MistyIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Talk Now settings',
              onPressed: _settings,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.sm,
                AppSizes.screenPadding,
                AppSizes.xl,
              ),
              children: <Widget>[
                _StatusPill(paused: paused),
                const SizedBox(height: AppSizes.md),
                Text(
                  paused ? AppStrings.pausedHint : AppStrings.onlineHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    14.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                RemainingTimeCard(window: presence.window, showProgress: true),
                const SizedBox(height: AppSizes.md),
                Center(
                  child: AnimatedBuilder(
                    animation: _breath,
                    builder: (BuildContext context, Widget? child) =>
                        Transform.scale(
                          scale: paused ? 1 : 0.96 + 0.06 * _breath.value,
                          child: child,
                        ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: paused ? 0.45 : 1,
                      child: Image.asset(
                        AppAssets.waitingRequest,
                        height: compact ? 170 : 210,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  paused ? 'Taking a pause' : AppStrings.waitingTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  paused
                      ? 'Resume whenever you’re ready.'
                      : AppStrings.waitingSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    14.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MistySecondaryButton(
                        label: paused
                            ? AppStrings.resumeAvailability
                            : AppStrings.pauseAvailability,
                        height: 50,
                        radius: AppSizes.radiusMd,
                        fontSize: 13.5,
                        color: AppColors.primaryStrong,
                        borderColor: AppColors.primaryMuted,
                        leading: Icon(
                          paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        onPressed: () => _togglePause(presence),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: MistySecondaryButton.danger(
                        label: AppStrings.endSession,
                        height: 50,
                        radius: AppSizes.radiusMd,
                        fontSize: 13.5,
                        leading: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        onPressed: _end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md + 2),
                const MistyInfoNote(
                  text: AppStrings.waitTip,
                  icon: Icons.lightbulb_outline_rounded,
                  center: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.paused});

  final bool paused;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md + 2),
      decoration: BoxDecoration(
        color: paused ? AppColors.amberSoft : AppColors.mintSoft,
        borderRadius: AppSizes.brPill,
        border: Border.all(
          color: paused
              ? AppColors.amber.withValues(alpha: 0.3)
              : AppColors.mintBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          PresenceDot(
            color: paused ? AppColors.amber : AppColors.online,
            size: 13,
            pulse: !paused,
          ),
          const SizedBox(width: AppSizes.xs),
          Text(
            paused ? AppStrings.availabilityPaused : AppStrings.youreOnline,
            style: AppTypography.body(19, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
