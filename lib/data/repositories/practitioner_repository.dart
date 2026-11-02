import '../models/app_notification.dart';
import '../models/availability.dart';
import '../models/client.dart';
import '../models/enums.dart';
import '../models/guide_video.dart';
import '../models/psychologist.dart';
import '../models/session.dart';
import '../models/settings.dart';
import '../models/talk_request.dart';
import '../models/transaction.dart';

/// Everything the partner app reads from or writes to the backend.
///
/// The UI only ever talks to this interface (through the providers in
/// `lib/state/`). [ApiPractitionerRepository] talks to the real Misty Minds
/// backend; tests use an in-memory version (test/support).
///
/// Failures surface as `ApiException`s whose message is safe to show.
abstract interface class PractitionerRepository {
  // ---- Auth ----------------------------------------------------------------

  /// Brings back a remembered session. True when the practitioner is signed in.
  Future<bool> restoreSession();
  Future<void> login({required String identifier, required String password});

  /// "Continue with Google" — only for an existing, approved partner whose
  /// registered email matches the Google account.
  Future<void> loginWithGoogle(String idToken);
  Future<void> requestPasswordReset(String identifier);
  Future<void> verifyOtp(String identifier, String otp);
  Future<void> resetPassword(String identifier, String newPassword);
  Future<void> logout();

  // ---- Push notifications --------------------------------------------------
  /// Registers this device's FCM token so pushes reach it.
  Future<void> registerDevice(String token, {required String platform});
  Future<void> unregisterDevice(String token);

  // ---- Application ---------------------------------------------------------
  /// Returns the application reference number.
  Future<String> submitApplication(Map<String, Object?> application);

  /// Uploads a document for an application (no account yet). Returns the
  /// server's reference for it, to include in the application.
  Future<String> uploadApplicationDocument(List<int> bytes, String fileName);

  /// Review stage of a submitted application: `document_verification`,
  /// `interview`, `approved` or `rejected`.
  Future<String> fetchApplicationStatus(String reference);

  // ---- Profile & settings --------------------------------------------------
  Future<Psychologist> fetchProfile();
  Future<Psychologist> updateProfile(Psychologist profile);

  /// Profile photo shown to clients on the listing.
  Future<Psychologist> uploadPhoto(List<int> bytes, String fileName);

  /// A verification document (PDF or photo) — goes "under review".
  Future<Psychologist> uploadDocument(
    String documentName,
    List<int> bytes,
    String fileName,
  );

  /// A message to the partner-support team; returns its reference number.
  Future<String> contactSupport(String message, {String category});
  Future<PractitionerSettings> fetchSettings();
  Future<PractitionerSettings> saveSettings(PractitionerSettings settings);

  // ---- Sessions ------------------------------------------------------------
  Future<List<Session>> fetchSessions();
  Future<void> cancelSession(String sessionId, String reason);
  Future<void> requestReschedule(String sessionId);
  Future<void> saveSessionNotes(String sessionId, String notes);

  /// Opens a booked session (allowed from 15 minutes before it starts).
  Future<ConsultationRoom> startSession(String sessionId);

  /// Ends a live session. Returns what the psychologist earned for it.
  Future<double> completeSession(
    String sessionId, {
    required Duration duration,
    String? privateNote,
  });

  // ---- Availability --------------------------------------------------------
  Future<Map<DateTime, List<AvailabilitySlot>>> fetchAvailability();
  Future<Map<DateTime, List<AvailabilitySlot>>> saveAvailability(
    Map<DateTime, List<AvailabilitySlot>> slots,
  );

  // ---- Talk Now ------------------------------------------------------------
  Future<PresenceSnapshot> fetchPresence();
  Future<PresenceSnapshot> setPresence({
    PresenceStatus? status,
    bool? acceptTalkNow,
  });

  /// The next client waiting to talk, or null. Polled while online.
  Future<TalkRequest?> nextTalkRequest();

  /// Accepts a request: the paid session opens straight away, with its chat
  /// thread or call credentials.
  Future<AcceptedTalk> acceptRequest(String requestId);
  Future<void> declineRequest(String requestId);

  // ---- Chat ----------------------------------------------------------------
  Future<ChatSnapshot> fetchChat(String sessionId);
  Future<ChatMessage> sendChatMessage(String sessionId, String text);

  // ---- People & money ------------------------------------------------------
  Future<List<Client>> fetchClients();
  Future<EarningsSummary> fetchEarningsSummary();
  Future<List<EarningTransaction>> fetchTransactions();
  Future<void> requestPayout();

  // ---- Notifications -------------------------------------------------------
  Future<List<AppNotification>> fetchNotifications();
  Future<void> markNotificationsRead(Iterable<String> ids);
  Future<void> markAllNotificationsRead();

  // ---- Videos --------------------------------------------------------------
  /// The videos the Misty Minds team has switched on for this app.
  Future<List<GuideVideo>> fetchGuideVideos();

  /// Records that the video was seen. [completed] is false when an optional
  /// video was skipped. Returns the video as the server now sees it.
  Future<GuideVideo> markGuideVideoWatched(
    String videoId, {
    bool completed = true,
  });
}
