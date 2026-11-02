import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../data/calls/agora_call.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../state/providers.dart';
import '../consultation_args.dart';
import '../widgets/consultation_widgets.dart';

/// Video consultation over Agora RTC. The stage shows the client's camera
/// once it's live; the corner tile is the psychologist's own camera.
class VideoConsultationScreen extends ConsumerStatefulWidget {
  const VideoConsultationScreen({super.key, required this.args});

  final ConsultationArgs args;

  @override
  ConsumerState<VideoConsultationScreen> createState() =>
      _VideoConsultationScreenState();
}

class _VideoConsultationScreenState
    extends ConsumerState<VideoConsultationScreen>
    with SessionClock<VideoConsultationScreen> {
  late final AgoraCall _call = AgoraCall(
    credentials: widget.args.call,
    video: true,
  );
  StreamSubscription<Object?>? _clientEnded;

  bool get _muted => _call.muted;
  bool get _cameraOn => _call.cameraOn;
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
    super.dispose();
  }

  void _end() =>
      endConsultation(context, ref, args: widget.args, elapsed: elapsed);

  @override
  Widget build(BuildContext context) {
    final ConsultationArgs a = widget.args;
    final Psychologist? me = ref.watch(profileProvider).valueOrNull;
    final Widget? remote = _call.remoteView();
    final String? status = callStatusText(_call.phase);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (!didPop) _end();
        },
        child: Scaffold(
          backgroundColor: AppColors.callStage,
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.callGradient),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      AppSizes.sm,
                      AppSizes.lg,
                      AppSizes.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                a.clientName,
                                style: AppTypography.body(
                                  18,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Video session · ${Fmt.clock(elapsed)}',
                                style: AppTypography.body(
                                  13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: AppSizes.brPill,
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.lock_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Encrypted',
                                style: AppTypography.body(
                                  12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                      ),
                      child: Stack(
                        children: <Widget>[
                          if (remote != null)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: remote,
                              ),
                            )
                          else
                            // Main participant stage.
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.02),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      MistyProfileAvatar(
                                        name: a.clientName,
                                        photoUrl: a.photoUrl,
                                        anonymous: a.anonymous,
                                        size: 150,
                                      ),
                                      const SizedBox(height: AppSizes.lg),
                                      Text(
                                        status ??
                                            (a.anonymous
                                                ? 'Client chose to keep their camera off'
                                                : 'Waiting for ${a.clientName}’s video…'),
                                        textAlign: TextAlign.center,
                                        style: AppTypography.body(
                                          14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Self preview.
                          Positioned(
                            right: AppSizes.md,
                            top: AppSizes.md,
                            child: _SelfPreview(
                              name: me?.name ?? 'You',
                              cameraOn: _cameraOn,
                              video: _call.localView(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      AppSizes.xl,
                      AppSizes.lg,
                      AppSizes.xl,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        CallControlButton(
                          dark: true,
                          size: 56,
                          icon: _muted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          label: _muted ? 'Unmute' : 'Mute',
                          active: _muted,
                          onTap: _call.toggleMute,
                        ),
                        CallControlButton(
                          dark: true,
                          size: 56,
                          icon: _cameraOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          label: 'Camera',
                          active: !_cameraOn,
                          onTap: _call.toggleCamera,
                        ),
                        CallControlButton(
                          dark: true,
                          size: 56,
                          icon: _speaker
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          label: 'Speaker',
                          active: !_speaker,
                          onTap: _call.toggleSpeaker,
                        ),
                        CallControlButton(
                          dark: true,
                          danger: true,
                          size: 56,
                          icon: Icons.call_end_rounded,
                          label: 'End',
                          onTap: _end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelfPreview extends StatelessWidget {
  const _SelfPreview({required this.name, required this.cameraOn, this.video});

  final String name;
  final bool cameraOn;

  /// The live camera view, once the call has started.
  final Widget? video;

  @override
  Widget build(BuildContext context) {
    final Widget? live = video;
    if (cameraOn && live != null) {
      return Container(
        width: 100,
        height: 136,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(17), child: live),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 100,
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: cameraOn
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFB9A6FF), Color(0xFF7654F7)],
              )
            : null,
        color: cameraOn ? null : Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (cameraOn)
            MistyProfileAvatar(name: name, size: 54)
          else
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 28,
            ),
          const SizedBox(height: 6),
          Text(
            'You',
            style: AppTypography.body(
              12,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
