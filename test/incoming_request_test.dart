import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mistyminds_practitioner/app.dart';
import 'package:mistyminds_practitioner/core/constants/app_assets.dart';
import 'package:mistyminds_practitioner/core/constants/app_strings.dart';
import 'package:mistyminds_practitioner/core/widgets/misty_svg_icon.dart';
import 'package:mistyminds_practitioner/data/audio/request_sounds.dart';
import 'package:mistyminds_practitioner/data/models/enums.dart';
import 'package:mistyminds_practitioner/data/models/talk_request.dart';
import 'package:mistyminds_practitioner/features/consultation/presentation/consultation_args.dart';
import 'package:mistyminds_practitioner/features/talk_now/presentation/screens/incoming_request_screen.dart';
import 'package:mistyminds_practitioner/navigation/app_routes.dart';
import 'package:mistyminds_practitioner/state/providers.dart';
import 'package:mistyminds_practitioner/state/realtime_bridge.dart';

import 'support/mock/mock_talk_requests.dart';
import 'support/mock_practitioner_repository.dart';
import 'support/preview_fonts.dart';

/// A Talk Now request must be seen wherever the psychologist is.
///
/// Regression: the request screen used to live inside the Home tab, so a
/// request that arrived while a full-screen page was open — typically the
/// summary of the session that had just ended — opened *behind* it. Nothing
/// rang, nothing showed, and every later request was blocked as "already on
/// screen". (Seen live: chat and audio requests answered, then three video
/// requests in a row never reached the psychologist.)
void main() {
  const ConsultationArgs args = ConsultationArgs(
    clientName: 'Anonymous Client',
    anonymous: true,
    mode: ConsultMode.audio,
    concern: 'Feeling overwhelmed',
    ratePerMinute: 20,
    isTalkNow: true,
  );

  setUpAll(() async {
    RequestSounds.enabled = false; // no audio plugin in widget tests
    await loadPreviewFonts();
    await MistySvgIcon.preload(AppAssets.allIcons);
  });

  Future<ProviderContainer> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
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
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    // Not awaited: under the test clock it completes on the next pump.
    container.read(presenceProvider.notifier).goOnline();
    await tester.pump();
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> finish(WidgetTester tester, ProviderContainer container) async {
    activeTalkRequest.value = null;
    container.read(presenceProvider.notifier).goOffline();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('a request shows on top of the session summary', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await start(tester);
    final TalkRequest request = mockTalkRequests().first;

    appRouter.go(
      AppRoutes.sessionComplete,
      extra: const SessionSummary(
        args: args,
        duration: Duration(minutes: 12),
        creditedAmount: 400,
      ),
    );
    await settle(tester);
    expect(inLiveConsultation, isFalse);

    // What realtime_bridge does when the socket announces a request.
    appRouter.push<Object?>(AppRoutes.incomingRequest, extra: request);
    await settle(tester);

    expect(find.byType(IncomingRequestScreen), findsOneWidget);
    // Really visible and tappable — not buried under the summary.
    expect(find.text(AppStrings.acceptRequest).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await finish(tester, container);
  });

  testWidgets('a live consultation is not interrupted', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await start(tester);

    appRouter.go(AppRoutes.audio, extra: args);
    await settle(tester);

    expect(inLiveConsultation, isTrue);

    await finish(tester, container);
  });
}
