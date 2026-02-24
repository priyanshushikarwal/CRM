import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardScreen({super.key, required this.child});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Load applications on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(applicationsProvider.notifier).loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar (Desktop only)
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isCollapsed ? 80 : 260,
              child: _buildSidebar(context, _isCollapsed),
            ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isDesktop, isMobile),
                Expanded(
                  child: Container(
                    color: AppTheme.backgroundColor,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: !isDesktop ? Drawer(child: _buildSidebar(context, false)) : null,
    );
  }

  Widget _buildSidebar(BuildContext context, bool isCollapsed) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo section
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 16 : 24,
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.solar_power_rounded,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DoonInfra',
                          style: AppTextStyles.heading4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Solar Manager',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Navigation items
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final currentUserAsync = ref.watch(currentUserProvider);
                final currentUser = currentUserAsync.when(
                  data: (user) => user,
                  loading: () => null,
                  error: (_, __) => null,
                );
                final canManageUsers = currentUser?.canManageUsers ?? false;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildNavItem(
                        context,
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        route: '/dashboard',
                        isActive: currentLocation == '/dashboard',
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        icon: Icons.description_rounded,
                        label: 'Applications',
                        route: '/applications',
                        isActive: currentLocation.startsWith('/applications'),
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 8),
                      // Pending Approvals - only visible to admins and superadmins
                      if (canManageUsers) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.pending_actions_rounded,
                          label: 'Pending Approvals',
                          route: '/pending-approvals',
                          isActive: currentLocation == '/pending-approvals',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          icon: Icons.people_rounded,
                          label: 'Users',
                          route: '/users',
                          isActive: currentLocation == '/users',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildNavItem(
                        context,
                        icon: Icons.inventory_2_rounded,
                        label: 'Inventory',
                        route: '/inventory',
                        isActive: currentLocation == '/inventory',
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        icon: Icons.bar_chart_rounded,
                        label: 'Reports',
                        route: '/reports',
                        isActive: currentLocation == '/reports',
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        route: '/settings',
                        isActive: currentLocation == '/settings',
                        isCollapsed: isCollapsed,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Collapse button
          if (MediaQuery.of(context).size.width > 900)
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Collapse',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          // User section
          Consumer(
            builder: (context, ref, child) {
              final currentUserAsync = ref.watch(currentUserProvider);
              final currentUser = currentUserAsync.when(
                data: (user) => user,
                loading: () => null,
                error: (_, __) => null,
              );

              return Container(
                padding: EdgeInsets.all(isCollapsed ? 12 : 16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isCollapsed ? 18 : 20,
                      backgroundColor: _getRoleColor(currentUser?.role),
                      child: Text(
                        currentUser?.displayName[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.displayName ?? 'User',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentUser?.roleDisplayName ?? 'Loading...',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                        onPressed: () => _handleLogout(context),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.superadmin:
        return Colors.purple;
      case UserRole.admin:
        return AppTheme.errorColor;
      case UserRole.vendor:
        return AppTheme.successColor;
      case UserRole.operator:
        return AppTheme.warningColor;
      case UserRole.viewer:
        return AppTheme.accentColor;
      case null:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    required bool isCollapsed,
  }) {
    return Tooltip(
      message: isCollapsed ? label : '',
      child: InkWell(
        onTap: () {
          if (!isActive) {
            context.go(route);
          }
          // Close drawer on mobile
          if (MediaQuery.of(context).size.width < 900) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 16 : 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border:
                isActive
                    ? Border.all(color: Colors.white.withOpacity(0.3))
                    : null,
          ),
          child: Row(
            mainAxisAlignment:
                isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                size: 22,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop, bool isMobile) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    String title = 'Dashboard';

    if (currentLocation.startsWith('/applications')) {
      title = 'Applications';
    } else if (currentLocation == '/inventory') {
      title = 'Solar Panel Inventory';
    } else if (currentLocation == '/reports') {
      title = 'Reports';
    } else if (currentLocation == '/settings') {
      title = 'Settings';
    } else if (currentLocation == '/users') {
      title = 'User Management';
    } else if (currentLocation == '/pending-approvals') {
      title = 'Pending Approvals';
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu button (mobile/tablet)
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          // Title
          if (!isMobile)
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          const Spacer(),
          // Search button
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: AppTheme.textSecondary,
            onPressed: () {
              // TODO: Implement global search
            },
          ),
          const SizedBox(width: 8),
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppTheme.textSecondary,
                onPressed: () {
                  // TODO: Implement notifications
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Container(width: 1, height: 32, color: AppTheme.borderColor),
            const SizedBox(width: 16),
            // Company badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.business_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.companyName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      // Invalidate the current user provider to clear cached data
      ref.invalidate(currentUserProvider);
      await SupabaseService.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

// Dashboard Overview Widget
class DashboardOverviewContent extends ConsumerWidget {
  const DashboardOverviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsState = ref.watch(applicationsProvider);
    final stats = applicationsState.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back! 👋',
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Here\'s an overview of your solar installation applications.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/applications/add'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New Application'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.solar_power_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Applications',
                    '${stats['total'] ?? 0}',
                    Icons.description_rounded,
                    AppTheme.primaryColor,
                    '+12% this month',
                  ),
                  _buildStatCard(
                    'In Progress',
                    '${stats['inProgress'] ?? 0}',
                    Icons.pending_actions_rounded,
                    AppTheme.statusInProgress,
                    'Active applications',
                  ),
                  _buildStatCard(
                    'Completed',
                    '${stats['completed'] ?? 0}',
                    Icons.check_circle_rounded,
                    AppTheme.statusCompleted,
                    'Successfully installed',
                  ),
                  _buildStatCard(
                    'Pending',
                    '${stats['pending'] ?? 0}',
                    Icons.hourglass_empty_rounded,
                    AppTheme.warningColor,
                    'Awaiting action',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Recent applications section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Applications', style: AppTextStyles.heading3),
              TextButton.icon(
                onPressed: () => context.go('/applications'),
                icon: const Text('View All'),
                label: const Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (applicationsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (applicationsState.applications.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: AppTheme.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: AppTextStyles.heading4.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first application to get started',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/applications/add'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Application'),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: applicationsState.applications.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final app = applicationsState.applications[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      app.applicationNumber,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${app.fullName} • ${app.district}',
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          app.currentStatus,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        app.statusDisplayName,
                        style: AppTextStyles.caption.copyWith(
                          color: _getStatusColor(app.currentStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () => context.go('/applications/${app.id}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: AppTheme.textLight,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    // Simple mapping for status colors
    return AppTheme.statusInProgress;
  }
}
