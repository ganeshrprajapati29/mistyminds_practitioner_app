// Firebase configuration for MistyMinds: Practitioner — Firebase project `mistyminds`.
//
// Values come from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist. To switch project later, replace those
// files and update this one (or run
// `flutterfire configure --out=lib/core/config/firebase_options.dart`).
// Any value can still be overridden at build time with --dart-define, e.g.
// FIREBASE_PROJECT_ID / FIREBASE_ANDROID_APP_ID (useful for a staging project).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Push notifications are not set up for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Push notifications are not set up for $defaultTargetPlatform.',
        );
    }
  }

  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'mistyminds',
  );
  static const String _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '191814432924',
  );
  static const String _storageBucket = 'mistyminds.firebasestorage.app';

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'AIzaSyB9Mx1LuVQhetrOu8I46os4ZRFFANMeA8A',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
      defaultValue: '1:191814432924:android:c4dcc7fe4cd82d4cb85559',
    ),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'AIzaSyD2AVrf91flni94KKRe_y40oujhCs9M6sg',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_IOS_APP_ID',
      defaultValue: '1:191814432924:ios:89837c7271194a1db85559',
    ),
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'in.mistyminds.partner',
  );
}
