import 'package:flutter/material.dart';

import 'enums.dart';
import 'json.dart';

TimeOfDay _parseHm(Object? hm) {
  final List<String> parts = (hm as String? ?? '00:00').split(':');
  final int h = int.tryParse(parts.first) ?? 0;
  final int m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

String _formatHm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// One bookable window on one day.
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.start,
    required this.end,
    this.bookedMinutes = 0,
  });

  /// One slot of `GET /practitioner/availability` → days[].slots[]
  factory AvailabilitySlot.fromJson(Json j) => AvailabilitySlot(
    id: j['id'] as String,
    start: _parseHm(j['start']),
    end: _parseHm(j['end']),
    bookedMinutes: asInt(j['bookedMinutes']),
  );

  Json toJson() => <String, dynamic>{
    'id': id,
    'start': _formatHm(start),
    'end': _formatHm(end),
  };

  final String id;
  final TimeOfDay start;
  final TimeOfDay end;

  /// How much of the window clients have already booked.
  final int bookedMinutes;

  int get _startMin => start.hour * 60 + start.minute;
  int get _endMin => end.hour * 60 + end.minute;

  Duration get duration => Duration(minutes: _endMin - _startMin);
  bool get isValid => _endMin > _startMin;
  bool get partiallyBooked => bookedMinutes > 0;

  bool overlaps(AvailabilitySlot other) =>
      _startMin < other._endMin && other._startMin < _endMin;

  AvailabilitySlot copyWith({TimeOfDay? start, TimeOfDay? end}) =>
      AvailabilitySlot(
        id: id,
        start: start ?? this.start,
        end: end ?? this.end,
        bookedMinutes: bookedMinutes,
      );
}

/// The Talk Now window the psychologist is currently inside.
class TalkWindow {
  const TalkWindow({
    required this.start,
    required this.end,
    required this.remaining,
  });

  /// `window` of `GET /practitioner/presence`
  factory TalkWindow.fromJson(Json j) => TalkWindow(
    start: _parseHm(j['start']),
    end: _parseHm(j['end']),
    remaining: Duration(minutes: asInt(j['remainingMinutes'])),
  );

  final TimeOfDay start;
  final TimeOfDay end;
  final Duration remaining;

  Duration get total => Duration(
    minutes: (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute),
  );

  double get progressLeft => total.inSeconds <= 0
      ? 0
      : (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);

  TalkWindow withRemaining(Duration r) =>
      TalkWindow(start: start, end: end, remaining: r);
}

/// Where the psychologist is in the Talk Now flow, as the server sees it.
class PresenceSnapshot {
  const PresenceSnapshot({
    required this.status,
    required this.acceptTalkNow,
    required this.window,
  });

  /// `GET|PUT /practitioner/presence`
  factory PresenceSnapshot.fromJson(Json j) => PresenceSnapshot(
    status: enumByName(
      PresenceStatus.values,
      j['status'],
      PresenceStatus.offline,
    ),
    acceptTalkNow: j['acceptTalkNow'] as bool? ?? true,
    window: TalkWindow.fromJson(jsonMap(j['window'])),
  );

  final PresenceStatus status;
  final bool acceptTalkNow;
  final TalkWindow window;
}
