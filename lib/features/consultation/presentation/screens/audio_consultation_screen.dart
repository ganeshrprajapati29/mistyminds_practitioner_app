import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_status_chip.dart';
import '../../../../data/calls/agora_call.dart';
import '../consultation_args.dart';
import '../widgets/consultation_widgets.dart';

/// Audio consultation over Agora RTC, with the credentials the backend
/// minted for this session (`ConsultationArgs.call`).
class AudioConsultationScreen extends ConsumerStatefulWidget {
  const AudioConsultationScreen({super.key, required this.args});

  final ConsultationArgs args;

  @override
  ConsumerState<AudioConsultationScreen> createState() =>
      _AudioConsultationScreenState();
}

class _AudioConsultationScreenState
    extends ConsumerState<AudioConsultationScreen>
    with SessionClock<AudioConsultationScreen>, SingleTickerProviderStateMixin {
  late final AnimationController _voice = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  late final AgoraCall _call = AgoraCall(
    credentials: widget.args.call,
    video: false,
  )..speakerOn = true;
  StreamSubscription<Object?>? _clientEnded;

  bool get _muted => _call.muted;
  bool get _speaker => _call.speakerOn;

  @override
  void initState() {
    super.initState();
    startClock();
    _call.addListener(_onCall);
    unawaited(_call.start());
    _clientEnded = onClientEnded(
      ref,
      widget.args,
      () => finishEndedByClient(
        context,
        ref,
        args: widget.args,
        elapsed: elapsed,
      ),
    );
  }

  void _onCall() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(_clientEnded?.cancel());
    _call.removeListener(_onCall);
    _call.dispose();
    _voice.dispose();
    super.dispose();
  }

  void _end() =>
      endConsultation(context, ref, args: widget.args, elapsed: elapsed);

  @override
  Widget build(BuildContext context) {
    final ConsultationArgs a = widget.args;
    final double avatar = (MediaQuery.sizeOf(context).width * 0.38).clamp(
      120.0,
      170.0,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _end();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.calmGradient),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSizes.lg),
                const MistyStatusChip(
                  label: 'Encrypted audio session',
                  tone: ChipTone.violet,
                  dot: true,
                ),
                const Spacer(),
                SizedBox(
                  width: avatar * 1.7,
                  height: avatar * 1.7,
                  child: AnimatedBuilder(
                    animation: _voice,
                    builder: (BuildContext context, Widget? child) => Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        // Two soft rings drift outward while the line is live.
                        for (final double offset in <double>[0, 0.5])
                          _ring(avatar, (_voice.value + offset) % 1),
                        child!,
                      ],
                    ),
                    child: MistyProfileAvatar(
                      name: a.clientName,
                      photoUrl: a.photoUrl,
                      anonymous: a.anonymous,
                      size: avatar,
                      ring: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(a.clientName, style: AppTypography.displayMedium),
                const SizedBox(height: AppSizes.xs),
                Text(
                  Fmt.clock(elapsed),
                  style: AppTypography.body(
                    17,
                    weight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  callStatusText(_call.phase) ?? a.concern,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      CallControlButton(
                        icon: _muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: _muted ? 'Unmute' : 'Mute',
                        active: _muted,
                        onTap: _call.toggleMute,
                      ),
                      CallControlButton(
                        icon: Icons.call_end_rounded,
                        label: 'End',
                        danger: true,
                        size: 72,
                        onTap: _end,
                      ),
                      CallControlButton(
                        icon: _speaker
                            ? Icons.volume_up_rounded
                            : Icons.hearing_rounded,
                        label: _speaker ? 'Speaker' : 'Earpiece',
                        active: _speaker,
                        onTap: _call.toggleSpeaker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double base, double t) => Container(
    width: base * (1 + 0.7 * t),
    height: base * (1 + 0.7 * t),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.primary.withValues(alpha: 0.10 * (1 - t)),
    ),
  );
}
