import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../data/calls/agora_call.dart';
import '../../../../data/realtime/realtime_service.dart';
import '../../../../navigation/app_routes.dart';
import '../../../../state/providers.dart';
import '../consultation_args.dart';

/// Adds a running session clock to a consultation screen.
mixin SessionClock<T extends StatefulWidget> on State<T> {
  Duration elapsed = Duration.zero;
  Timer? _clock;

  void startClock() {
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsed += const Duration(seconds: 1));
    });
  }

  void stopClock() => _clock?.cancel();

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}

/// Confirms, then closes the consultation and opens the summary.
Future<void> endConsultation(
  BuildContext context,
  WidgetRef ref, {
  required ConsultationArgs args,
  required Duration elapsed,
}) async {
  final bool ok = await AppFeedback.confirm(
    context,
    title: 'End this session?',
    message:
        'Make sure you’ve closed the conversation gently with your client.',
    confirmLabel: 'End Session',
    destructive: true,
  );
  if (!ok || !context.mounted) return;

  double? credited;
  final String? sessionId = args.sessionId;
  if (sessionId != null) {
    // The server completes the session and credits the psychologist; if that
    // fails, stay in the session rather than show a summary that isn't true.
    final bool completed = await AppFeedback.guard(context, () async {
      credited = await ref
          .read(sessionsProvider.notifier)
          .complete(sessionId, duration: elapsed);
    });
    if (!completed || !context.mounted) return;
  }
  context.pushReplacement(
    AppRoutes.sessionComplete,
    extra: SessionSummary(
      args: args,
      duration: elapsed,
      creditedAmount: credited,
    ),
  );
}

/// Closes a consultation the *client* ended from their app: the server has
/// already completed it, so this only fetches the credited amount (the call
/// is idempotent) and shows the summary.
Future<void> finishEndedByClient(
  BuildContext context,
  WidgetRef ref, {
  required ConsultationArgs args,
  required Duration elapsed,
}) async {
  double? credited;
  final String? sessionId = args.sessionId;
  if (sessionId != null) {
    try {
      credited = await ref
          .read(sessionsProvider.notifier)
          .complete(sessionId, duration: elapsed);
    } catch (_) {
      // The summary still shows; earnings refresh with the sessions list.
    }
  }
  if (!context.mounted) return;
  AppFeedback.toast(context, 'Your client ended the session.');
  context.pushReplacement(
    AppRoutes.sessionComplete,
    extra: SessionSummary(
      args: args,
      duration: elapsed,
      creditedAmount: credited,
    ),
  );
}

/// Watches for the client ending [args]' session from their side and runs
/// [onEnded] once. Returns the subscription so the screen can cancel it.
StreamSubscription<RealtimeEvent>? onClientEnded(
  WidgetRef ref,
  ConsultationArgs args,
  VoidCallback onEnded,
) {
  final String? sessionId = args.sessionId;
  if (sessionId == null) return null;
  return ref
      .read(realtimeProvider)
      ?.on('session:ended')
      .where(
        (RealtimeEvent e) =>
            e.data['sessionId'] == sessionId && e.data['by'] == 'client',
      )
      .take(1)
      .listen((_) => onEnded());
}

/// A short, calm line describing where a call is — null once connected.
String? callStatusText(CallPhase phase) => switch (phase) {
  CallPhase.connecting => 'Connecting…',
  CallPhase.waitingForPeer => 'Waiting for your client to join…',
  CallPhase.reconnecting => 'Reconnecting…',
  CallPhase.notConfigured =>
    'Calling isn’t set up on the server yet — this is a preview.',
  CallPhase.permissionDenied =>
    'Allow microphone and camera access in Settings to talk.',
  CallPhase.failed =>
    'The call couldn’t connect. Please check your connection.',
  CallPhase.connected || CallPhase.ended => null,
};

/// A round call control with a caption underneath.
class CallControlButton extends StatelessWidget {
  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
    this.dark = false,
    this.size = 62,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Toggled on (e.g. muted) — drawn filled.
  final bool active;
  final bool danger;

  /// For the video stage: light-on-dark styling.
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color bg = danger
        ? AppColors.coral
        : active
        ? (dark ? Colors.white : AppColors.primary)
        : (dark ? Colors.white.withValues(alpha: 0.14) : AppColors.surface);
    final Color ink = danger
        ? Colors.white
        : active
        ? (dark ? AppColors.callStage : Colors.white)
        : (dark ? Colors.white : AppColors.textPrimary);

    return Semantics(
      button: true,
      toggled: danger ? null : active,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: bg,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: dark || danger ? null : AppColors.softShadow,
                ),
                child: Icon(icon, color: ink, size: size * 0.42),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.body(
              12.5,
              weight: FontWeight.w500,
              color: dark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
