import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/talk_request.dart';

/// Where a call is, from the psychologist's point of view.
enum CallPhase {
  /// Joining the channel.
  connecting,

  /// In the channel; the client hasn't joined yet.
  waitingForPeer,

  /// Both people are in the call.
  connected,

  /// The network dropped; Agora is trying to rejoin.
  reconnecting,

  /// The server has no Agora App ID yet — nothing to join.
  notConfigured,

  /// Microphone (or camera) permission was refused.
  permissionDenied,

  /// Joining failed.
  failed,

  /// The call is over.
  ended,
}

/// One Agora RTC call: joins the session's channel with the credentials the
/// backend minted, and exposes mute / camera / speaker controls and the
/// remote person's state for the call screens to render.
class AgoraCall extends ChangeNotifier {
  AgoraCall({required this.credentials, required this.video});

  final CallCredentials? credentials;
  final bool video;

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  CallPhase phase = CallPhase.connecting;
  bool peerJoined = false;
  bool peerVideoOn = false;
  bool muted = false;
  bool cameraOn = true;
  late bool speakerOn = video;
  String? error;

  bool _disposed = false;

  bool get isLive => _engine != null && phase != CallPhase.ended;

  void _set(void Function() change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  /// Asks for permissions, then joins the channel. Never throws: problems are
  /// reported through [phase] so the screen can explain them calmly.
  Future<void> start() async {
    final CallCredentials? c = credentials;
    if (c == null || !c.configured || (c.appId ?? '').isEmpty) {
      _set(() => phase = CallPhase.notConfigured);
      return;
    }

    final Map<Permission, PermissionStatus> granted = await <Permission>[
      Permission.microphone,
      if (video) Permission.camera,
    ].request();
    if (granted.values.any((PermissionStatus s) => !s.isGranted)) {
      _set(() => phase = CallPhase.permissionDenied);
      return;
    }

    try {
      final RtcEngine engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(
        RtcEngineContext(
          appId: c.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _set(
              () => phase = peerJoined
                  ? CallPhase.connected
                  : CallPhase.waitingForPeer,
            );
            unawaited(engine.setEnableSpeakerphone(speakerOn));
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (remoteUid != c.peerUid) return;
            _set(() {
              peerJoined = true;
              phase = CallPhase.connected;
            });
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                if (remoteUid != c.peerUid) return;
                _set(() {
                  peerJoined = false;
                  peerVideoOn = false;
                  phase = CallPhase.waitingForPeer;
                });
              },
          onRemoteVideoStateChanged:
              (
                RtcConnection connection,
                int remoteUid,
                RemoteVideoState state,
                RemoteVideoStateReason reason,
                int elapsed,
              ) {
                if (remoteUid != c.peerUid) return;
                _set(
                  () => peerVideoOn =
                      state == RemoteVideoState.remoteVideoStateDecoding ||
                      state == RemoteVideoState.remoteVideoStateStarting,
                );
              },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                if (state == ConnectionStateType.connectionStateReconnecting) {
                  _set(() => phase = CallPhase.reconnecting);
                } else if (state ==
                        ConnectionStateType.connectionStateConnected &&
                    phase == CallPhase.reconnecting) {
                  _set(
                    () => phase = peerJoined
                        ? CallPhase.connected
                        : CallPhase.waitingForPeer,
                  );
                } else if (state == ConnectionStateType.connectionStateFailed) {
                  _set(() {
                    phase = CallPhase.failed;
                    error =
                        'The call couldn’t connect. Please check your connection.';
                  });
                }
              },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora error $err: $msg');
          },
        ),
      );

      if (video) {
        await engine.enableVideo();
        await engine.startPreview();
      } else {
        await engine.disableVideo();
      }

      await engine.joinChannel(
        token: c.token ?? '',
        channelId: c.channel,
        uid: c.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: video,
          autoSubscribeAudio: true,
          autoSubscribeVideo: video,
        ),
      );
    } catch (e) {
      debugPrint('Agora join failed: $e');
      _set(() {
        phase = CallPhase.failed;
        error = 'The call couldn’t start. Please try again.';
      });
    }
  }

  Future<void> toggleMute() async {
    _set(() => muted = !muted);
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleCamera() async {
    _set(() => cameraOn = !cameraOn);
    await _engine?.muteLocalVideoStream(!cameraOn);
    await _engine?.enableLocalVideo(cameraOn);
  }

  Future<void> toggleSpeaker() async {
    _set(() => speakerOn = !speakerOn);
    await _engine?.setEnableSpeakerphone(speakerOn);
  }

  Future<void> switchCamera() async => _engine?.switchCamera();

  /// The psychologist's own camera.
  Widget? localView() {
    final RtcEngine? e = _engine;
    if (e == null || !video) return null;
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: e,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  /// The client's camera, once they've joined with it on.
  Widget? remoteView() {
    final RtcEngine? e = _engine;
    final CallCredentials? c = credentials;
    if (e == null || c == null || !video || !peerJoined || !peerVideoOn) {
      return null;
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: e,
        canvas: VideoCanvas(uid: c.peerUid),
        connection: RtcConnection(channelId: c.channel),
      ),
    );
  }

  Future<void> leave() async {
    final RtcEngine? e = _engine;
    _engine = null;
    _set(() => phase = CallPhase.ended);
    if (e == null) return;
    try {
      await e.leaveChannel();
      await e.release();
    } catch (_) {
      // Already gone.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(leave());
    super.dispose();
  }
}
