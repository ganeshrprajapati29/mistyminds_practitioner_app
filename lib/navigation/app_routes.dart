import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/talk_request.dart';
import '../features/application/presentation/screens/application_flow_screen.dart';
import '../features/application/presentation/screens/application_submitted_screen.dart';
import '../features/application/presentation/screens/verification_pending_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/availability/presentation/screens/set_availability_screen.dart';
import '../features/clients/presentation/screens/client_details_screen.dart';
import '../features/clients/presentation/screens/clients_screen.dart';
import '../features/consultation/presentation/consultation_args.dart';
import '../features/consultation/presentation/screens/audio_consultation_screen.dart';
import '../features/consultation/presentation/screens/chat_consultation_screen.dart';
import '../features/consultation/presentation/screens/session_complete_screen.dart';
import '../features/consultation/presentation/screens/video_consultation_screen.dart';
import '../features/earnings/presentation/screens/earnings_screen.dart';
import '../features/earnings/presentation/screens/transactions_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/availability_preferences_screen.dart';
import '../features/profile/presentation/screens/documents_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/help_support_screen.dart';
import '../features/profile/presentation/screens/notification_settings_screen.dart';
import '../features/profile/presentation/screens/privacy_screen.dart';
import '../features/profile/presentation/screens/profile_info_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/sessions/presentation/screens/session_details_screen.dart';
import '../features/sessions/presentation/screens/sessions_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/talk_now/presentation/screens/go_online_screen.dart';
import '../features/talk_now/presentation/screens/incoming_request_screen.dart';
import '../features/talk_now/presentation/screens/online_waiting_screen.dart';
import '../features/talk_now/presentation/screens/request_accepted_screen.dart';
import '../features/welcome/presentation/screens/psychologist_welcome_screen.dart';
import 'main_navigation_screen.dart';

