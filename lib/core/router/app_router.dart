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
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/installations/installations_list_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/reports/payments_list_screen.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';

class DemoSession {
  DemoSession._();
  static bool _active = false;
  static bool get isActive => _active;
  static void start() => _active = true;
  static void end() => _active = false;
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

bool _matchesAllowedRoute(String location, List<String> allowedPrefixes) {
  return allowedPrefixes.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );
}

Future<UserModel?> _getCurrentUserAccess() async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  try {
    final response = await SupabaseService.from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  } catch (_) {
    return null;
  }
}

String _defaultRouteForUser(UserModel? user) {
  if (user == null) return '/applications';
  if (user.canViewDashboard) return '/dashboard';
  if (user.canAccessApplications) return '/applications';
  if (user.canAccessPayments) return '/payments';
  if (user.canAccessInventory) {
    return '/inventory';
  }
  return '/login';
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final isLoggedIn = SupabaseService.isLoggedIn || DemoSession.isActive;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    final isSplash = state.matchedLocation == '/';

    if (isSplash) return null;

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    if (DemoSession.isActive) {
      if (isLoggedIn && isAuthRoute) {
        return '/applications';
      }
      return null;
    }

    final user = await _getCurrentUserAccess();
    final defaultRoute = _defaultRouteForUser(user);

    final hasAnyModuleAccess =
        user == null ||
        user.isAdmin ||
        user.canAccessApplications ||
        user.canAccessPayments ||
        user.canAccessInventory;

    if (isLoggedIn && isAuthRoute) {
      if (!hasAnyModuleAccess) {
        return null;
      }
      return defaultRoute;
    }

    if (user == null || user.isAdmin) {
      return null;
    }

    final allowedRoutes = <String>[];
    if (user.canAccessApplications) {
      allowedRoutes.add('/applications');
    }
    if (user.canAccessPayments) {
      allowedRoutes.add('/payments');
    }
    if (user.canAccessInventory) {
      allowedRoutes.add('/inventory');
    }

    if (allowedRoutes.isEmpty) {
      return '/login';
    }

    if (!_matchesAllowedRoute(state.matchedLocation, allowedRoutes)) {
      return defaultRoute;
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
          path: '/inventory',
          name: 'inventory',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: InventoryScreen()),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          pageBuilder:
              (context, state) => const NoTransitionPage(
                child: ReportsScreen(),
              ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
        ),
        GoRoute(
          path: '/installations',
          name: 'installations',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: InstallationsListScreen()),
        ),
        GoRoute(
          path: '/payments',
          name: 'payments',
          pageBuilder:
              (context, state) =>
                  const NoTransitionPage(child: PaymentsListScreen()),
        ),
      ],
    ),
  ],
);
