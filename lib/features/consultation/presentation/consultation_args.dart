import '../../../data/models/enums.dart';
import '../../../data/models/session.dart';
import '../../../data/models/talk_request.dart';

/// What a consultation screen needs to know about who it is with.
class ConsultationArgs {
  const ConsultationArgs({
    required this.clientName,
    required this.anonymous,
    required this.mode,
    required this.concern,
    required this.ratePerMinute,
    this.sessionId,
    this.conversationId,
    this.call,
    this.isTalkNow = false,
    this.photoUrl,
  });

  /// A Talk Now request the psychologist just accepted.
  factory ConsultationArgs.fromAccepted(AcceptedTalk a) => ConsultationArgs(
    clientName: a.request.clientName,
    anonymous: a.request.anonymous,
    photoUrl: a.request.clientPhotoUrl,
    mode: a.request.mode,
    concern: a.request.concern,
    ratePerMinute: a.request.details.fee != null &&
        (a.request.details.sessionMinutes ?? 0) > 0
      ? a.request.details.fee! / a.request.details.sessionMinutes!
      : 0,
    sessionId: a.room.session.id,
    conversationId: a.room.conversationId,
    call: a.room.call,
    isTalkNow: true,
  );

  /// A booked session the psychologist just opened.
  factory ConsultationArgs.fromRoom(ConsultationRoom room) {
    final Session s = room.session;
    return ConsultationArgs(
      clientName: s.clientName,
      anonymous: s.anonymous,
      photoUrl: s.clientPhotoUrl,
      mode: s.mode,
      concern: s.concern,
      ratePerMinute: s.fee / s.duration.inMinutes,
      sessionId: s.id,
      conversationId: room.conversationId,
      call: room.call,
    );
  }

  factory ConsultationArgs.fromRequest(TalkRequest r) => ConsultationArgs(
    clientName: r.clientName,
    anonymous: r.anonymous,
    photoUrl: r.clientPhotoUrl,
    mode: r.mode,
    concern: r.concern,
    ratePerMinute: r.details.fee != null && (r.details.sessionMinutes ?? 0) > 0
      ? r.details.fee! / r.details.sessionMinutes!
      : 0,
    sessionId: r.sessionId,
    isTalkNow: true,
  );

  factory ConsultationArgs.fromSession(Session s) => ConsultationArgs(
    clientName: s.clientName,
    anonymous: s.anonymous,
    photoUrl: s.clientPhotoUrl,
    mode: s.mode,
    concern: s.concern,
    ratePerMinute: s.fee / s.duration.inMinutes,
    sessionId: s.id,
  );

  final String clientName;
  final bool anonymous;

  /// The client's profile photo, when they have set one.
  final String? photoUrl;
  final ConsultMode mode;
  final String concern;

  /// Only for an estimate on the summary if the server's figure is missing.
  final double ratePerMinute;

  /// The session on the server (booked, or opened by accepting a Talk Now
  /// request). Messages and completion go through it.
  final String? sessionId;

  /// The chat thread (chat sessions) — used to relay typing indicators.
  final String? conversationId;

  /// Agora credentials (audio/video sessions). Null or not configured → the
  /// call screens explain that calling isn't set up yet.
  final CallCredentials? call;
  final bool isTalkNow;
}

/// Passed to the session-complete screen.
class SessionSummary {
  const SessionSummary({
    required this.args,
    required this.duration,
    this.creditedAmount,
  });

  final ConsultationArgs args;
  final Duration duration;

  /// What the server credited to the psychologist for this session.
  final double? creditedAmount;

  /// The server's net figure; an estimate with the default split (50/50,
  /// then 18% GST and 10% TDS on your half) only if it's missing.
  double get earned {
    if (creditedAmount != null) return creditedAmount!;
    final int minutes = duration.inMinutes < 1 ? 1 : duration.inMinutes;
    final double doctorGross = minutes * args.ratePerMinute * 0.5;
    final double gst = doctorGross * 0.18;
    final double tds = doctorGross * 0.1;
    return ((doctorGross - gst - tds) * 100).round() / 100;
  }
}