/// Every path in the app, in one place.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String resetPassword = '/reset-password';
  static const String apply = '/apply';
  static const String applicationSubmitted = '/apply/submitted';
  static const String verificationPending = '/apply/status';

  // Tab roots
  static const String home = '/home';
  static const String calendar = '/calendar';
  static const String clients = '/clients';
  static const String earnings = '/earnings';
  static const String profile = '/profile';

  // Home stack
  static const String notifications = '/home/notifications';
  static const String goOnline = '/home/go-online';
  static const String onlineWaiting = '/home/online';
  // Full screen, above everything — a request that arrives while a session
  // summary (or any other full-screen flow) is open must still be seen.
  static const String incomingRequest = '/request';
  static const String sessions = '/home/sessions';
  static String sessionDetails(String id) => '/home/sessions/$id';

  static String clientDetails(String id) => '/clients/$id';
  static const String transactions = '/earnings/transactions';

  // Profile stack
  static const String editProfile = '/profile/edit';
  static String profileInfo(ProfileSection s) => '/profile/info/${s.name}';
  static const String documents = '/profile/documents';
  static const String availabilityPreferences = '/profile/availability';
  static const String notificationSettings = '/profile/notification-settings';
  static const String privacy = '/profile/privacy';
  static const String help = '/profile/help';

  // Full-screen flows (above the tab bar)
  static const String requestAccepted = '/connecting';
  static const String chat = '/consult/chat';
  static const String audio = '/consult/audio';
  static const String video = '/consult/video';
  static const String sessionComplete = '/consult/complete';
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// Gentle fade + rise for screen changes — calm rather than showy.
CustomTransitionPage<void> _soft(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (_, Animation<double> a, _, Widget child) {
        final Animation<double> curved = CurvedAnimation(
          parent: a,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

GoRoute _page(
  String path,
  Widget Function(GoRouterState state) build, {
  List<RouteBase> routes = const <RouteBase>[],
  bool root = false,
  bool needsExtra = false,
}) => GoRoute(
  path: path,
  parentNavigatorKey: root ? _rootKey : null,
  // Screens fed through `extra` cannot be rebuilt from a bare URL (after a
  // restore, or a stale location); send those back to the dashboard.
  redirect: needsExtra
      ? (BuildContext context, GoRouterState state) =>
            state.extra == null ? AppRoutes.home : null
      : null,
  pageBuilder: (BuildContext context, GoRouterState state) =>
      _soft(state, build(state)),
  routes: routes,
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    _page(AppRoutes.splash, (_) => const SplashScreen()),
    _page(AppRoutes.welcome, (_) => const PsychologistWelcomeScreen()),
    _page(AppRoutes.login, (_) => const LoginScreen()),
    _page(AppRoutes.forgotPassword, (_) => const ForgotPasswordScreen()),
    _page(
      AppRoutes.otp,
      (GoRouterState s) =>
          OtpScreen(destination: s.uri.queryParameters['to'] ?? ''),
    ),
    _page(
      AppRoutes.resetPassword,
      (GoRouterState s) =>
          ResetPasswordScreen(identifier: s.uri.queryParameters['to'] ?? ''),
    ),
    _page(AppRoutes.apply, (_) => const ApplicationFlowScreen()),
    _page(
      AppRoutes.applicationSubmitted,
      (GoRouterState s) => ApplicationSubmittedScreen(
        reference: s.uri.queryParameters['ref'] ?? '',
      ),
    ),
    _page(
      AppRoutes.verificationPending,
      (GoRouterState s) => VerificationPendingScreen(
        reference: s.uri.queryParameters['ref'] ?? '',
      ),
    ),

    // ---- Tabs ----------------------------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (_, _, StatefulNavigationShell shell) =>
          MainNavigationScreen(shell: shell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            _page(
              AppRoutes.home,
              (_) => const HomeScreen(),
              routes: <RouteBase>[
                _page('notifications', (_) => const NotificationsScreen()),
                _page('go-online', (_) => const GoOnlineScreen()),
                _page('online', (_) => const OnlineWaitingScreen()),
                _page(
                  'sessions',
                  (GoRouterState s) => SessionsScreen(
                    initialTab:
                        int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0,
                  ),
                  routes: <RouteBase>[
                    _page(
                      ':id',
                      (GoRouterState s) => SessionDetailsScreen(
                        sessionId: s.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            _page(AppRoutes.calendar, (_) => const SetAvailabilityScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            _page(
              AppRoutes.clients,
              (_) => const ClientsScreen(),
              routes: <RouteBase>[
                _page(
                  ':id',
                  (GoRouterState s) =>
                      ClientDetailsScreen(clientId: s.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            _page(
              AppRoutes.earnings,
              (_) => const EarningsScreen(),
              routes: <RouteBase>[
                _page('transactions', (_) => const TransactionsScreen()),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            _page(
              AppRoutes.profile,
              (_) => const ProfileScreen(),
              routes: <RouteBase>[
                _page('edit', (_) => const EditProfileScreen()),
                _page(
                  'info/:section',
                  (GoRouterState s) => ProfileInfoScreen(
                    section: ProfileSection.values.byName(
                      s.pathParameters['section']!,
                    ),
                  ),
                ),
                _page('documents', (_) => const DocumentsScreen()),
                _page(
                  'availability',
                  (_) => const AvailabilityPreferencesScreen(),
                ),
                _page(
                  'notification-settings',
                  (_) => const NotificationSettingsScreen(),
                ),
                _page('privacy', (_) => const PrivacyScreen()),
                _page('help', (_) => const HelpSupportScreen()),
              ],
            ),
          ],
        ),
      ],
    ),

    // ---- Full-screen flows ---------------------------------------------------
    _page(
      AppRoutes.incomingRequest,
      (GoRouterState s) =>
          IncomingRequestScreen(request: s.extra! as TalkRequest),
      root: true,
      needsExtra: true,
    ),
    _page(
      AppRoutes.requestAccepted,
      (GoRouterState s) =>
          RequestAcceptedScreen(accepted: s.extra! as AcceptedTalk),
      root: true,
      needsExtra: true,
    ),
    _page(
      AppRoutes.chat,
      (GoRouterState s) =>
          ChatConsultationScreen(args: s.extra! as ConsultationArgs),
      root: true,
      needsExtra: true,
    ),
    _page(
      AppRoutes.audio,
      (GoRouterState s) =>
          AudioConsultationScreen(args: s.extra! as ConsultationArgs),
      root: true,
      needsExtra: true,
    ),
    _page(
      AppRoutes.video,
      (GoRouterState s) =>
          VideoConsultationScreen(args: s.extra! as ConsultationArgs),
      root: true,
      needsExtra: true,
    ),
    _page(
      AppRoutes.sessionComplete,
      (GoRouterState s) =>
          SessionCompleteScreen(summary: s.extra! as SessionSummary),
      root: true,
      needsExtra: true,
    ),
  ],
);

/// True while the psychologist is in a live consultation (or connecting to
/// one) — a new Talk Now request must not interrupt the person they're with.
bool get inLiveConsultation {
  try {
    final String top =
        appRouter.routerDelegate.currentConfiguration.last.matchedLocation;
    return const <String>{
      AppRoutes.requestAccepted,
      AppRoutes.chat,
      AppRoutes.audio,
      AppRoutes.video,
    }.contains(top);
  } catch (_) {
    return false; // nothing on the stack yet
  }
}
