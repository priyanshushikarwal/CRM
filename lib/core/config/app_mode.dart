import '../../models/user_model.dart';

enum AppMode { full, inventoryOnly }

class AppModeConfig {
  AppModeConfig._();

  static AppMode _current = AppMode.full;

  static AppMode get current => _current;

  static bool get isInventoryOnly => _current == AppMode.inventoryOnly;

  static void setMode(AppMode mode) {
    _current = mode;
  }

  static String get appName =>
      isInventoryOnly ? 'DoonInfra Inventory' : 'DoonInfra Solar Manager';

  static String get appHeadline =>
      isInventoryOnly ? 'DoonInfra\nInventory' : 'DoonInfra\nSolar Manager';

  static String get appSubtitle => isInventoryOnly
      ? 'Sign in to manage stock, scan barcodes, and update inventory in real time.'
      : 'Manage your solar rooftop applications\nefficiently with our comprehensive solution.';

  static String get loginSubtitle => isInventoryOnly
      ? 'Sign in to continue with inventory operations'
      : 'Sign in to continue managing your applications';

  static String defaultRouteForUser(UserModel? user) {
    if (user == null) {
      return isInventoryOnly ? '/login' : '/applications';
    }
    if (isInventoryOnly) {
      return user.canAccessInventory ? '/inventory' : '/login';
    }
    if (user.canViewDashboard) return '/dashboard';
    if (user.canAccessApplications) return '/applications';
    if (user.canAccessPayments) return '/payments';
    if (user.canAccessInventory) return '/inventory';
    return '/login';
  }

  static bool hasAnyModuleAccess(UserModel? user) {
    if (user == null) return true;
    if (isInventoryOnly) return user.canAccessInventory;
    return user.isAdmin ||
        user.canAccessApplications ||
        user.canAccessPayments ||
        user.canAccessInventory;
  }

  static List<String> allowedRoutesForUser(UserModel user) {
    if (isInventoryOnly) {
      return user.canAccessInventory ? ['/inventory'] : const [];
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
    if (user.canViewDashboard) {
      allowedRoutes.add('/dashboard');
      allowedRoutes.add('/reports');
    }
    if (user.canManageUsers) {
      allowedRoutes.add('/users');
      allowedRoutes.add('/pending-approvals');
    }
    if (user.canManageInstallations) {
      allowedRoutes.add('/installations');
    }
    if (user.isAdmin) {
      allowedRoutes.add('/settings');
    }
    return allowedRoutes;
  }
}
