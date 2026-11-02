import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The sounds around a Talk Now request: a ringtone that loops while the
/// request is on screen, and a short tone when it is accepted or declined.
///
/// Sound is a nicety, never a requirement — every call here swallows its own
/// failures (no audio device, a platform without the plugin, a test run), so
/// a request can always still be answered.
class RequestSounds {
  RequestSounds._();
  static final RequestSounds instance = RequestSounds._();

  /// Turned off in widget tests, where no audio plugin is registered.
  static bool enabled = true;

  static const String _ring = 'sounds/talk_request.wav';
  static const String _accept = 'sounds/talk_accept.wav';
  static const String _decline = 'sounds/talk_decline.wav';

  /// Rings like an incoming call: follows the phone's ring volume and briefly
  /// lowers other audio rather than stopping it.
  static final AudioContext _ringContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.notificationRingtone,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const <AVAudioSessionOptions>{AVAudioSessionOptions.duckOthers},
    ),
  );

  AudioPlayer? _ringer;

  bool get isRinging => _ringer != null;

  /// Starts the looping ringtone (once — a second call while ringing is a no-op).
  Future<void> startRinging() async {
    if (!enabled || _ringer != null) return;
    final AudioPlayer player = AudioPlayer();
    _ringer = player;
    try {
      unawaited(HapticFeedback.heavyImpact());
      await player.setAudioContext(_ringContext);
      await player.setReleaseMode(ReleaseMode.loop);
      // Stopped while this was still loading? Don't start late.
      if (_ringer != player) return;
      await player.play(AssetSource(_ring));
    } catch (e) {
      debugPrint('Talk Now ringtone unavailable: $e');
    }
  }

  /// Stops the ringtone, if it is playing.
  Future<void> stopRinging() async {
    final AudioPlayer? player = _ringer;
    _ringer = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {
      // Already gone.
    }
  }

  /// The short rising chime for "accepted".
  Future<void> playAccepted() => _playOnce(_accept);

  /// The short soft falling tone for "declined".
  Future<void> playDeclined() => _playOnce(_decline);

  Future<void> _playOnce(String asset) async {
    if (!enabled) return;
    final AudioPlayer player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.release);
      unawaited(
        player.onPlayerComplete.first
            .timeout(const Duration(seconds: 5))
            .then<void>((_) {}, onError: (Object _) {})
            .whenComplete(player.dispose),
      );
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Talk Now tone unavailable: $e');
      unawaited(player.dispose().catchError((Object _) {}));
    }
  }
}
