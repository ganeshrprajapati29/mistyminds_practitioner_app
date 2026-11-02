import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api/token_store.dart';
import '../models/json.dart';

/// One event pushed by the backend over Socket.IO.
class RealtimeEvent {
  const RealtimeEvent(this.name, this.data);

  final String name;
  final Json data;
}

/// The practitioner app's live connection to the backend (Socket.IO).
///
/// Events the server sends to this psychologist (see backend
/// `realtime/socket.js` and `realtime/emitters.js`):
///
/// | event              | when                                          |
/// |--------------------|-----------------------------------------------|
/// | `talk:request`     | a client asks to talk now                     |
/// | `talk:resolved`    | a request was accepted / declined / expired   |
/// | `chat:message`     | a client sent a chat message                  |
/// | `session:ended`    | the client ended a session                    |
/// | `session:updated`  | the client cancelled a session                |
/// | `notification:new` | anything that also lands in Notifications     |
/// | `typing:start/stop`| the client is typing (conversation room)      |
class RealtimeService {
  RealtimeService({
    required this.baseUrl,
    required this.tokens,
    this.refreshSession,
  });

  final String baseUrl;
  final TokenStore tokens;

  /// Renews the access token (e.g. by making any authenticated API call),
  /// used when the server refuses a reconnect with an expired token.
  final Future<void> Function()? refreshSession;

  static const List<String> _events = <String>[
    'talk:request',
    'talk:resolved',
    'chat:message',
    'session:ended',
    'session:updated',
    'notification:new',
    'typing:start',
    'typing:stop',
  ];

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  io.Socket? _socket;
  bool _wanted = false;
  bool _refreshing = false;

  Stream<RealtimeEvent> get events => _controller.stream;

  Stream<RealtimeEvent> on(String name) =>
      events.where((RealtimeEvent e) => e.name == name);

  /// Opens (or re-opens) the connection with the current access token.
  void connect() {
    final String? token = tokens.accessToken;
    if (token == null) return;
    _wanted = true;
    _socket?.dispose();

    final io.Socket socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .setAuth(<String, dynamic>{'token': token})
          .enableReconnection()
          .setReconnectionDelay(1500)
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) => connected.value = true);
    socket.onDisconnect((_) => connected.value = false);
    socket.onConnectError((dynamic err) {
      connected.value = false;
      // The handshake token expired while the app was idle: refresh it and
      // reconnect with the new one.
      if ('$err'.contains('UNAUTHORIZED')) {
        unawaited(_reconnectWithFreshToken());
      }
    });

    for (final String name in _events) {
      socket.on(name, (dynamic data) {
        final Json json = data is Map
            ? data.cast<String, dynamic>()
            : <String, dynamic>{'value': data};
        _controller.add(RealtimeEvent(name, json));
      });
    }

    socket.connect();
    _socket = socket;
  }

  Future<void> _reconnectWithFreshToken() async {
    if (_refreshing || !_wanted || refreshSession == null) return;
    _refreshing = true;
    try {
      await refreshSession!();
      if (_wanted) connect();
    } catch (_) {
      // Signed out meanwhile; nothing to reconnect.
    } finally {
      _refreshing = false;
    }
  }

  void emit(String event, [Object? data]) => _socket?.emit(event, data);

  /// Joins a chat thread's room (to relay typing indicators).
  void joinConversation(String conversationId) =>
      emit('conversation:join', conversationId);

  void disconnect() {
    _wanted = false;
    _socket?.dispose();
    _socket = null;
    connected.value = false;
  }
}
