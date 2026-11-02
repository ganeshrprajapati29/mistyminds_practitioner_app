import 'package:flutter/material.dart';

import 'package:mistyminds_practitioner/data/models/availability.dart';

DateTime _day(int offset) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day + offset);
}

/// Availability keyed by calendar day (date-only).
final Map<DateTime, List<AvailabilitySlot>> mockAvailability =
    <DateTime, List<AvailabilitySlot>>{
      _day(0): const <AvailabilitySlot>[
        AvailabilitySlot(
          id: 'av_1',
          start: TimeOfDay(hour: 18, minute: 0),
          end: TimeOfDay(hour: 20, minute: 0),
        ),
        AvailabilitySlot(
          id: 'av_2',
          start: TimeOfDay(hour: 20, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
      ],
      _day(1): const <AvailabilitySlot>[
        AvailabilitySlot(
          id: 'av_3',
          start: TimeOfDay(hour: 10, minute: 0),
          end: TimeOfDay(hour: 13, minute: 0),
          bookedMinutes: 50,
        ),
      ],
      _day(3): const <AvailabilitySlot>[
        AvailabilitySlot(
          id: 'av_4',
          start: TimeOfDay(hour: 17, minute: 0),
          end: TimeOfDay(hour: 20, minute: 0),
        ),
      ],
      _day(5): const <AvailabilitySlot>[
        AvailabilitySlot(
          id: 'av_5',
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
          bookedMinutes: 100,
        ),
      ],
      _day(8): const <AvailabilitySlot>[
        AvailabilitySlot(
          id: 'av_6',
          start: TimeOfDay(hour: 18, minute: 0),
          end: TimeOfDay(hour: 21, minute: 0),
        ),
      ],
    };

/// Today's Talk Now window from the reference ("6:00 PM – 8:00 PM").
const TalkWindow mockTalkWindow = TalkWindow(
  start: TimeOfDay(hour: 18, minute: 0),
  end: TimeOfDay(hour: 20, minute: 0),
  remaining: Duration(hours: 1, minutes: 42),
);
