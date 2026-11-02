import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mistyminds_practitioner/data/api/api_client.dart';
import 'package:mistyminds_practitioner/data/api/api_exception.dart';
import 'package:mistyminds_practitioner/data/api/token_store.dart';
import 'package:mistyminds_practitioner/data/models/app_notification.dart';
import 'package:mistyminds_practitioner/data/models/availability.dart';
import 'package:mistyminds_practitioner/data/models/client.dart';
import 'package:mistyminds_practitioner/data/models/enums.dart';
import 'package:mistyminds_practitioner/data/models/psychologist.dart';
import 'package:mistyminds_practitioner/data/models/session.dart';
import 'package:mistyminds_practitioner/data/models/settings.dart';
import 'package:mistyminds_practitioner/data/models/transaction.dart';
import 'package:mistyminds_practitioner/data/repositories/api_practitioner_repository.dart';

/// Tokens kept in memory only — secure storage needs a device.
class _MemoryTokenStore extends TokenStore {
  String? _a;
  String? _r;

  @override
  String? get accessToken => _a;
  @override
  String? get refreshToken => _r;
  @override
  bool get hasSession => _r != null;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _a = accessToken;
    _r = refreshToken;
  }

  @override
  Future<bool> load() async => hasSession;

  @override
  Future<void> clear() async => _a = _r = null;
}

/// Checks that the app parses every response of the real backend.
///
/// Needs a running backend seeded with `npm run seed:practitioner`:
///   MISTY_API_URL=http://localhost:5000 flutter test test/api_contract_test.dart
void main() {
  final String? baseUrl = Platform.environment['MISTY_API_URL'];
  final bool skip = baseUrl == null;

  late ApiPractitionerRepository repo;

  setUpAll(() async {
    if (skip) return;
    final _MemoryTokenStore tokens = _MemoryTokenStore();
    repo = ApiPractitionerRepository(
      ApiClient(baseUrl: baseUrl, tokens: tokens),
      tokens,
    );
    await repo.login(
      identifier: 'ananya.mehta@mistyminds.in',
      password: 'misty123',
    );
  });

  test('wrong password surfaces the backend’s own message', () async {
    final _MemoryTokenStore tokens = _MemoryTokenStore();
    final ApiPractitionerRepository fresh = ApiPractitionerRepository(
      ApiClient(baseUrl: baseUrl!, tokens: tokens),
      tokens,
    );
    await expectLater(
      fresh.login(identifier: 'ananya.mehta@mistyminds.in', password: 'nope'),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.code, 'code', 'INVALID_CREDENTIALS')
            .having(
              (ApiException e) => e.message,
              'message',
              contains('doesn’t match'),
            ),
      ),
    );
  }, skip: skip);

  test('profile', () async {
    final Psychologist p = await repo.fetchProfile();
    expect(p.name, 'Dr. Ananya Mehta');
    expect(p.title, 'Clinical Psychologist');
    expect(p.qualifications, hasLength(3));
    expect(
      p.documents.map((d) => d.status).toSet(),
      contains(DocumentStatus.underReview),
    );
    expect(p.modes, <ConsultMode>[
      ConsultMode.chat,
      ConsultMode.audio,
      ConsultMode.video,
    ]);
    expect(p.bank.accountMasked, 'XXXX XXXX 4821');
  }, skip: skip);

  test('sessions, clients, earnings, notifications', () async {
    final List<Session> sessions = await repo.fetchSessions();
    expect(sessions, isNotEmpty);
    expect(
      sessions.where((Session s) => s.status == SessionStatus.upcoming),
      hasLength(5),
    );
    expect(
      sessions.where((Session s) => s.status == SessionStatus.cancelled),
      hasLength(2),
    );

    final List<Client> clients = await repo.fetchClients();
    expect(clients, hasLength(6));
    expect(clients.where((Client c) => c.anonymous), hasLength(2));

    final EarningsSummary summary = await repo.fetchEarningsSummary();
    expect(summary.total, greaterThan(0));
    final List<EarningTransaction> txs = await repo.fetchTransactions();
    expect(txs.first.title, 'Talk Now session');
    expect(
      txs.any((EarningTransaction t) => t.type == TransactionType.payout),
      isTrue,
    );

    final List<AppNotification> notes = await repo.fetchNotifications();
    expect(notes, hasLength(5));
    expect(notes.first.kind, NotificationKind.talkRequest);
  }, skip: skip);

  test('availability round-trips', () async {
    final Map<DateTime, List<AvailabilitySlot>> before = await repo
        .fetchAvailability();
    expect(before.values.expand((List<AvailabilitySlot> s) => s), isNotEmpty);
    final Map<DateTime, List<AvailabilitySlot>> after = await repo
        .saveAvailability(before);
    expect(after.keys.toSet(), before.keys.toSet());
  }, skip: skip);

  test('presence, talk requests and settings', () async {
    final PresenceSnapshot online = await repo.setPresence(
      status: PresenceStatus.online,
    );
    expect(online.status, PresenceStatus.online);
    expect(online.window.remaining, greaterThan(Duration.zero));
    expect(await repo.nextTalkRequest(), isNull);
    final PresenceSnapshot offline = await repo.setPresence(
      status: PresenceStatus.offline,
    );
    expect(offline.status, PresenceStatus.offline);

    final PractitionerSettings s = await repo.fetchSettings();
    final PractitionerSettings saved = await repo.saveSettings(
      s.copyWith(privacy: <String, bool>{...s.privacy, 'appLock': true}),
    );
    expect(saved.privacy['appLock'], isTrue);
    await repo.saveSettings(s);
  }, skip: skip);

  test('starting a session outside its window is refused kindly', () async {
    final Session later = (await repo.fetchSessions()).firstWhere(
      (Session s) =>
          s.status == SessionStatus.upcoming &&
          s.start.isAfter(DateTime.now().add(const Duration(days: 1))),
    );
    await expectLater(
      repo.startSession(later.id),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.statusCode,
          'status',
          403,
        ),
      ),
    );
  }, skip: skip);
}
