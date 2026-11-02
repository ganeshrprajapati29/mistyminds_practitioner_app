import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api_exception.dart';

/// "Continue with Google" for partners: shows Google's account picker and
/// returns an ID token for `POST /practitioner/auth/google`. The backend only
/// signs in an existing partner whose registered email matches.
///
/// The token is for the Firebase project's web OAuth client ([serverClientId]);
/// Android also needs this app's SHA-1 registered in Firebase (Project
/// settings → Your apps → in.mistyminds.partner).
class GoogleSignInClient {
  GoogleSignInClient._();
  static final GoogleSignInClient instance = GoogleSignInClient._();

  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '191814432924-11komn2g1i6jv8ctlbah0t0abtp5e4td.apps.googleusercontent.com',
  );

  Future<void>? _init;

  Future<void> _ensureInitialized() => _init ??= GoogleSignIn.instance
      .initialize(serverClientId: serverClientId);

  /// A Google ID token, or null if the picker was closed. Throws an
  /// [ApiException] with a readable message on real failures.
  Future<String?> idToken() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();
      final String? token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const ApiException(
          'GOOGLE_NO_TOKEN',
          'Google didn’t return your account details. Please try again.',
        );
      }
      return token;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      debugPrint('Google sign-in failed: ${e.code} ${e.description}');
      throw const ApiException(
        'GOOGLE_UNAVAILABLE',
        'Google sign-in isn’t available right now. Please use your email.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in with Google.
    }
  }
}
