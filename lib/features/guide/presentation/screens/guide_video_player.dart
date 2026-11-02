import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../data/models/guide_video.dart';
import '../../../../state/providers.dart';

/// Plays one of the videos published from the admin console, full screen.
///
/// Shown two ways:
///  - straight after signing in (no [onClose]): it stays up until the video
///    has been watched — and, when the video is compulsory, there is no skip
///    and no seeking ahead;
///  - opened from a card on Home / Profile / Help ([onClose] set): an ordinary
///    player that can be closed and scrubbed freely.
class GuideVideoPlayer extends ConsumerStatefulWidget {
  const GuideVideoPlayer({super.key, required this.video, this.onClose});

  final GuideVideo video;

  /// Null for the screen shown after signing in, which can't be dismissed.
  final VoidCallback? onClose;

  @override
  ConsumerState<GuideVideoPlayer> createState() => _GuideVideoPlayerState();
}

class _GuideVideoPlayerState extends ConsumerState<GuideVideoPlayer>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _failed = false;
  bool _finished = false;
  bool _saving = false;

  bool get _afterLogin => widget.onClose == null;

  /// Compulsory and not yet watched through: no skip, no seeking ahead.
  bool get _locked => _afterLogin && widget.video.mandatory && !_finished;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  void _load() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
      ..addListener(_onTick);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.play();
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  void _retry() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    setState(() => _failed = false);
    _load();
  }

  void _onTick() {
    if (!mounted) return;
    final VideoPlayerValue v = _controller.value;
    if (v.hasError) _failed = true;
    final bool reachedEnd =
        v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 400);
    if (reachedEnd && !_finished) {
      _finished = true;
      unawaited(_saveWatched(completed: true));
    }
    setState(() {});
  }

  /// Records the viewing. After login, a saved viewing is what takes this
  /// screen away (see `pendingLoginVideoProvider`), so a failure is shown and
  /// can be retried with Continue; elsewhere it is saved quietly.
  Future<void> _saveWatched({required bool completed}) async {
    if (_saving || (widget.video.watched && !_afterLogin)) return;
    setState(() => _saving = true);
    Future<void> save() => ref
        .read(guideVideosProvider.notifier)
        .markWatched(widget.video.id, completed: completed);
    if (_afterLogin) {
      await AppFeedback.guard(context, save);
    } else {
      await save().catchError((Object _) {});
    }
    if (mounted) setState(() => _saving = false);
  }

  void _togglePlay() {
    final VideoPlayerValue v = _controller.value;
    if (!v.isInitialized) return;
    if (v.isPlaying) {
      _controller.pause();
    } else {
      if (v.position >= v.duration) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final VideoPlayerValue v = _controller.value;
    final TextStyle onDark = AppTypography.body(
      13,
      color: Colors.white.withValues(alpha: 0.82),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _TopBar(
                title: widget.video.title,
                onClose: widget.onClose,
                action: !_afterLogin
                    ? null
                    : widget.video.mandatory
                    ? (
                        'Log out',
                        () => AppFeedback.guard(
                          context,
                          () => ref.read(authProvider.notifier).logout(),
                        ),
                      )
                    : ('Skip', () => _saveWatched(completed: false)),
              ),
              Expanded(
                child: _failed
                    ? _PlaybackError(onRetry: _retry)
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _togglePlay,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            if (v.isInitialized)
                              Center(
                                child: AspectRatio(
                                  aspectRatio: v.aspectRatio,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            if (!v.isInitialized || v.isBuffering)
                              const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            else if (!v.isPlaying)
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _finished
                                      ? Icons.replay_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.sm,
                  AppSizes.screenPadding,
                  AppSizes.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (v.isInitialized && !_failed) ...<Widget>[
                      ClipRRect(
                        borderRadius: AppSizes.brPill,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: !_locked,
                          padding: EdgeInsets.zero,
                          colors: VideoProgressColors(
                            playedColor: AppColors.primary,
                            bufferedColor: Colors.white.withValues(alpha: 0.35),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: <Widget>[
                          Text(
                            '${_clock(v.position)} / ${_clock(v.duration)}',
                            style: onDark,
                          ),
                          const Spacer(),
                          if (_locked)
                            Text(
                              'Please watch the full video to continue',
                              style: onDark,
                            ),
                        ],
                      ),
                    ],
                    if (_afterLogin && _finished) ...<Widget>[
                      const SizedBox(height: AppSizes.lg),
                      MistyPrimaryButton(
                        label: 'Continue',
                        isLoading: _saving,
                        onPressed: () => _saveWatched(completed: true),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.onClose, this.action});

  final String title;
  final VoidCallback? onClose;

  /// A text button on the right: its label and what it does.
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        onClose == null ? AppSizes.screenPadding : AppSizes.xs,
        AppSizes.xs,
        AppSizes.xs,
        AppSizes.xs,
      ),
      child: Row(
        children: <Widget>[
          if (onClose != null)
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                16,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: action!.$2,
              child: Text(
                action!.$1,
                style: AppTypography.body(
                  14,
                  weight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _PlaybackError extends StatelessWidget {
  const _PlaybackError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 40),
            const SizedBox(height: AppSizes.md),
            Text(
              'We couldn’t play this video',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                16,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                13.5,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Try again',
                style: AppTypography.body(
                  15,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
