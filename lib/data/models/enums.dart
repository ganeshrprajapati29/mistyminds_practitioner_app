import '../../core/constants/app_assets.dart';

/// How a session is held.
enum ConsultMode {
  chat('Chat', 'Just talk (chat)', AppAssets.iconChat),
  audio('Audio', 'Voice call', AppAssets.iconAudio),
  video('Video', 'Video call', AppAssets.iconVideo);

  const ConsultMode(this.label, this.requestLabel, this.icon);

  final String label;

  /// Wording used on an incoming request ("Just talk (chat)").
  final String requestLabel;
  final String icon;
}

enum SessionStatus {
  upcoming('Upcoming'),
  completed('Completed'),
  cancelled('Cancelled');

  const SessionStatus(this.label);
  final String label;
}

/// Where the psychologist is in the Talk Now flow.
enum PresenceStatus { offline, online, paused }

enum TransactionType { sessionCredit, payout }

enum TransactionStatus {
  completed('Completed'),
  pending('Pending'),
  processing('Processing');

  const TransactionStatus(this.label);
  final String label;
}

enum NotificationKind {
  sessionBooked(AppAssets.iconCalendar),
  talkRequest(AppAssets.iconTalkNow),
  sessionReminder(AppAssets.iconClock),
  availabilityEnding(AppAssets.iconClock),
  paymentReceived(AppAssets.iconWallet),
  general(AppAssets.iconNotification);

  const NotificationKind(this.icon);
  final String icon;
}

enum DocumentStatus {
  verified('Verified'),
  underReview('Under review'),
  missing('Not uploaded');

  const DocumentStatus(this.label);
  final String label;
}
