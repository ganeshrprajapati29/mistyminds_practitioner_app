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
    this.totalMinutes,
    this.endsAt,
    this.committed = false,
  });

  /// `window` of `GET /practitioner/presence`. Going online commits to a
  /// fixed 2-hour window; [endsAt] is when it ends on THIS phone's clock
  /// (worked out from the server's seconds-left, so a wrong phone clock
  /// can't skew the countdown).
  factory TalkWindow.fromJson(Json j) {
    final int? seconds = j['remainingSeconds'] is num
        ? (j['remainingSeconds'] as num).toInt()
        : null;
    final Duration remaining = seconds != null
        ? Duration(seconds: seconds)
        : Duration(minutes: asInt(j['remainingMinutes']));
    return TalkWindow(
      start: _parseHm(j['start']),
      end: _parseHm(j['end']),
      remaining: remaining,
      totalMinutes: j['totalMinutes'] is num
          ? (j['totalMinutes'] as num).toInt()
          : null,
      endsAt: seconds != null ? DateTime.now().add(remaining) : null,
      committed: j['committed'] == true,
    );
  }

  final TimeOfDay start;
  final TimeOfDay end;
  final Duration remaining;
  final int? totalMinutes;
  final DateTime? endsAt;

  /// True once they've gone online — the window is running and fixed.
  final bool committed;

  Duration get total => totalMinutes != null
      ? Duration(minutes: totalMinutes!)
      : Duration(
          minutes:
              (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute),
        );

  double get progressLeft => total.inSeconds <= 0
      ? 0
      : (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);

  /// "01:42:07"
  String get countdown {
    final Duration d = remaining.isNegative ? Duration.zero : remaining;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:'
        '${two(d.inSeconds.remainder(60))}';
  }

  TalkWindow withRemaining(Duration r) => TalkWindow(
    start: start,
    end: end,
    remaining: r,
    totalMinutes: totalMinutes,
    endsAt: endsAt,
    committed: committed,
  );
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
