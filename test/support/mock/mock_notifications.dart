import 'package:mistyminds_practitioner/data/models/app_notification.dart';
import 'package:mistyminds_practitioner/data/models/enums.dart';

DateTime _ago(Duration d) => DateTime.now().subtract(d);

final List<AppNotification> mockNotifications = <AppNotification>[
  AppNotification(
    id: 'n_01',
    kind: NotificationKind.talkRequest,
    title: 'Talk Now request',
    body:
        'Someone needed to talk while you were away. Go online to be '
        'reachable.',
    time: _ago(const Duration(minutes: 8)),
  ),
  AppNotification(
    id: 'n_02',
    kind: NotificationKind.sessionBooked,
    title: 'New session booked',
    body: 'Meera booked a 50-min video session for tomorrow, 11:00 AM.',
    time: _ago(const Duration(minutes: 42)),
  ),
  AppNotification(
    id: 'n_03',
    kind: NotificationKind.sessionReminder,
    title: 'Session reminder',
    body: 'Your video session with Riya starts at 10:30 AM.',
    time: _ago(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 'n_04',
    kind: NotificationKind.availabilityEnding,
    title: 'Availability ending soon',
    body: 'Your 6:00 PM – 8:00 PM window ends in 15 minutes.',
    time: _ago(const Duration(hours: 20)),
    read: true,
  ),
  AppNotification(
    id: 'n_05',
    kind: NotificationKind.paymentReceived,
    title: 'Payment received',
    body: '₹5,200 was settled to your HDFC account ending 4821.',
    time: _ago(const Duration(days: 4)),
    read: true,
  ),
];
