import 'package:flutter/foundation.dart';

/// Build-time switches, set with `--dart-define`.
///
///   flutter run                                   → local backend on this machine
///   flutter build apk --release                   → the live backend ([productionBaseUrl])
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000
///                                                 → backend on your LAN (physical phone)
abstract final class AppConfig {
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const int _defaultPort = 5000;

  /// The live backend. A release build uses this unless API_BASE_URL says
  /// otherwise, so an APK built without the flag still reaches the server
  /// (it used to fall back to the emulator-only address 10.0.2.2).
  static const String productionBaseUrl = 'https://72-60-41-224.sslip.io';

  /// Where the Misty Minds backend lives. The Android emulator reaches the
  /// host machine at 10.0.2.2; desktop, web and iOS simulators use localhost.
  static String get apiBaseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride.endsWith('/')
          ? _baseUrlOverride.substring(0, _baseUrlOverride.length - 1)
          : _baseUrlOverride;
    }
    if (kReleaseMode) return productionBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_defaultPort';
    }
    return 'http://localhost:$_defaultPort';
  }

  /// Media the backend stores itself may come back as `/uploads/...` (when
  /// the server has no PUBLIC_BASE_URL); resolve it against the API.
  static String? resolveMedia(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('/')) return url;
    return '$apiBaseUrl$url';
  }
}
