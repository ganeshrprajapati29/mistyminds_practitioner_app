import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/config/firebase_options.dart';

/// Runs in its own isolate when a push arrives while the app is in the
/// background. Notification pushes are shown by the system itself, so there
/// is nothing to do here beyond making sure Firebase is up.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await PushService.initializeFirebase();
}

/// Firebase Cloud Messaging for the practitioner app: registers this device
/// with the backend, shows pushes that arrive while the app is open, and
/// reports taps so the app can open the right screen.
///
/// Everything is a no-op until Firebase is configured
/// (lib/core/config/firebase_options.dart), so the app never depends on it.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static bool _firebaseReady = false;
  static bool get isAvailable => _firebaseReady;

  /// Android notification channels, matching the backend's `channelId`s.
  static const AndroidNotificationChannel talkChannel =
      AndroidNotificationChannel(
        'misty_talk_now',
        'Talk Now requests',
        description: 'A client is asking to talk right now.',
        importance: Importance.max,
      );
  /// Talk Now requests that arrive while the app is closed or in the
  /// background ring with the app's own ringtone (res/raw/talk_request.wav).
  /// A channel's sound can't be changed once it exists, hence a new id; the
  /// older [talkChannel] stays for servers that still send to it.
  static const AndroidNotificationChannel talkRingChannel =
      AndroidNotificationChannel(
        'misty_talk_ring',
        'Talk Now requests',
        description: 'A client is asking to talk right now.',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('talk_request'),
      );
  static const AndroidNotificationChannel generalChannel =
      AndroidNotificationChannel(
        'misty_general',
        'Sessions & updates',
        description: 'Bookings, reminders and payments.',
        importance: Importance.high,
      );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, String>> _taps =
      StreamController<Map<String, String>>.broadcast();
  final StreamController<Map<String, String>> _foreground =
      StreamController<Map<String, String>>.broadcast();
  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];
  String? _token;

  /// Push data of notifications the user tapped (app opened from a push).
  Stream<Map<String, String>> get taps => _taps.stream;

  /// Push data that arrived while the app was in the foreground.
  Stream<Map<String, String>> get foregroundMessages => _foreground.stream;

  String? get token => _token;

  /// Called once from main(). Returns false (push off) when Firebase isn't
  /// configured yet — never throws.
  static Future<bool> initializeFirebase() async {
    if (_firebaseReady) return true;
    try {
      final FirebaseOptions options = DefaultFirebaseOptions.currentPlatform;
      if (options.apiKey.isEmpty || options.appId.isEmpty) return false;
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase not initialised (push notifications off): $e');
    }
    return _firebaseReady;
  }

  /// Sets up notification channels and listeners. Call once after
  /// [initializeFirebase] succeeded.
  Future<void> start() async {
    if (!_firebaseReady || _subs.isNotEmpty) return;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        final String? payload = r.payload;
        if (payload == null || payload.isEmpty) return;
        _taps.add(
          Map<String, String>.from(
            jsonDecode(payload) as Map<dynamic, dynamic>,
          ),
        );
      },
    );
    final AndroidFlutterLocalNotificationsPlugin? android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(talkChannel);
    await android?.createNotificationChannel(talkRingChannel);
    await android?.createNotificationChannel(generalChannel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    _subs.add(FirebaseMessaging.onMessage.listen(_showForeground));
    _subs.add(
      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage m) => _taps.add(_data(m)),
      ),
    );
    final RemoteMessage? launch = await FirebaseMessaging.instance
        .getInitialMessage();
    if (launch != null) {
      // Let the router finish its first frame before navigating.
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        () => _taps.add(_data(launch)),
      );
    }
  }

  /// Asks for permission (Android 13+ / iOS) and returns this device's FCM
  /// token, or null if push is unavailable or refused.
  Future<String?> requestToken() async {
    if (!_firebaseReady) return null;
    try {
      final NotificationSettings s = await FirebaseMessaging.instance
          .requestPermission();
      if (s.authorizationStatus == AuthorizationStatus.denied) return null;
      _token = await FirebaseMessaging.instance.getToken();
      return _token;
    } catch (e) {
      debugPrint('Could not get an FCM token: $e');
      return null;
    }
  }

  Future<void> Function(String token)? _register;
  StreamSubscription<String>? _refreshSub;

  /// Keeps the backend up to date when Firebase rotates the token. Calling
  /// it again (next sign-in) replaces the callback; there is one listener.
  void onTokenRefresh(Future<void> Function(String token) register) {
    if (!_firebaseReady) return;
    _register = register;
    _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
      String t,
    ) {
      _token = t;
      final Future<void> Function(String token)? callback = _register;
      if (callback != null) unawaited(callback(t).catchError((Object _) {}));
    });
  }

  Map<String, String> _data(RemoteMessage m) =>
      m.data.map((String k, dynamic v) => MapEntry<String, String>(k, '$v'));

  Future<void> _showForeground(RemoteMessage m) async {
    final Map<String, String> data = _data(m);
    _foreground.add(data);
    final RemoteNotification? n = m.notification;
    if (n == null) return;
    final bool talk = data['kind'] == 'talkRequest';
    // With the app open, a Talk Now request opens its own full screen and
    // rings there (state/realtime_bridge.dart) — a banner with a second
    // ringtone on top would only be noise.
    if (talk) return;
    const AndroidNotificationChannel channel = generalChannel;
    await _local.show(
      id: m.hashCode,
      title: n.title,
      body: n.body,
      payload: jsonEncode(data),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> deleteToken() async {
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Offline — the backend drops dead tokens by itself on the next push.
    }
    _token = null;
  }
}
