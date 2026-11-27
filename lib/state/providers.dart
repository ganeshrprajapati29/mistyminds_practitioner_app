import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/utils/formatters.dart';
import '../data/api/api_client.dart';
import '../data/api/token_store.dart';
import '../data/auth/google_sign_in_client.dart';
import '../data/models/app_notification.dart';
import '../data/models/availability.dart';
import '../data/models/client.dart';
import '../data/models/enums.dart';
import '../data/models/guide_video.dart';
import '../data/models/psychologist.dart';
import '../data/models/session.dart';
import '../data/models/settings.dart';
import '../data/models/transaction.dart';
import '../data/repositories/api_practitioner_repository.dart';
import '../data/repositories/practitioner_repository.dart';
import '../data/push/push_service.dart';
import '../data/realtime/realtime_service.dart';

/// Everything goes through the real backend (tests override this).
final Provider<PractitionerRepository> repositoryProvider =
    Provider<PractitionerRepository>((Ref ref) {
      return ApiPractitionerRepository(
        ref.watch(apiClientProvider),
        ref.watch(tokenStoreProvider),
      );
    });

/// The signed-in practitioner's tokens — shared by HTTP and the socket.
final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>(
  (Ref ref) => TokenStore(),
);

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  final ApiClient client = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokens: ref.watch(tokenStoreProvider),
  );
  // A session that can no longer be refreshed sends the user back to sign in.
  client.onSessionExpired = () =>
      ref.read(authProvider.notifier).sessionExpired();
  return client;
});

/// The live Socket.IO connection (null in widget tests, via an override).
final Provider<RealtimeService?> realtimeProvider = Provider<RealtimeService?>((
  Ref ref,
) {
  final RealtimeService service = RealtimeService(
    baseUrl: AppConfig.apiBaseUrl,
    tokens: ref.watch(tokenStoreProvider),
    // Any authenticated call refreshes an expired access token.
    refreshSession: () => ref.read(repositoryProvider).fetchPresence(),
  );
  ref.onDispose(service.disconnect);
  return service;
});

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

class AuthController extends Notifier<bool> {
  @override
  bool build() => false;

  PractitionerRepository get _repo => ref.read(repositoryProvider);

  /// Restores a remembered session at start-up. Never throws.
  Future<bool> restore() async {
    try {
      final bool signedIn = await _repo.restoreSession();
      if (signedIn) _onSignedIn();
      return signedIn;
    } catch (_) {
      return false;
    }
  }

  Future<void> login(String identifier, String password) async {
    await _repo.login(identifier: identifier, password: password);
    _onSignedIn();
  }

  /// "Continue with Google". Returns false when the picker was closed
  /// (nothing to show); throws [ApiException] on a real failure.
  Future<bool> loginWithGoogle() async {
    final String? idToken = await GoogleSignInClient.instance.idToken();
    if (idToken == null) return false;
    await _repo.loginWithGoogle(idToken);
    _onSignedIn();
    return true;
  }

  Future<void> logout() async {
    try {
      await ref.read(presenceProvider.notifier).goOffline();
    } catch (_) {
      // Signing out must still work offline.
    }
    // This device should stop receiving this account's pushes.
    final String? token = PushService.instance.token;
    if (token != null) {
      await _repo.unregisterDevice(token).catchError((Object _) {});
    }
    ref.read(realtimeProvider)?.disconnect();
    await _repo.logout();
    await GoogleSignInClient.instance.signOut();
    state = false;
  }

  void sessionExpired() {
    if (state) state = false;
  }

  /// Every per-account provider starts fresh for the new session.
  void _onSignedIn() {
    ref
      ..invalidate(profileProvider)
      ..invalidate(sessionsProvider)
      ..invalidate(clientsProvider)
      ..invalidate(earningsSummaryProvider)
      ..invalidate(transactionsProvider)
      ..invalidate(notificationsProvider)
      ..invalidate(availabilityProvider)
      ..invalidate(settingsProvider)
      ..invalidate(guideVideosProvider);
    state = true;
    unawaited(ref.read(presenceProvider.notifier).refresh());
    ref.read(realtimeProvider)?.connect();
    unawaited(_registerForPush());
  }

  /// Registers this device's FCM token with the backend (and again whenever
  /// Firebase rotates it). Silently skipped while Firebase isn't configured.
  /// Registers again (e.g. after notifications were turned on, or when the
  /// app returns to the foreground). Returns true if a token was registered.
  Future<bool> retryPushRegistration() async {
    if (!state) return false;
    await _registerForPush();
    return PushService.instance.token != null &&
        PushService.instance.lastProblem == null;
  }

