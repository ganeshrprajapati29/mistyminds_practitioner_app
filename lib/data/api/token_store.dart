import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in practitioner's token pair: held in memory for every request,
/// mirrored to the platform's secure storage so the session survives a
/// restart.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kAccess = 'mmp_access_token';
  static const String _kRefresh = 'mmp_refresh_token';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasSession => _refreshToken != null;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await Future.wait(<Future<void>>[
      _storage.write(key: _kAccess, value: accessToken),
      _storage.write(key: _kRefresh, value: refreshToken),
    ]);
  }

  /// Loads a remembered session. Returns false when there isn't one.
  Future<bool> load() async {
    try {
      _accessToken = await _storage.read(key: _kAccess);
      _refreshToken = await _storage.read(key: _kRefresh);
    } catch (_) {
      // A keystore that can't be read is treated as "signed out".
      _accessToken = null;
      _refreshToken = null;
    }
    return hasSession;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      await Future.wait(<Future<void>>[
        _storage.delete(key: _kAccess),
        _storage.delete(key: _kRefresh),
      ]);
    } catch (_) {
      // Nothing more to clear.
    }
  }
}
