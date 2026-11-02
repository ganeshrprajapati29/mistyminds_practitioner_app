/// User-facing copy for the reference screens and shared UI.
///
/// Wording on the reference screens is reproduced exactly — change it here,
/// never in a widget.
abstract final class AppStrings {
  static const String appName = 'Misty Minds';
  static const String appTitle = 'MistyMinds: Practitioner';
  static const String tagline = 'Where the Mist Clears, Healing Begins.';

  /// The splash screen carries the same words as the MistyMinds client app's
  /// splash (its AppStrings.tagline and scriptGoodThings), so both apps open
  /// with one voice.
  static const String splashTagline = tagline;
  static const String splashScript = 'Good Things\nTake Time';
  static const String partnerLine = 'Partner app for psychologists';

  // ---- Welcome -------------------------------------------------------------
  static const String welcomeTitle = 'Healing\nhappens together.';
  static const String welcomeSubtitle =
      'Thank you for being here.\nYour presence creates change.';
  static const String loginAsPsychologist = 'Login as a Psychologist';
  static const String newHere = 'New here?';
  static const String applyToJoin = 'Apply to Join as a Psychologist';

  // ---- Auth ----------------------------------------------------------------
  static const String loginTitle = 'Welcome back.';
  static const String loginSubtitle =
      'Log in to continue supporting your clients.';
  static const String emailOrMobile = 'Email / Mobile Number';
  static const String emailOrMobileHint = 'you@example.com or 98XXXXXXXX';
  static const String password = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String forgotPassword = 'Forgot Password?';
  static const String login = 'Login';
  static const String notPartnerYet = 'Not a Misty Minds partner yet?';
  static const String applyToJoinShort = 'Apply to Join';

  // ---- Home ----------------------------------------------------------------
  static const String viewProfile = 'View Profile';
  static const String currentlyOffline = 'Currently Offline';
  static const String offlineHint =
      'Go online when you’re ready to receive clients.';
  static const String youreOnline = 'You’re Online';
  static const String onlineHint = 'You’re visible to clients right now.';
  static const String availabilityPaused = 'Availability Paused';
  static const String pausedHint = 'Clients can’t reach you until you resume.';
  static const String goOnlineNow = 'Go Online Now';
  static const String viewTalkNowStatus = 'View Talk Now Status';
  static const String setAvailability = 'Set Availability';
  static const String setAvailabilityHint = 'Block your time slots';
  static const String talkNow = 'Talk Now';
  static const String talkNowHint = 'Appear for instant client requests';
  static const String upcomingSessions = 'Upcoming Sessions';
  static const String earnings = 'Earnings';
  static const String thisMonth = 'this month';
  static const String homeQuote = 'You create a safer,\nkinder world.';

  // ---- Availability --------------------------------------------------------
  static const String help = 'Help';
  static const String setYourAvailability = 'Set Your Availability';
  static const String availabilitySubtitle =
      'Select the dates and time slots you want to be available. '
      'Minimum 2 hours per day.';
  static const String calendarView = 'Calendar View';
  static const String listView = 'List View';
  static const String legendSelected = 'Selected';
  static const String legendPartial = 'Partially booked';
  static const String legendAvailable = 'Has availability';
  static const String addTimeSlot = 'Add Time Slot';
  static const String saveAvailability = 'Save Availability';

  // ---- Talk Now ------------------------------------------------------------
  static const String readyTitle = 'Ready when you are.';
  static const String readySubtitle =
      'You’re making space for someone\nwho might need it.';
  static const String goOnline = 'Go Online';
  static const String goOnlineHint =
      'You’ll appear to clients who select\n“Talk to someone now”.';
  static const String remainingToday = 'remaining today';
  static const String todaysWindow = 'Today’s window';
  static const String acceptTalkNow = 'Accept Talk Now requests';
  static const String acceptTalkNowHint =
      'Clients can send you requests during your availability.';
  static const String keepAppOpen =
      'Keep the app open to stay visible.\n'
      'You can pause or end availability anytime.';
  static const String imOnlineNow = 'I’m Online Now';
  static const String remainingInSlot = 'remaining in your slot';
  static const String endsAt = 'Ends at';
  static const String waitingTitle = 'Waiting for a request...';
  static const String waitingSubtitle =
      'You’ll be notified when a client\nwants to talk.';
  static const String pauseAvailability = 'Pause Availability';
  static const String resumeAvailability = 'Resume Availability';
  static const String endSession = 'End Session';
  static const String waitTip =
      'You can do other work while you wait.\nWe’ll notify you instantly.';
  static const String newRequest = 'New Request';
  static const String someoneNeedsToTalk = 'Someone needs\nto talk.';
  static const String clientLooking =
      'A client is looking for support\nright now.';
  static const String preferredMode = 'Preferred mode';
  static const String expectedDuration = 'Expected duration';
  static const String client = 'Client';
  static const String anonymous = 'Anonymous';
  static const String acceptRequest = 'Accept Request';
  static const String notNow = 'Not now';
  static const String declineNote =
      'If you decline, you won’t be shown to this client again, '
      'but you’ll remain online.';

  // ---- Misc ----------------------------------------------------------------
  static const String privacyNote =
      'Client identities are protected. Only what a client chooses to share '
      'is shown to you.';
}
