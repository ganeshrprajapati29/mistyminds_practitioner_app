import 'mock/mock_availability.dart';
import 'mock/mock_clients.dart';
import 'mock/mock_notifications.dart';
import 'mock/mock_psychologist.dart';
import 'mock/mock_sessions.dart';
import 'mock/mock_talk_requests.dart';
import 'mock/mock_transactions.dart';
import 'package:mistyminds_practitioner/data/models/app_notification.dart';
import 'package:mistyminds_practitioner/data/models/availability.dart';
import 'package:mistyminds_practitioner/data/models/client.dart';
import 'package:mistyminds_practitioner/data/models/enums.dart';
import 'package:mistyminds_practitioner/data/models/guide_video.dart';
import 'package:mistyminds_practitioner/data/models/psychologist.dart';
import 'package:mistyminds_practitioner/data/models/session.dart';
import 'package:mistyminds_practitioner/data/models/settings.dart';
import 'package:mistyminds_practitioner/data/models/talk_request.dart';
import 'package:mistyminds_practitioner/data/models/transaction.dart';
import 'package:mistyminds_practitioner/data/repositories/practitioner_repository.dart';

/// In-memory implementation backed by `lib/mock/`, for offline demos
/// (`--dart-define=USE_MOCK_DATA=true`) and widget tests. It behaves like the
/// backend: a client asks to talk a few seconds after going online, and
/// replies arrive in chat a moment after each message.
class MockPractitionerRepository implements PractitionerRepository {
  static const Duration _latency = Duration(milliseconds: 250);

  Psychologist _profile = mockPsychologist;
  PractitionerSettings _settings = PractitionerSettings.defaults;
  PresenceSnapshot _presence = const PresenceSnapshot(
    status: PresenceStatus.offline,
    acceptTalkNow: true,
    window: mockTalkWindow,
  );

  int _requestCursor = 0;
  DateTime? _nextRequestAt;
  TalkRequest? _pending;

  final Map<String, _MockChat> _chats = <String, _MockChat>{};

  Future<T> _reply<T>(T value, [Duration latency = _latency]) =>
      Future<T>.delayed(latency, () => value);

  // ---- Auth ----------------------------------------------------------------

  @override
  Future<bool> restoreSession() => _reply(false, Duration.zero);

  @override
  Future<void> login({required String identifier, required String password}) =>
      _reply<void>(null, const Duration(milliseconds: 900));

  @override
  Future<void> requestPasswordReset(String identifier) =>
      _reply<void>(null, const Duration(milliseconds: 700));

  @override
  Future<void> verifyOtp(String identifier, String otp) =>
      _reply<void>(null, const Duration(milliseconds: 700));

  @override
  Future<void> resetPassword(String identifier, String newPassword) =>
      _reply<void>(null, const Duration(milliseconds: 700));

  @override
  Future<void> logout() => _reply<void>(null);

  // ---- Push notifications --------------------------------------------------

  @override
  Future<void> registerDevice(String token, {required String platform}) =>
      _reply<void>(null);

  @override
  Future<void> unregisterDevice(String token) => _reply<void>(null);

  // ---- Application ---------------------------------------------------------

  @override
  Future<String> submitApplication(Map<String, Object?> application) =>
      _reply('MM-PSY-${DateTime.now().year}-0412', const Duration(seconds: 1));

  @override
  Future<String> fetchApplicationStatus(String reference) =>
      _reply('document_verification');

  // ---- Profile & settings --------------------------------------------------

  @override
  Future<Psychologist> fetchProfile() => _reply(_profile);

  @override
  Future<Psychologist> updateProfile(Psychologist profile) =>
      _reply(_profile = profile);

  @override
  Future<void> loginWithGoogle(String idToken) =>
      _reply<void>(null, const Duration(milliseconds: 900));

  @override
  Future<String> uploadApplicationDocument(List<int> bytes, String fileName) =>
      _reply('/uploads/private/applications/test/$fileName');

  @override
  Future<Psychologist> uploadPhoto(List<int> bytes, String fileName) =>
      _reply(_profile);

  @override
  Future<Psychologist> uploadDocument(
    String documentName,
    List<int> bytes,
    String fileName,
  ) => _reply(_profile);

