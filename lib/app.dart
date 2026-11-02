import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_routes.dart';
import 'state/providers.dart';
import 'state/realtime_bridge.dart';

/// The root widget. Light theme only, by design.
class MistyMindsPartnerApp extends ConsumerWidget {
  const MistyMindsPartnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Socket events and push notifications → the app.
    ref.watch(realtimeBridgeProvider);

    // Signed out from anywhere (logout, or a session that could no longer be
    // refreshed) → back to the welcome screen.
    ref.listen<bool>(authProvider, (bool? was, bool signedIn) {
      if (was == true && !signedIn) appRouter.go(AppRoutes.welcome);
    });

    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (BuildContext context, Widget? child) {
        // Respect the user's text size, but clamp the extremes so no screen
        // can overflow.
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.25,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