  Future<void> _registerForPush() async {
    final PushService push = PushService.instance;
    if (!PushService.isAvailable) return;
    final String platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    Future<void> register(String token) =>
        _repo.registerDevice(token, platform: platform);
    final String? token = await push.requestToken();
    if (token != null) await register(token).catchError((Object _) {});
    push.onTokenRefresh(register);
  }
}

final NotifierProvider<AuthController, bool> authProvider =
    NotifierProvider<AuthController, bool>(AuthController.new);

// ---------------------------------------------------------------------------
// Profile & settings
// ---------------------------------------------------------------------------

class ProfileController extends AsyncNotifier<Psychologist> {
  @override
  Future<Psychologist> build() => ref.read(repositoryProvider).fetchProfile();

  Future<void> save(Psychologist updated) async {
    state = AsyncData<Psychologist>(
      await ref.read(repositoryProvider).updateProfile(updated),
    );
  }

  /// New profile photo (shown to clients on the listing).
  Future<void> uploadPhoto(List<int> bytes, String fileName) async {
    state = AsyncData<Psychologist>(
      await ref.read(repositoryProvider).uploadPhoto(bytes, fileName),
    );
  }

  /// A verification document; it then shows as "under review".
  Future<void> uploadDocument(
    String documentName,
    List<int> bytes,
    String fileName,
  ) async {
    state = AsyncData<Psychologist>(
      await ref
          .read(repositoryProvider)
          .uploadDocument(documentName, bytes, fileName),
    );
  }
}

final AsyncNotifierProvider<ProfileController, Psychologist> profileProvider =
    AsyncNotifierProvider<ProfileController, Psychologist>(
      ProfileController.new,
    );

class SettingsController extends AsyncNotifier<PractitionerSettings> {
  @override
  Future<PractitionerSettings> build() =>
      ref.read(repositoryProvider).fetchSettings();

  PractitionerSettings get _current =>
      state.valueOrNull ?? PractitionerSettings.defaults;

  /// Applies a change straight away, then saves it; reverts if saving fails.
  Future<void> change(
    PractitionerSettings Function(PractitionerSettings) edit,
  ) async {
    final PractitionerSettings before = _current;
    final PractitionerSettings next = edit(before);
    state = AsyncData<PractitionerSettings>(next);
    try {
      state = AsyncData<PractitionerSettings>(
        await ref.read(repositoryProvider).saveSettings(next),
      );
    } catch (_) {
      state = AsyncData<PractitionerSettings>(before);
      rethrow;
    }
  }

  Future<void> setNotification(String key, bool value) => change(
    (PractitionerSettings s) => s.copyWith(
      notifications: <String, bool>{...s.notifications, key: value},
    ),
  );

  Future<void> setPrivacy(String key, bool value) => change(
    (PractitionerSettings s) =>
        s.copyWith(privacy: <String, bool>{...s.privacy, key: value}),
  );

  Future<void> setAvailabilityPreferences(Map<String, Object> values) => change(
    (PractitionerSettings s) => s.copyWith(
      availability: <String, Object>{...s.availability, ...values},
    ),
  );
}

final AsyncNotifierProvider<SettingsController, PractitionerSettings>
settingsProvider =
    AsyncNotifierProvider<SettingsController, PractitionerSettings>(
      SettingsController.new,
    );

// ---------------------------------------------------------------------------
// Sessions
// ---------------------------------------------------------------------------

class SessionsController extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() => ref.read(repositoryProvider).fetchSessions();

  PractitionerRepository get _repo => ref.read(repositoryProvider);

  /// Re-reads the schedule, and everything derived from it, from the server.
  Future<void> reload() async {
    state = AsyncData<List<Session>>(await _repo.fetchSessions());
    ref
      ..invalidate(clientsProvider)
      ..invalidate(earningsSummaryProvider)
      ..invalidate(transactionsProvider)
      ..invalidate(availabilityProvider);
  }

  Future<void> cancel(String id, String reason) async {
    await _repo.cancelSession(id, reason);
    await reload();
  }

  Future<void> requestReschedule(String id) async {
    await _repo.requestReschedule(id);
    await reload();
  }

  Future<void> saveNotes(String id, String notes) async {
    await _repo.saveSessionNotes(id, notes);
    final List<Session> current = state.valueOrNull ?? const <Session>[];
    state = AsyncData<List<Session>>(<Session>[
      for (final Session s in current)
        s.id == id ? s.copyWith(notes: notes) : s,
    ]);
  }

  /// Ends a live session and returns what the psychologist earned.
  Future<double> complete(
    String id, {
    required Duration duration,
    String? privateNote,
  }) async {
    final double earned = await _repo.completeSession(
      id,
      duration: duration,
      privateNote: privateNote,
    );
    unawaited(reload().catchError((Object _) {}));
    return earned;
  }
}

