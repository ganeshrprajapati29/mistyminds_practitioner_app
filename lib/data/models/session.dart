import '../../core/config/app_config.dart';
import 'enums.dart';
import 'json.dart';

/// A booked or completed consultation.
class Session {
  const Session({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.anonymous,
    required this.start,
    required this.duration,
    required this.mode,
    required this.status,
    required this.fee,
    required this.concern,
    this.notes,
    this.cancelReason,
    this.clientPhotoUrl,
  });

  /// `GET /practitioner/sessions`
  factory Session.fromJson(Json j) => Session(
    id: j['id'] as String,
    clientId: j['clientId'] as String,
    clientName: j['clientName'] as String,
    anonymous: j['anonymous'] as bool? ?? false,
    clientPhotoUrl: AppConfig.resolveMedia(j['clientPhotoUrl'] as String?),
    start: asDate(j['start']),
    duration: Duration(minutes: asInt(j['durationMinutes'])),
    mode: enumByName(ConsultMode.values, j['mode'], ConsultMode.chat),
    status: enumByName(
      SessionStatus.values,
      j['status'],
      SessionStatus.upcoming,
    ),
    fee: asInt(j['fee']),
    concern: j['concern'] as String? ?? '',
    notes: j['notes'] as String?,
    cancelReason: j['cancelReason'] as String?,
  );

  final String id;
  final String clientId;

  /// What the psychologist sees: a first name, or an alias when anonymous.
  final String clientName;
  final bool anonymous;

  /// The client's profile photo, when they have set one.
  final String? clientPhotoUrl;
  final DateTime start;
  final Duration duration;
  final ConsultMode mode;
  final SessionStatus status;
  final int fee;
  final String concern;
  final String? notes;
  final String? cancelReason;

  DateTime get end => start.add(duration);

  Session copyWith({
    SessionStatus? status,
    String? cancelReason,
    String? notes,
  }) => Session(
    id: id,
    clientId: clientId,
    clientName: clientName,
    anonymous: anonymous,
    clientPhotoUrl: clientPhotoUrl,
    start: start,
    duration: duration,
    mode: mode,
    status: status ?? this.status,
    fee: fee,
    concern: concern,
    notes: notes ?? this.notes,
    cancelReason: cancelReason ?? this.cancelReason,
  );
}
