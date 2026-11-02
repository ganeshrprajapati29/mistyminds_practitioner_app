import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_assets.dart';
import 'core/widgets/misty_svg_icon.dart';
import 'data/push/push_service.dart';

/// MistyMinds: Practitioner — the app psychologists use to set availability, go
/// online for Talk Now, run sessions and track earnings.
///
/// Backed by the MistyMinds API: live Talk Now requests and chat over
/// Socket.IO, calls over Agora and push notifications over Firebase.
Future<void> main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash up until the brand icons are ready, so the first
  // Flutter frame is complete.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await MistySvgIcon.preload(AppAssets.allIcons);

  // Push notifications: on only once Firebase is configured
  // (lib/core/config/firebase_options.dart); the app runs fine without.
  if (await PushService.initializeFirebase()) {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await PushService.instance.start();
  }

  runApp(const ProviderScope(child: MistyMindsPartnerApp()));
  FlutterNativeSplash.remove();
}
