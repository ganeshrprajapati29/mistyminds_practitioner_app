import '../../core/config/app_config.dart';
import 'enums.dart';
import 'json.dart';
import 'session.dart';

/// An instant "Talk to someone now" request from a client.
class TalkRequest {
  const TalkRequest({
    required this.id,
    required this.message,
    required this.mode,
    required this.expectedMinutes,
    required this.anonymous,
    required this.clientName,
    required this.requestedAt,
    required this.concern,
    this.sessionId,
    this.clientPhotoUrl,
    this.details = const RequestDetails(),
  });

  /// `GET /practitioner/talk-requests/next`
  factory TalkRequest.fromJson(Json j) => TalkRequest(
    id: j['id'] as String,
    sessionId: j['sessionId'] as String?,
    message: j['message'] as String? ?? '',
    mode: enumByName(ConsultMode.values, j['mode'], ConsultMode.chat),
    expectedMinutes: asInt(j['expectedMinutes']),
    anonymous: j['anonymous'] as bool? ?? false,
    clientName: j['clientName'] as String? ?? 'Client',
    clientPhotoUrl: AppConfig.resolveMedia(j['clientPhotoUrl'] as String?),
    requestedAt: asDate(j['requestedAt']),
    concern: j['concern'] as String? ?? '',
    details: j['details'] is Map
        ? RequestDetails.fromJson(jsonMap(j['details']))
        : const RequestDetails(),
  );

  final String id;

  /// The paid session this request opens once accepted.
  final String? sessionId;

  /// The line the client chose to send ("I'd like to talk to someone…").
  final String message;
  final ConsultMode mode;
  final int expectedMinutes;
  final bool anonymous;
  final String clientName;

  /// The client's profile photo, when they have set one.
  final String? clientPhotoUrl;
  final DateTime requestedAt;
  final String concern;

  /// Who is asking and why — shown on the request before it is answered.
  final RequestDetails details;
}

/// What the psychologist is told about the person behind a Talk Now request.
/// Every field is optional: an anonymous client shares no identifying details,
/// and an older server sends none at all.
class RequestDetails {
  const RequestDetails({
    this.age,
    this.gender,
    this.city,
    this.language,
    this.mood,
    this.intent,
    this.concerns = const <String>[],
    this.previousSessions,
    this.fee,
    this.sessionMinutes,
  });

  factory RequestDetails.fromJson(Json j) => RequestDetails(
    age: (j['age'] as num?)?.round(),
    gender: _text(j['gender']),
    city: _text(j['city']),
    language: _text(j['language']),
    mood: _text(j['mood']),
    intent: _text(j['intent']),
    concerns: j['concerns'] is List
        ? (j['concerns'] as List<dynamic>)
              .whereType<String>()
              .where((String c) => c.trim().isNotEmpty)
              .toList()
        : const <String>[],
    previousSessions: (j['previousSessions'] as num?)?.round(),
    fee: j['fee'] as num?,
    sessionMinutes: (j['sessionMinutes'] as num?)?.round(),
  );

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  final int? age;
  final String? gender;
  final String? city;
  final String? language;
  final String? mood;

  /// What they want from the session ("Just talk", "Help me understand"…).
  final String? intent;
  final List<String> concerns;

  /// Completed sessions with this psychologist before now.
  final int? previousSessions;

  /// What the client paid for this session.
  final num? fee;
  final int? sessionMinutes;

  /// "27 yrs · Female · Mumbai" — whatever is known.
  String get identityLine => <String>[
    if (age != null) '$age yrs',
    if (gender != null) '${gender![0].toUpperCase()}${gender!.substring(1)}',
    ?city,
  ].join(' · ');
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.time,
  });

  /// `GET /practitioner/sessions/:id/messages`
  factory ChatMessage.fromJson(Json j) => ChatMessage(
    id: j['id'] as String,
    text: j['text'] as String,
    fromMe: j['fromMe'] as bool? ?? false,
    time: asDate(j['time']),
  );

  final String id;
  final String text;
  final bool fromMe;
  final DateTime time;
}

/// A chat as it stands: its messages, and whether the client is typing.
class ChatSnapshot {
  const ChatSnapshot({required this.messages, this.clientTyping = false});

  final List<ChatMessage> messages;
  final bool clientTyping;
}

/// What opening a session returns: the session, and its chat thread if any.
class ConsultationRoom {
  const ConsultationRoom({
    required this.session,
    this.conversationId,
    this.call,
  });

  factory ConsultationRoom.fromJson(Json j) => ConsultationRoom(
    session: Session.fromJson(jsonMap(j['session'])),
    conversationId: j['conversationId'] as String?,
    call: j['call'] == null
        ? null
        : CallCredentials.fromJson(jsonMap(j['call'])),
  );

  final Session session;

  /// The chat thread (chat sessions).
  final String? conversationId;

  /// How to join the audio/video call (audio/video sessions).
  final CallCredentials? call;
}

/// Agora RTC credentials for this side of a call, minted by the backend
/// (`services/agora.js`). [peerUid] is the other person's uid in the channel.
class CallCredentials {
  const CallCredentials({
    required this.configured,
    required this.channel,
    required this.uid,
    required this.peerUid,
    this.appId,
    this.token,
  });

  factory CallCredentials.fromJson(Json j) => CallCredentials(
    configured: j['configured'] as bool? ?? false,
    appId: j['appId'] as String?,
    channel: j['channel'] as String? ?? '',
    uid: asInt(j['uid']),
    peerUid: asInt(j['peerUid']),
    token: j['token'] as String?,
  );

  /// False when the server has no Agora App ID yet — the call screens then
  /// explain that calling isn't set up instead of trying to connect.
  final bool configured;
  final String? appId;
  final String channel;
  final int uid;
  final int peerUid;

  /// Null for an Agora project in testing mode (App ID only).
  final String? token;
}

/// An accepted Talk Now request and the session it opened.
class AcceptedTalk {
  const AcceptedTalk({required this.request, required this.room});

  final TalkRequest request;
  final ConsultationRoom room;
}
