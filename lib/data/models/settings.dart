import 'json.dart';

/// The practitioner's saved preferences: notification toggles, availability
/// preferences and privacy switches. Keys match `GET /practitioner/me/settings`.
class PractitionerSettings {
  const PractitionerSettings({
    required this.notifications,
    required this.availability,
    required this.privacy,
  });

  factory PractitionerSettings.fromJson(Json j) => PractitionerSettings(
    notifications: Map<String, bool>.from(jsonMap(j['notifications'])),
    availability: Map<String, Object>.from(jsonMap(j['availability'])),
    privacy: Map<String, bool>.from(jsonMap(j['privacy'])),
  );

  static const PractitionerSettings defaults = PractitionerSettings(
    notifications: <String, bool>{
      'talkRequests': true,
      'newBookings': true,
      'sessionReminders': true,
      'availabilityEnding': true,
      'payments': true,
      'tips': false,
    },
    availability: <String, Object>{
      'sessionLength': '50 min',
      'breakBetween': '10 min',
      'minimumNotice': '4 hours',
      'remindToGoOnline': false,
      'openWeekends': true,
    },
    privacy: <String, bool>{
      'showPhoto': true,
      'appLock': false,
      'hidePreviews': true,
    },
  );

  final Map<String, bool> notifications;
  final Map<String, Object> availability;
  final Map<String, bool> privacy;

  Json toJson() => <String, dynamic>{
    'notifications': notifications,
    'availability': availability,
    'privacy': privacy,
  };

  PractitionerSettings copyWith({
    Map<String, bool>? notifications,
    Map<String, Object>? availability,
    Map<String, bool>? privacy,
  }) => PractitionerSettings(
    notifications: notifications ?? this.notifications,
    availability: availability ?? this.availability,
    privacy: privacy ?? this.privacy,
  );
}