final AsyncNotifierProvider<SessionsController, List<Session>>
sessionsProvider = AsyncNotifierProvider<SessionsController, List<Session>>(
  SessionsController.new,
);

List<Session> _sessions(Ref ref) =>
    ref.watch(sessionsProvider).valueOrNull ?? const <Session>[];

/// Sessions with [status], soonest-first for upcoming and newest-first
/// otherwise.
final ProviderFamily<List<Session>, SessionStatus> sessionsByStatusProvider =
    Provider.family<List<Session>, SessionStatus>((
      Ref ref,
      SessionStatus status,
    ) {
      final List<Session> list =
          _sessions(ref).where((Session s) => s.status == status).toList()
            ..sort((Session a, Session b) => a.start.compareTo(b.start));
      return status == SessionStatus.upcoming ? list : list.reversed.toList();
    });

final Provider<List<Session>> todaysSessionsProvider = Provider<List<Session>>((
  Ref ref,
) {
  final DateTime now = DateTime.now();
  return ref
      .watch(sessionsByStatusProvider(SessionStatus.upcoming))
      .where((Session s) => Fmt.sameDay(s.start, now))
      .toList();
});

final ProviderFamily<Session?, String> sessionByIdProvider =
    Provider.family<Session?, String>((Ref ref, String id) {
      for (final Session s in _sessions(ref)) {
        if (s.id == id) return s;
      }
      return null;
    });

final ProviderFamily<List<Session>, String> sessionsForClientProvider =
    Provider.family<List<Session>, String>(
      (Ref ref, String clientId) =>
          _sessions(ref).where((Session s) => s.clientId == clientId).toList()
            ..sort((Session a, Session b) => b.start.compareTo(a.start)),
    );

// ---------------------------------------------------------------------------
// Clients & earnings (read-only)
// ---------------------------------------------------------------------------

final FutureProvider<List<Client>> clientsProvider =
    FutureProvider<List<Client>>(
      (Ref ref) => ref.read(repositoryProvider).fetchClients(),
    );

final ProviderFamily<Client?, String> clientByIdProvider =
    Provider.family<Client?, String>((Ref ref, String id) {
      for (final Client c
          in ref.watch(clientsProvider).valueOrNull ?? const <Client>[]) {
        if (c.id == id) return c;
      }
      return null;
    });

final FutureProvider<EarningsSummary> earningsSummaryProvider =
    FutureProvider<EarningsSummary>(
      (Ref ref) => ref.read(repositoryProvider).fetchEarningsSummary(),
    );

final FutureProvider<List<EarningTransaction>> transactionsProvider =
    FutureProvider<List<EarningTransaction>>(
      (Ref ref) => ref.read(repositoryProvider).fetchTransactions(),
    );

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.read(repositoryProvider).fetchNotifications();

  void markRead(String id) {
    state = AsyncData<List<AppNotification>>(<AppNotification>[
      for (final AppNotification n
          in state.valueOrNull ?? const <AppNotification>[])
        n.id == id ? n.markRead() : n,
    ]);
    unawaited(
      ref
          .read(repositoryProvider)
          .markNotificationsRead(<String>[id])
          .catchError((Object _) {}),
    );
  }

  void markAllRead() {
    final List<AppNotification> all =
        state.valueOrNull ?? const <AppNotification>[];
    state = AsyncData<List<AppNotification>>(
      all.map((AppNotification n) => n.markRead()).toList(),
    );
    unawaited(
      ref
          .read(repositoryProvider)
          .markAllNotificationsRead()
          .catchError((Object _) {}),
    );
  }
}

final AsyncNotifierProvider<NotificationsController, List<AppNotification>>
notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

final Provider<int> unreadNotificationsProvider = Provider<int>(
  (Ref ref) =>
      (ref.watch(notificationsProvider).valueOrNull ??
              const <AppNotification>[])
          .where((AppNotification n) => !n.read)
          .length,
);

// ---------------------------------------------------------------------------
// Videos (published from the admin console)
// ---------------------------------------------------------------------------

class GuideVideosController extends AsyncNotifier<List<GuideVideo>> {
  @override
  Future<List<GuideVideo>> build() =>
      ref.read(repositoryProvider).fetchGuideVideos();

