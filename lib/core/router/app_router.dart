import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/announcements/presentation/pages/announcements_page.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/polls/presentation/pages/polls_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../injection.dart';
import '../animations/page_transitions.dart';
import '../widgets/placeholder_page.dart';
import '../widgets/splash_page.dart';
import 'app_shell.dart';

/// Named route paths, kept in one place so screens navigate type-safely
/// (`context.go(AppRoutes.events)`).
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const chat = '/chat';
  static const events = '/events';
  static const notices = '/notices';
  static const profile = '/profile';
  static const adminDashboard = '/admin';

  // Stack routes (pushed over the shell).
  static const onboarding = '/welcome';
  static const login = '/login';
  static const announcements = '/announcements';
  static const polls = '/polls';
  static const notifications = '/notifications';
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// The application router.
///
/// A [StatefulShellRoute] hosts the five bottom-tab branches (each keeps its
/// own navigation state). A [redirect] guard backed by [AuthBloc] gates the app
/// behind sign-in, and [refreshListenable] re-evaluates routes whenever the
/// session changes.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: _AuthRefresh(getIt<AuthBloc>().stream),
  redirect: _guard,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) =>
          buildFadeSlidePage(state: state, child: const LoginPage()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellKey,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.chat,
              builder: (context, state) => const PlaceholderPage(
                title: 'Chat',
                icon: LucideIcons.messageSquare,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.events,
              builder: (context, state) => const EventsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.notices,
              builder: (context, state) => const PlaceholderPage(
                title: 'Notices',
                icon: LucideIcons.fileText,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const PlaceholderPage(
                title: 'Profile',
                icon: LucideIcons.user,
              ),
            ),
          ],
        ),
        // Branch 5 — admin only (Dashboard). The shell shows its tab only for
        // admins, and the redirect guard keeps students out of `/admin`.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminDashboard,
              builder: (context, state) => const AdminDashboardPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.announcements,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) =>
          buildFadeSlidePage(state: state, child: const AnnouncementsPage()),
    ),
    GoRoute(
      path: AppRoutes.polls,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) =>
          buildFadeSlidePage(state: state, child: const PollsPage()),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => buildFadeSlidePage(
        state: state,
        child: const PlaceholderPage(
          title: 'Notifications',
          icon: LucideIcons.bell,
        ),
      ),
    ),
  ],
);

/// Auth-aware redirect: keeps unauthenticated users on `/login`, signed-in
/// users out of `/login` and the splash, and shows the splash while the initial
/// session check is pending.
String? _guard(BuildContext context, GoRouterState state) {
  final authState = getIt<AuthBloc>().state;
  final status = authState.status;
  final isAdmin = authState.isAdmin;
  final loc = state.matchedLocation;

  // Where a signed-in user belongs by default.
  final landing = isAdmin ? AppRoutes.adminDashboard : AppRoutes.home;

  switch (status) {
    case AuthStatus.unknown:
      return loc == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.unauthenticated:
      // Signed-out users may sit on onboarding or the login/sign-up screens;
      // anything else sends them to the branded onboarding entry.
      const allowed = {AppRoutes.onboarding, AppRoutes.login};
      return allowed.contains(loc) ? null : AppRoutes.onboarding;
    case AuthStatus.authenticated:
      // Coming from splash/login → send to the role's landing tab.
      if (loc == AppRoutes.login || loc == AppRoutes.splash) return landing;
      // Students may not access the admin dashboard.
      if (loc == AppRoutes.adminDashboard && !isAdmin) return AppRoutes.home;
      // Admins shouldn't sit on the student Home feed.
      if (loc == AppRoutes.home && isAdmin) return AppRoutes.adminDashboard;
      return null;
  }
}

/// Bridges the [AuthBloc] state stream to a [Listenable] so go_router refreshes
/// its redirect when the session changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
