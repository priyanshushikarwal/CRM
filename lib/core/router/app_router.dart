import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/applications/applications_list_screen.dart';
import '../../screens/applications/application_details_screen.dart';
import '../../screens/applications/add_application_screen.dart';
import '../../screens/applications/pending_approvals_screen.dart';
import '../../screens/users/user_management_screen.dart';
import '../../services/supabase_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = SupabaseService.isLoggedIn;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    final isSplash = state.matchedLocation == '/';

    if (isSplash) return null;

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    if (isLoggedIn && isAuthRoute) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: DashboardOverviewContent()),
        ),
        GoRoute(
          path: '/applications',
          name: 'applications',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: ApplicationsListScreen()),
          routes: [
            GoRoute(
              path: 'add',
              name: 'add-application',
              builder: (context, state) => const AddApplicationScreen(),
            ),
            GoRoute(
              path: ':id',
              name: 'application-details',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ApplicationDetailsScreen(applicationId: id);
              },
            ),
            GoRoute(
              path: ':id/edit',
              name: 'edit-application',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AddApplicationScreen(applicationId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/users',
          name: 'users',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: UserManagementScreen()),
        ),
        GoRoute(
          path: '/pending-approvals',
          name: 'pending-approvals',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: PendingApprovalsScreen()),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          pageBuilder:
              (context, state) => NoTransitionPage(
                child: Center(
                  child: Text(
                    'Reports Coming Soon',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder:
              (context, state) => NoTransitionPage(
                child: Center(
                  child: Text(
                    'Settings Coming Soon',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
        ),
      ],
    ),
  ],
);