  /// Tells the server the video was seen ([completed] is false for a skipped
  /// optional video), then shows it as watched everywhere.
  Future<void> markWatched(String id, {bool completed = true}) async {
    final GuideVideo updated = await ref
        .read(repositoryProvider)
        .markGuideVideoWatched(id, completed: completed);
    state = AsyncData<List<GuideVideo>>(<GuideVideo>[
      for (final GuideVideo v in state.valueOrNull ?? const <GuideVideo>[])
        v.id == id ? updated : v,
    ]);
  }
}

final AsyncNotifierProvider<GuideVideosController, List<GuideVideo>>
guideVideosProvider =
    AsyncNotifierProvider<GuideVideosController, List<GuideVideo>>(
      GuideVideosController.new,
    );

/// The videos to show in one place, in the order the admin console set.
final ProviderFamily<List<GuideVideo>, VideoPlacement>
videosForPlacementProvider = Provider.family<List<GuideVideo>, VideoPlacement>(
  (Ref ref, VideoPlacement placement) =>
      (ref.watch(guideVideosProvider).valueOrNull ?? const <GuideVideo>[])
          .where((GuideVideo v) => v.placements.contains(placement))
          .toList(),
);

/// The next video to show full screen after signing in, or null when there is
/// nothing left to watch.
final Provider<GuideVideo?> pendingLoginVideoProvider = Provider<GuideVideo?>((
  Ref ref,
) {
  for (final GuideVideo v in ref.watch(
    videosForPlacementProvider(VideoPlacement.afterLogin),
  )) {
    if (!v.watched) return v;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Availability
// ---------------------------------------------------------------------------

typedef AvailabilityMap = Map<DateTime, List<AvailabilitySlot>>;

class AvailabilityController extends AsyncNotifier<AvailabilityMap> {
  int _seq = 100;

  @override
  Future<AvailabilityMap> build() =>
      ref.read(repositoryProvider).fetchAvailability();

  AvailabilityMap get _current =>
      state.valueOrNull ?? <DateTime, List<AvailabilitySlot>>{};

  List<AvailabilitySlot> slotsFor(DateTime day) =>
      _current[Fmt.dateOnly(day)] ?? const <AvailabilitySlot>[];

  /// Adds or replaces a slot. Returns an error message instead of saving when
  /// the slot is invalid or overlaps another one that day.
  String? upsert(DateTime day, AvailabilitySlot slot) {
    if (!slot.isValid) return 'End time must be after start time.';
    final DateTime key = Fmt.dateOnly(day);
    final List<AvailabilitySlot> list = List<AvailabilitySlot>.of(
      _current[key] ?? const <AvailabilitySlot>[],
    );
    final bool clash = list.any(
      (AvailabilitySlot s) => s.id != slot.id && s.overlaps(slot),
    );
    if (clash) return 'This overlaps another slot on the same day.';
    final int i = list.indexWhere((AvailabilitySlot s) => s.id == slot.id);
    if (i >= 0) {
      list[i] = slot;
    } else {
      list.add(slot);
    }
    list.sort(
      (AvailabilitySlot a, AvailabilitySlot b) =>
          (a.start.hour * 60 + a.start.minute) -
          (b.start.hour * 60 + b.start.minute),
    );
    state = AsyncData<AvailabilityMap>(<DateTime, List<AvailabilitySlot>>{
      ..._current,
      key: list,
    });
    return null;
  }

  String newId() => 'av_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  void remove(DateTime day, String slotId) {
    final DateTime key = Fmt.dateOnly(day);
    final List<AvailabilitySlot> list =
        (_current[key] ?? const <AvailabilitySlot>[])
            .where((AvailabilitySlot s) => s.id != slotId)
            .toList();
    final AvailabilityMap next = <DateTime, List<AvailabilitySlot>>{
      ..._current,
    };
    if (list.isEmpty) {
      next.remove(key);
    } else {
      next[key] = list;
    }
    state = AsyncData<AvailabilityMap>(next);
  }

  /// Days from today on with some time set but less than the two-hour minimum.
  List<DateTime> daysBelowMinimum() {
    final DateTime today = Fmt.dateOnly(DateTime.now());
    return <DateTime>[
      for (final MapEntry<DateTime, List<AvailabilitySlot>> e
          in _current.entries)
        if (!e.key.isBefore(today) &&
            e.value.fold<int>(
                  0,
                  (int sum, AvailabilitySlot s) => sum + s.duration.inMinutes,
                ) <
                120)
          e.key,
    ]..sort();
  }

  /// Saves every date from today on. The server's copy (with booked minutes)
  /// replaces the local one.
  Future<void> save() async {
    final DateTime today = Fmt.dateOnly(DateTime.now());
    final AvailabilityMap upcoming = <DateTime, List<AvailabilitySlot>>{
      for (final MapEntry<DateTime, List<AvailabilitySlot>> e
          in _current.entries)
        if (!e.key.isBefore(today)) e.key: e.value,
    };
    state = AsyncData<AvailabilityMap>(
      await ref.read(repositoryProvider).saveAvailability(upcoming),
    );
    unawaited(ref.read(presenceProvider.notifier).refresh());
  }
}

final AsyncNotifierProvider<AvailabilityController, AvailabilityMap>
availabilityProvider =
    AsyncNotifierProvider<AvailabilityController, AvailabilityMap>(
      AvailabilityController.new,
    );

// ---------------------------------------------------------------------------
// Presence (Talk Now)
// ---------------------------------------------------------------------------

@immutable
class PresenceState {
  const PresenceState({
    required this.status,
    required this.acceptTalkNow,
    required this.window,
  });

  final PresenceStatus status;
  final bool acceptTalkNow;
  final TalkWindow window;

  bool get isOnline => status == PresenceStatus.online;
  bool get isLive => status != PresenceStatus.offline;

  PresenceState copyWith({
    PresenceStatus? status,
    bool? acceptTalkNow,
    TalkWindow? window,
  }) => PresenceState(
    status: status ?? this.status,
    acceptTalkNow: acceptTalkNow ?? this.acceptTalkNow,
    window: window ?? this.window,
  );
}

/// Mirrors the server's view of the psychologist's Talk Now presence. Every
/// change is sent to the server first; the window's countdown then ticks
/// locally once a minute.
class PresenceController extends Notifier<PresenceState> {
  Timer? _ticker;

  @override
  PresenceState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const PresenceState(
      status: PresenceStatus.offline,
      acceptTalkNow: true,
      // Placeholder until the server's presence arrives (fetched on start).
      window: TalkWindow(
        start: TimeOfDay(hour: 18, minute: 0),
        end: TimeOfDay(hour: 20, minute: 0),
        remaining: Duration.zero,
      ),
    );
  }

  PractitionerRepository get _repo => ref.read(repositoryProvider);

  void _apply(PresenceSnapshot s) {
    state = PresenceState(
      status: s.status,
      acceptTalkNow: s.acceptTalkNow,
      window: s.window,
    );
    if (s.status != PresenceStatus.offline) {
      _startTicker();
    } else {
      _ticker?.cancel();
    }
  }

  /// Picks up the server's state (e.g. still online from a previous launch).
  Future<void> refresh() async {
    try {
      _apply(await _repo.fetchPresence());
    } catch (_) {
      // Keep what we have; the next action will retry.
    }
  }

  Future<void> goOnline() async =>
      _apply(await _repo.setPresence(status: PresenceStatus.online));

  Future<void> pause() async =>
      _apply(await _repo.setPresence(status: PresenceStatus.paused));

  Future<void> resume() => goOnline();

  /// Going offline (or pausing) is refused by the server while the 2-hour
  /// online window is running — the error message says until when; the
  /// screen then stays as the server has it.
  Future<void> goOffline() async {
    try {
      _apply(await _repo.setPresence(status: PresenceStatus.offline));
    } catch (_) {
      await refresh();
      rethrow;
    }
  }

  Future<void> setAcceptTalkNow(bool value) async {
    final bool before = state.acceptTalkNow;
    state = state.copyWith(acceptTalkNow: value);
    try {
      _apply(await _repo.setPresence(acceptTalkNow: value));
    } catch (_) {
      state = state.copyWith(acceptTalkNow: before);
      rethrow;
    }
  }

  /// Counts the 2-hour window down every second while online. When it runs
  /// out the server takes them offline; this just picks that up.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (state.status == PresenceStatus.offline) return;
      final DateTime? endsAt = state.window.endsAt;
      final Duration left = endsAt != null
          ? endsAt.difference(DateTime.now())
          : state.window.remaining - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        state = state.copyWith(window: state.window.withRemaining(Duration.zero));
        t.cancel();
        // Give the server's minute sweep a moment, then read its state.
        Future<void>.delayed(const Duration(seconds: 65), refresh);
        return;
      }
      state = state.copyWith(window: state.window.withRemaining(left));
    });
  }
}

final NotifierProvider<PresenceController, PresenceState> presenceProvider =
    NotifierProvider<PresenceController, PresenceState>(PresenceController.new);
