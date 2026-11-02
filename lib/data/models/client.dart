import 'enums.dart';
import 'json.dart';

/// A person the psychologist has worked with. Only what the client chose to
/// share is held here.
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.anonymous,
    required this.sessionCount,
    required this.lastSession,
    required this.firstSession,
    required this.preferredMode,
    required this.concerns,
    this.ageRange,
    this.privateNote,
  });

  /// `GET /practitioner/clients`
  factory Client.fromJson(Json j) => Client(
    id: j['id'] as String,
    name: j['name'] as String,
    anonymous: j['anonymous'] as bool? ?? false,
    sessionCount: asInt(j['sessionCount']),
    lastSession: asDate(j['lastSession']),
    firstSession: asDate(j['firstSession']),
    preferredMode: enumByName(
      ConsultMode.values,
      j['preferredMode'],
      ConsultMode.chat,
    ),
    concerns: stringList(j['concerns']),
    ageRange: j['ageRange'] as String?,
    privateNote: j['privateNote'] as String?,
  );

  final String id;
  final String name;
  final bool anonymous;
  final int sessionCount;
  final DateTime lastSession;
  final DateTime firstSession;
  final ConsultMode preferredMode;
  final List<String> concerns;
  final String? ageRange;

  /// The psychologist's own note — never shown to the client.
  final String? privateNote;
}
