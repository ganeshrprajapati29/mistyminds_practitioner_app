import 'enums.dart';
import 'json.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  /// `GET /practitioner/notifications`
  factory AppNotification.fromJson(Json j) => AppNotification(
    id: j['id'] as String,
    kind: enumByName(
      NotificationKind.values,
      j['kind'],
      NotificationKind.general,
    ),
    title: j['title'] as String,
    body: j['body'] as String,
    time: asDate(j['time']),
    read: j['read'] as bool? ?? false,
  );

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  AppNotification markRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    time: time,
    read: true,
  );
}
