import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mistyminds_practitioner/app.dart';
import 'package:mistyminds_practitioner/core/constants/app_assets.dart';
import 'package:mistyminds_practitioner/core/widgets/misty_svg_icon.dart';
import 'package:mistyminds_practitioner/data/models/enums.dart';
import 'package:mistyminds_practitioner/data/models/talk_request.dart';
import 'support/mock_practitioner_repository.dart';
import 'package:mistyminds_practitioner/features/consultation/presentation/consultation_args.dart';
import 'support/mock/mock_talk_requests.dart';
import 'package:mistyminds_practitioner/data/audio/request_sounds.dart';
import 'package:mistyminds_practitioner/navigation/app_routes.dart';
import 'package:mistyminds_practitioner/state/providers.dart';

import 'support/preview_fonts.dart';

/// Renders every key screen at 390×844 and fails on any layout overflow.
///
/// Always runs as a smoke test. To also write review PNGs to `test/preview/`:
///   PREVIEW_SCREENS=1 flutter test --update-goldens test/screen_preview_test.dart
void main() {
  final bool capture = Platform.environment.containsKey('PREVIEW_SCREENS');
  final TalkRequest chatRequest = mockTalkRequests().first;
  const ConsultationArgs anonymousChat = ConsultationArgs(
    clientName: 'Anonymous Client',
    anonymous: true,
    mode: ConsultMode.chat,
    concern: 'Feeling overwhelmed',
    ratePerMinute: 20,
    isTalkNow: true,
  );

  final List<
    ({
      String name,
      String path,
      Object? extra,
      bool online,
      bool push,
      Size size,
    })
  >
  shots =
      <
        ({
          String name,
          String path,
          Object? extra,
          bool online,
          bool push,
          Size size,
        })
      >[
        for (final Size size in <Size>[
          const Size(390, 844),
          const Size(360, 690),
        ]) ...<
          ({
            String name,
            String path,
            Object? extra,
            bool online,
            bool push,
            Size size,
          })
        >[
          (
            name: 'welcome',
            path: AppRoutes.welcome,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'login',
            path: AppRoutes.login,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'apply',
            path: AppRoutes.apply,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'submitted',
            path: '${AppRoutes.applicationSubmitted}?ref=MM-PSY-2026-0412',
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'status',
            path: AppRoutes.verificationPending,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'home',
            path: AppRoutes.home,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'home_online',
            path: AppRoutes.home,
            extra: null,
            online: true,
            push: false,
            size: size,
          ),
          (
            name: 'calendar',
            path: AppRoutes.calendar,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'go_online',
            path: AppRoutes.goOnline,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'online',
            path: AppRoutes.onlineWaiting,
            extra: null,
            online: true,
            push: false,
            size: size,
          ),
          (
            name: 'request',
            path: AppRoutes.incomingRequest,
            extra: chatRequest,
            online: true,
            push: false,
            size: size,
          ),
          (
            name: 'chat',
            path: AppRoutes.chat,
            extra: anonymousChat,
            online: true,
            push: false,
            size: size,
          ),
          (
            name: 'audio',
            path: AppRoutes.audio,
            extra: anonymousChat,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'video',
            path: AppRoutes.video,
            extra: anonymousChat,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'complete',
            path: AppRoutes.sessionComplete,
            extra: const SessionSummary(
              args: anonymousChat,
              duration: Duration(minutes: 22),
            ),
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'sessions',
            path: AppRoutes.sessions,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'session_details',
            path: AppRoutes.sessionDetails('se_101'),
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'clients',
            path: AppRoutes.clients,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'client_details',
            path: AppRoutes.clientDetails('cl_01'),
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'earnings',
            path: AppRoutes.earnings,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'profile',
            path: AppRoutes.profile,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
          (
            name: 'notifications',
            path: AppRoutes.notifications,
            extra: null,
            online: false,
            push: false,
            size: size,
          ),
        ],
      ];

  setUpAll(() async {
    RequestSounds.enabled = false; // no audio plugin in widget tests
    await loadPreviewFonts();
    await MistySvgIcon.preload(AppAssets.allIcons);
  });

  for (final shot in shots) {
    final String tag = '${shot.name}_${shot.size.width.toInt()}';
    testWidgets('screen $tag renders without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = shot.size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      // Widget tests run on in-memory data, never the network or socket.
      final ProviderContainer container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(MockPractitionerRepository()),
          realtimeProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MistyMindsPartnerApp(),
        ),
      );
      // Let the splash finish.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 400));

      if (shot.online) container.read(presenceProvider.notifier).goOnline();
      appRouter.go(shot.path, extra: shot.extra);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.runAsync(() async {
        for (final Element e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);

      if (capture) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('preview/$tag.png'),
        );
      }

      // Tear down so screen timers (waiting, chat, call clocks) stop.
      container.read(presenceProvider.notifier).goOffline();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 30));
    });
  }
}