  @override
  Future<String> contactSupport(
    String message, {
    String category = 'support',
  }) => _reply('MM-TEST01');

  @override
  Future<PractitionerSettings> fetchSettings() => _reply(_settings);

  @override
  Future<PractitionerSettings> saveSettings(PractitionerSettings settings) =>
      _reply(_settings = settings);

  // ---- Sessions ------------------------------------------------------------

  @override
  Future<List<Session>> fetchSessions() =>
      _reply(List<Session>.of(mockSessions));

  @override
  Future<void> cancelSession(String sessionId, String reason) =>
      _reply<void>(null);

  @override
  Future<void> requestReschedule(String sessionId) => _reply<void>(null);

  @override
  Future<void> saveSessionNotes(String sessionId, String notes) =>
      _reply<void>(null);

  @override
  Future<ConsultationRoom> startSession(String sessionId) => _reply(
    ConsultationRoom(
      session: mockSessions.firstWhere((Session s) => s.id == sessionId),
    ),
  );

  @override
  Future<double> completeSession(
    String sessionId, {
    required Duration duration,
    String? privateNote,
  }) {
    for (final Session s in mockSessions) {
      if (s.id == sessionId) return _reply(s.fee * 0.45);
    }
    final int minutes = duration.inMinutes < 1 ? 1 : duration.inMinutes;
    return _reply((minutes * 31 * 0.45 * 100).round() / 100);
  }

  // ---- Availability --------------------------------------------------------

  @override
  Future<Map<DateTime, List<AvailabilitySlot>>> fetchAvailability() =>
      _reply(<DateTime, List<AvailabilitySlot>>{
        for (final MapEntry<DateTime, List<AvailabilitySlot>> e
            in mockAvailability.entries)
          e.key: List<AvailabilitySlot>.of(e.value),
      });

  @override
  Future<Map<DateTime, List<AvailabilitySlot>>> saveAvailability(
    Map<DateTime, List<AvailabilitySlot>> slots,
  ) => _reply(slots, const Duration(milliseconds: 700));

  // ---- Talk Now ------------------------------------------------------------

  @override
  Future<PresenceSnapshot> fetchPresence() => _reply(_presence);

  @override
  Future<PresenceSnapshot> setPresence({
    PresenceStatus? status,
    bool? acceptTalkNow,
  }) {
    if (status == PresenceStatus.online &&
        _presence.status != PresenceStatus.online) {
      _nextRequestAt = DateTime.now().add(const Duration(seconds: 6));
    }
    _presence = PresenceSnapshot(
      status: status ?? _presence.status,
      acceptTalkNow: acceptTalkNow ?? _presence.acceptTalkNow,
      window: _presence.window,
    );
    return _reply(_presence);
  }

  @override
  Future<TalkRequest?> nextTalkRequest() {
    final DateTime? due = _nextRequestAt;
    final bool live =
        _presence.status == PresenceStatus.online && _presence.acceptTalkNow;
    if (_pending == null &&
        live &&
        due != null &&
        DateTime.now().isAfter(due)) {
      final List<TalkRequest> all = mockTalkRequests();
      _pending = all[_requestCursor % all.length];
      _requestCursor++;
    }
    return _reply(live ? _pending : null);
  }

