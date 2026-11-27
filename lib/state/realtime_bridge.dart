import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/talk_request.dart';
import '../data/push/push_service.dart';
import '../data/realtime/realtime_service.dart';
import '../navigation/app_routes.dart';
import 'providers.dart';

/// The id of the Talk Now request currently on screen, if any — so the same
/// request is never shown twice (socket, push and polling can all announce it).
final ValueNotifier<String?> activeTalkRequest = ValueNotifier<String?>(null);

/// Opens the incoming-request screen for [request] when the psychologist is
/// online and accepting — wherever they are in the app.
Future<void> presentTalkRequest(Ref ref, TalkRequest request) async {
  final PresenceState presence = ref.read(presenceProvider);
  if (!ref.read(authProvider) ||
      !presence.isOnline ||
      !presence.acceptTalkNow) {
    return;
  }
  // Busy with a client: let this one pass (it expires and the client is
  // refunded) rather than ring over a live session.
  if (inLiveConsultation) return;
  if (activeTalkRequest.value != null) return;
  activeTalkRequest.value = request.id;
  try {
    await appRouter.push<Object?>(AppRoutes.incomingRequest, extra: request);
  } finally {
    if (activeTalkRequest.value == request.id) activeTalkRequest.value = null;
  }
}

/// Wires live events into the app: Socket.IO events from the backend and
/// Firebase pushes. Watched once by the root widget, so it lives as long as
/// the app does.
final Provider<void> realtimeBridgeProvider = Provider<void>((Ref ref) {
  final List<StreamSubscription<Object?>> subs =
      <StreamSubscription<Object?>>[];
  ref.onDispose(() {
    for (final StreamSubscription<Object?> s in subs) {
      unawaited(s.cancel());
    }
  });

  void refreshSessions() {
    unawaited(
      ref.read(sessionsProvider.notifier).reload().catchError((Object _) {}),
    );
  }

  /// Asks the server for the waiting request (used when only a push or a
  /// notification told us about it) and shows it.
  Future<void> fetchAndPresentRequest() async {
    try {
      final TalkRequest? next = await ref
          .read(repositoryProvider)
          .nextTalkRequest();
      if (next != null) await presentTalkRequest(ref, next);
    } catch (_) {
      // The waiting screen's polling will pick it up.
    }
  }

  // ---- Socket.IO ------------------------------------------------------------
  final RealtimeService? realtime = ref.read(realtimeProvider);
  if (realtime != null) {
    subs.add(
      realtime.events.listen((RealtimeEvent e) {
        switch (e.name) {
          case 'talk:request':
            unawaited(presentTalkRequest(ref, TalkRequest.fromJson(e.data)));
          case 'notification:new':
            ref.invalidate(notificationsProvider);
          case 'session:ended':
          case 'session:updated':
            refreshSessions();
          // The 2-hour online window ended, or an admin set them offline.
          case 'presence:updated':
          case 'presence:forced':
            unawaited(ref.read(presenceProvider.notifier).refresh());
        }
      }),
    );
  }

  // ---- Firebase pushes ------------------------------------------------------
  final PushService push = PushService.instance;
  subs.add(
    push.foregroundMessages.listen((Map<String, String> data) {
      ref.invalidate(notificationsProvider);
      if (data['kind'] == 'talkRequest') unawaited(fetchAndPresentRequest());
    }),
  );
  subs.add(
    push.taps.listen((Map<String, String> data) {
      if (!ref.read(authProvider)) return; // sign in first; the splash routes
      ref.invalidate(notificationsProvider);
      switch (data['kind']) {
        case 'talkRequest':
          unawaited(fetchAndPresentRequest());
        case 'sessionBooked':
        case 'sessionReminder':
          final String? id = data['sessionId'];
          appRouter.go(
            id == null ? AppRoutes.sessions : AppRoutes.sessionDetails(id),
          );
        case 'paymentReceived':
          appRouter.go(AppRoutes.earnings);
        default:
          appRouter.go(AppRoutes.notifications);
      }
    }),
  );
});
