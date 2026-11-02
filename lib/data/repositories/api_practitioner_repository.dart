import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../models/app_notification.dart';
import '../models/availability.dart';
import '../models/client.dart';
import '../models/enums.dart';
import '../models/guide_video.dart';
import '../models/json.dart';
import '../models/psychologist.dart';
import '../models/session.dart';
import '../models/settings.dart';
import '../models/talk_request.dart';
import '../models/transaction.dart';
import 'practitioner_repository.dart';

/// [PractitionerRepository] backed by the Misty Minds backend's
/// `/practitioner` API (see backend/README.md → Practitioner API).
class ApiPractitionerRepository implements PractitionerRepository {
  ApiPractitionerRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  static const String _base = '/practitioner';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDay(String s) {
    final List<int> p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  List<T> _list<T>(Object? data, T Function(Json) parse) =>
      jsonList(data).map(parse).toList();

  // ---- Auth ----------------------------------------------------------------

  @override
  Future<bool> restoreSession() async {
    if (!await _tokens.load()) return false;
    try {
      // Validates the stored session (refreshing it if the access token
      // expired while the app was closed).
      await _api.get<Json>('$_base/me');
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    }
  }

  @override
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final Json data = await _api.post<Json>(
      '$_base/auth/login',
      data: <String, dynamic>{
        'identifier': identifier.trim(),
        'password': password,
      },
    );
    final Json tokens = jsonMap(data['tokens']);
    await _tokens.save(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }

  @override
  Future<void> loginWithGoogle(String idToken) async {
    final Json data = await _api.post<Json>(
      '$_base/auth/google',
      data: <String, dynamic>{'idToken': idToken},
    );
    final Json tokens = jsonMap(data['tokens']);
    await _tokens.save(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }

  @override
  Future<void> requestPasswordReset(String identifier) => _api.post<Json>(
    '$_base/auth/password/forgot',
    data: <String, dynamic>{'identifier': identifier.trim()},
  );

  @override
  Future<void> verifyOtp(String identifier, String otp) => _api.post<Json>(
    '$_base/auth/otp/verify',
    data: <String, dynamic>{'identifier': identifier.trim(), 'otp': otp},
  );

  @override
  Future<void> resetPassword(String identifier, String newPassword) =>
      _api.post<Json>(
        '$_base/auth/password/reset',
        data: <String, dynamic>{
          'identifier': identifier.trim(),
          'newPassword': newPassword,
        },
      );

  @override
  Future<void> logout() async {
    final String? refreshToken = _tokens.refreshToken;
    try {
      if (refreshToken != null) {
        await _api.post<Json>(
          '$_base/auth/logout',
          data: <String, dynamic>{'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Signing out locally must work even offline.
    } finally {
      await _tokens.clear();
    }
  }

  // ---- Push notifications --------------------------------------------------

  @override
  Future<void> registerDevice(String token, {required String platform}) =>
      _api.post<Json>(
        '$_base/me/devices',
        data: <String, dynamic>{'token': token, 'platform': platform},
      );

  @override
  Future<void> unregisterDevice(String token) => _api.delete<Json>(
    '$_base/me/devices',
    data: <String, dynamic>{'token': token},
  );

  // ---- Application ---------------------------------------------------------

  @override
  Future<String> submitApplication(Map<String, Object?> application) async {
    final Json data = await _api.post<Json>(
      '$_base/applications',
      data: application,
    );
    return data['reference'] as String;
  }

  @override
  Future<String> fetchApplicationStatus(String reference) async {
    final Json data = await _api.get<Json>(
      '$_base/applications/${Uri.encodeComponent(reference)}',
    );
    return data['status'] as String;
  }

  // ---- Profile & settings --------------------------------------------------

  @override
  Future<Psychologist> fetchProfile() async =>
      Psychologist.fromJson(await _api.get<Json>('$_base/me'));

  @override
  Future<String> uploadApplicationDocument(
    List<int> bytes,
    String fileName,
  ) async {
    final Json data = await _api.upload<Json>(
      '$_base/applications/documents',
      () => FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
    );
    return data['file'] as String;
  }

  @override
  Future<Psychologist> uploadPhoto(List<int> bytes, String fileName) async =>
      Psychologist.fromJson(
        await _api.upload<Json>(
          '$_base/me/photo',
          () => FormData.fromMap(<String, dynamic>{
            'file': MultipartFile.fromBytes(bytes, filename: fileName),
          }),
        ),
      );

  @override
  Future<Psychologist> uploadDocument(
    String documentName,
    List<int> bytes,
    String fileName,
  ) async => Psychologist.fromJson(
    await _api.upload<Json>(
      '$_base/me/documents',
      () => FormData.fromMap(<String, dynamic>{
        'name': documentName,
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      }),
    ),
  );

  @override
  Future<String> contactSupport(
    String message, {
    String category = 'support',
  }) async {
    final Json data = await _api.post<Json>(
      '$_base/support/tickets',
      data: <String, dynamic>{
        'category': category,
        'message': message,
        'platform': 'app',
      },
    );
    return data['reference'] as String;
  }

  @override
  Future<Psychologist> updateProfile(Psychologist profile) async =>
      Psychologist.fromJson(
        await _api.patch<Json>('$_base/me', data: profile.toUpdateJson()),
      );

  @override
  Future<PractitionerSettings> fetchSettings() async =>
      PractitionerSettings.fromJson(await _api.get<Json>('$_base/me/settings'));

  @override
  Future<PractitionerSettings> saveSettings(
    PractitionerSettings settings,
  ) async => PractitionerSettings.fromJson(
    await _api.put<Json>('$_base/me/settings', data: settings.toJson()),
  );

  // ---- Sessions ------------------------------------------------------------

  @override
  Future<List<Session>> fetchSessions() async =>
      _list(await _api.get<List<dynamic>>('$_base/sessions'), Session.fromJson);

  @override
  Future<void> cancelSession(String sessionId, String reason) =>
      _api.post<Json>(
        '$_base/sessions/$sessionId/cancel',
        data: <String, dynamic>{'reason': reason},
      );

  @override
  Future<void> requestReschedule(String sessionId) =>
      _api.post<Json>('$_base/sessions/$sessionId/reschedule-request');

  @override
  Future<void> saveSessionNotes(String sessionId, String notes) =>
      _api.put<Json>(
        '$_base/sessions/$sessionId/notes',
        data: <String, dynamic>{'notes': notes},
      );

  @override
  Future<ConsultationRoom> startSession(String sessionId) async =>
      ConsultationRoom.fromJson(
        await _api.post<Json>('$_base/sessions/$sessionId/start'),
      );

  @override
  Future<double> completeSession(
    String sessionId, {
    required Duration duration,
    String? privateNote,
  }) async {
    final Json data = await _api.post<Json>(
      '$_base/sessions/$sessionId/complete',
      data: <String, dynamic>{
        'durationSeconds': duration.inSeconds,
        if (privateNote != null && privateNote.trim().isNotEmpty)
          'privateNote': privateNote.trim(),
      },
    );
    return asDouble(data['earned']);
  }

  // ---- Availability --------------------------------------------------------

  Map<DateTime, List<AvailabilitySlot>> _parseAvailability(Json data) =>
      <DateTime, List<AvailabilitySlot>>{
        for (final Json day in jsonList(data['days']))
          _parseDay(day['date'] as String): jsonList(
            day['slots'],
          ).map(AvailabilitySlot.fromJson).toList(),
      };

  @override
  Future<Map<DateTime, List<AvailabilitySlot>>> fetchAvailability() async =>
      _parseAvailability(await _api.get<Json>('$_base/availability'));

  @override
  Future<Map<DateTime, List<AvailabilitySlot>>> saveAvailability(
    Map<DateTime, List<AvailabilitySlot>> slots,
  ) async {
    final Json data = await _api.put<Json>(
      '$_base/availability',
      data: <String, dynamic>{
        'days': <Json>[
          for (final MapEntry<DateTime, List<AvailabilitySlot>> e
              in slots.entries)
            <String, dynamic>{
              'date': _day(e.key),
              'slots': e.value.map((AvailabilitySlot s) => s.toJson()).toList(),
            },
        ],
      },
    );
    return _parseAvailability(data);
  }

  // ---- Talk Now ------------------------------------------------------------

  @override
  Future<PresenceSnapshot> fetchPresence() async =>
      PresenceSnapshot.fromJson(await _api.get<Json>('$_base/presence'));

  @override
  Future<PresenceSnapshot> setPresence({
    PresenceStatus? status,
    bool? acceptTalkNow,
  }) async => PresenceSnapshot.fromJson(
    await _api.put<Json>(
      '$_base/presence',
      data: <String, dynamic>{
        if (status != null) 'status': status.name,
        'acceptTalkNow': ?acceptTalkNow,
      },
    ),
  );

  @override
  Future<TalkRequest?> nextTalkRequest() async {
    final Json? data = await _api.get<Json?>('$_base/talk-requests/next');
    return data == null ? null : TalkRequest.fromJson(data);
  }

  @override
  Future<AcceptedTalk> acceptRequest(String requestId) async {
    final Json data = await _api.post<Json>(
      '$_base/talk-requests/$requestId/accept',
    );
    return AcceptedTalk(
      request: TalkRequest.fromJson(jsonMap(data['request'])),
      room: ConsultationRoom.fromJson(data),
    );
  }

  @override
  Future<void> declineRequest(String requestId) =>
      _api.post<Json>('$_base/talk-requests/$requestId/decline');

  // ---- Chat ----------------------------------------------------------------

  @override
  Future<ChatSnapshot> fetchChat(String sessionId) async => ChatSnapshot(
    messages: _list(
      await _api.get<List<dynamic>>('$_base/sessions/$sessionId/messages'),
      ChatMessage.fromJson,
    ),
  );

  @override
  Future<ChatMessage> sendChatMessage(String sessionId, String text) async =>
      ChatMessage.fromJson(
        await _api.post<Json>(
          '$_base/sessions/$sessionId/messages',
          data: <String, dynamic>{'text': text},
        ),
      );

  // ---- People & money ------------------------------------------------------

  @override
  Future<List<Client>> fetchClients() async =>
      _list(await _api.get<List<dynamic>>('$_base/clients'), Client.fromJson);

  @override
  Future<EarningsSummary> fetchEarningsSummary() async =>
      EarningsSummary.fromJson(await _api.get<Json>('$_base/earnings/summary'));

  @override
  Future<List<EarningTransaction>> fetchTransactions() async => _list(
    await _api.get<List<dynamic>>('$_base/earnings/transactions'),
    EarningTransaction.fromJson,
  );

  @override
  Future<void> requestPayout() => _api.post<Json>('$_base/earnings/payout');

  // ---- Notifications -------------------------------------------------------

  @override
  Future<List<AppNotification>> fetchNotifications() async => _list(
    await _api.get<List<dynamic>>('$_base/notifications'),
    AppNotification.fromJson,
  );

  @override
  Future<void> markNotificationsRead(Iterable<String> ids) =>
      _api.post<List<dynamic>>(
        '$_base/notifications/read',
        data: <String, dynamic>{'ids': ids.toList()},
      );

  @override
  Future<void> markAllNotificationsRead() =>
      _api.post<List<dynamic>>('$_base/notifications/read-all');

  // ---- Videos --------------------------------------------------------------

  @override
  Future<List<GuideVideo>> fetchGuideVideos() async => _list(
    await _api.get<List<dynamic>>('$_base/videos'),
    GuideVideo.fromJson,
  );

  @override
  Future<GuideVideo> markGuideVideoWatched(
    String videoId, {
    bool completed = true,
  }) async => GuideVideo.fromJson(
    await _api.post<Json>(
      '$_base/videos/$videoId/watched',
      data: <String, dynamic>{'completed': completed},
    ),
  );
}