  @override
  Future<AcceptedTalk> acceptRequest(String requestId) {
    final TalkRequest r = _pending ?? mockTalkRequests().first;
    _pending = null;
    _nextRequestAt = null; // no new requests while in a session
    final String sessionId =
        'talk_${r.id}_${DateTime.now().millisecondsSinceEpoch}';
    _chats[sessionId] = _MockChat(
      opening:
          'Hi… thank you for accepting. I’ve been ${r.concern.toLowerCase()}.',
    );
    final TalkRequest accepted = TalkRequest(
      id: r.id,
      sessionId: sessionId,
      message: r.message,
      mode: r.mode,
      expectedMinutes: r.expectedMinutes,
      anonymous: r.anonymous,
      clientName: r.clientName,
      requestedAt: r.requestedAt,
      concern: r.concern,
    );
    // Offline demo: no call credentials, so the call screens run in demo mode.
    return _reply(
      AcceptedTalk(
        request: accepted,
        room: ConsultationRoom(
          session: Session(
            id: sessionId,
            clientId: 'mock_client',
            clientName: r.clientName,
            anonymous: r.anonymous,
            start: DateTime.now(),
            duration: Duration(minutes: r.expectedMinutes),
            mode: r.mode,
            status: SessionStatus.upcoming,
            fee: r.expectedMinutes * 20,
            concern: r.concern,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> declineRequest(String requestId) {
    _pending = null;
    _nextRequestAt = DateTime.now().add(const Duration(seconds: 15));
    return _reply<void>(null);
  }

  // ---- Chat ----------------------------------------------------------------

  @override
  Future<ChatSnapshot> fetchChat(String sessionId) {
    final _MockChat chat = _chats.putIfAbsent(
      sessionId,
      () => _MockChat(opening: 'Hi… thank you for being here.'),
    );
    return _reply(chat.snapshot(), Duration.zero);
  }

  @override
  Future<ChatMessage> sendChatMessage(String sessionId, String text) {
    final _MockChat chat = _chats.putIfAbsent(
      sessionId,
      () => _MockChat(opening: 'Hi… thank you for being here.'),
    );
    return _reply(chat.send(text), const Duration(milliseconds: 120));
  }

  // ---- People & money ------------------------------------------------------

  @override
  Future<List<Client>> fetchClients() => _reply(mockClients);

  @override
  Future<EarningsSummary> fetchEarningsSummary() => _reply(mockEarningsSummary);

  @override
  Future<List<EarningTransaction>> fetchTransactions() =>
      _reply(mockTransactions);

  @override
  Future<void> requestPayout() => _reply<void>(null);

  // ---- Notifications -------------------------------------------------------

  @override
  Future<List<AppNotification>> fetchNotifications() =>
      _reply(List<AppNotification>.of(mockNotifications));

  @override
  Future<void> markNotificationsRead(Iterable<String> ids) =>
      _reply<void>(null);

  @override
  Future<void> markAllNotificationsRead() => _reply<void>(null);

  // ---- Videos --------------------------------------------------------------

  @override
  Future<List<GuideVideo>> fetchGuideVideos() =>
      _reply(const <GuideVideo>[], Duration.zero);

  @override
  Future<GuideVideo> markGuideVideoWatched(
    String videoId, {
    bool completed = true,
  }) => _reply(
    GuideVideo(
      id: videoId,
      title: '',
      description: '',
      url: '',
      placements: const <VideoPlacement>{},
      mandatory: false,
      watched: true,
    ),
  );
}

/// A simulated client on the other end of a chat: they open the conversation
/// shortly after it starts and reply a couple of seconds after each message.
class _MockChat {
  _MockChat({required String opening}) {
    _schedule(opening, const Duration(milliseconds: 1400));
  }

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<(DateTime, String)> _queued = <(DateTime, String)>[];
  int _replyIndex = 0;

  void _schedule(String text, Duration after) =>
      _queued.add((DateTime.now().add(after), text));

  void _deliverDue() {
    final DateTime now = DateTime.now();
    for (final (DateTime due, String text) in List<(DateTime, String)>.of(
      _queued,
    )) {
      if (now.isAfter(due)) {
        _queued.remove((due, text));
        _messages.add(
          ChatMessage(
            id: 'c${_messages.length}',
            text: text,
            fromMe: false,
            time: due,
          ),
        );
      }
    }
  }

  ChatSnapshot snapshot() {
    _deliverDue();
    return ChatSnapshot(
      messages: List<ChatMessage>.of(_messages),
      clientTyping: _queued.isNotEmpty,
    );
  }

  ChatMessage send(String text) {
    _deliverDue();
    final ChatMessage mine = ChatMessage(
      id: 'm${_messages.length}',
      text: text,
      fromMe: true,
      time: DateTime.now(),
    );
    _messages.add(mine);
    if (_replyIndex < mockClientReplies.length) {
      _schedule(
        mockClientReplies[_replyIndex++],
        const Duration(milliseconds: 2200),
      );
    }
    return mine;
  }
}
