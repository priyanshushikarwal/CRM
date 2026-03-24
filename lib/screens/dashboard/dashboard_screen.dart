import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/application_model.dart';
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
  bool _isGlobalRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = await ref.read(currentUserProvider.future);
      if (!mounted || currentUser == null) return;
      if (currentUser.canAccessApplications || currentUser.canViewDashboard) {
        ref.read(applicationsProvider.notifier).loadApplications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isCollapsed ? 80 : 260,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppTheme.borderColor)),
              ),
              child: _buildSidebar(context, _isCollapsed),
            ),
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: Column(
                children: [
                  _buildTopBar(context, isDesktop, size.width < 600),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
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
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 100,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 24,
              vertical: 24,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'DoonInfra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final currentUserAsync = ref.watch(currentUserProvider);
                final currentUser = currentUserAsync.when(
                  data: (user) => user,
                  loading: () => null,
                  error: (_, __) => null,
                );
                final canAccessApplications =
                    currentUser?.canAccessApplications ?? false;
                final canAccessPayments =
                    currentUser?.canAccessPayments ?? false;
                final canManageUsers = currentUser?.canManageUsers ?? false;
                final canViewDashboard = currentUser?.canViewDashboard ?? false;
                final canManageInstallations = currentUser?.canManageInstallations ?? false;
                final canAccessInventory =
                    currentUser?.canAccessInventory ?? false;
                final isAdmin = currentUser?.isAdmin ?? false;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (canViewDashboard) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.grid_view_rounded,
                          label: 'Dashboard',
                          route: '/dashboard',
                          isActive: currentLocation == '/dashboard',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (canAccessApplications) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.layers_rounded,
                          label: 'Applications',
                          route: '/applications',
                          isActive: currentLocation.startsWith('/applications'),
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (canManageInstallations) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.settings_input_component_rounded,
                          label: 'Installations',
                          route: '/installations',
                          isActive: currentLocation == '/installations',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (canAccessPayments) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.receipt_long_rounded,
                          label: 'Payments',
                          route: '/payments',
                          isActive: currentLocation == '/payments',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (canManageUsers) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.verified_user_rounded,
                          label: 'Approvals',
                          route: '/pending-approvals',
                          isActive: currentLocation == '/pending-approvals',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                        _buildNavItem(
                          context,
                          icon: Icons.group_rounded,
                          label: 'Users',
                          route: '/users',
                          isActive: currentLocation == '/users',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (canAccessInventory) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.inventory_2_rounded,
                          label: 'Inventory',
                          route: '/inventory',
                          isActive: currentLocation == '/inventory',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (canViewDashboard) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.analytics_rounded,
                          label: 'Reports',
                          route: '/reports',
                          isActive: currentLocation == '/reports',
                          isCollapsed: isCollapsed,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (isAdmin) ...[
                        _buildNavItem(
                          context,
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          route: '/settings',
                          isActive: currentLocation == '/settings',
                          isCollapsed: isCollapsed,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider).value;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () => _handleLogout(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentUser?.displayName ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  currentUser?.roleDisplayName ?? 'Role',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.logout_rounded, size: 16, color: AppTheme.textSecondary),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppTheme.textSecondary,
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
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
      title = 'Inventory & Factory Management';
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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: AppTheme.backgroundColor,
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 20),
            color: AppTheme.textSecondary,
            onPressed: () {},
          ),
          IconButton(
            icon:
                _isGlobalRefreshing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.sync_rounded, size: 20),
            color: AppTheme.textSecondary,
            tooltip: 'Refresh all data',
            onPressed: _isGlobalRefreshing ? null : () => _handleGlobalRefresh(context),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                color: AppTheme.textSecondary,
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  AppConstants.companyName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
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
      ref.invalidate(currentUserProvider);
      await SupabaseService.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _handleGlobalRefresh(BuildContext context) async {
    setState(() => _isGlobalRefreshing = true);

    try {
      await ref.read(globalRefreshProvider)();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data synced successfully.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGlobalRefreshing = false);
      }
    }
  }
}

class DashboardOverviewContent extends ConsumerWidget {
  const DashboardOverviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsState = ref.watch(applicationsProvider);
    final stats = applicationsState.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1.0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Welcome back! Here is what is happening today.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/applications/add'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New Application'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100 ? 5 : (constraints.maxWidth > 800 ? 3 : 2);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard('Total Projects', '${stats['total'] ?? 0}', Icons.folder_open_rounded, Colors.blue),
                  _buildStatCard('Active Clients', '${stats['pending'] ?? 0}', Icons.people_outline_rounded, Colors.teal),
                  _buildStatCard('Installations', '${stats['completedInstallations'] ?? 0}', Icons.done_all_rounded, Colors.indigo),
                  _buildStatCard(
                    'Domestic kW',
                    '${(stats['domesticKw'] ?? 0.0).toStringAsFixed(1)}',
                    Icons.home_work_outlined,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Commercial kW',
                    '${(stats['commercialKw'] ?? 0.0).toStringAsFixed(1)}',
                    Icons.business_outlined,
                    Colors.purple,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildRecentSection(context, applicationsState),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildPerformanceCard(),
                    const SizedBox(height: 24),
                    _buildPendingTasksCard(stats),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '+2.4% ↑',
                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context, ApplicationsState state) {
    final approvedApplications =
        state.applications
            .where((app) => app.approvalStatus == ApprovalStatus.approved)
            .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              TextButton(onPressed: () => context.go('/applications'), child: const Text('View all →')),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1),
              },
              children: [
                _buildTableHeader(),
                ...approvedApplications.take(5).map(
                  (app) => _buildTableRow(context, app),
                ),
              ],
            ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return const TableRow(
      children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Client', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Capacity', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Location', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Status', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, ApplicationModel app) {
    return TableRow(
      children: [
        InkWell(
          onTap: () => context.go('/applications/${app.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: Text(app.fullName[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(child: Text(app.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('${app.proposedCapacity} kW', style: const TextStyle(fontSize: 13))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(app.district, style: const TextStyle(fontSize: 13))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(app.currentStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              app.currentStatus.name.split('.').last.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trim().toUpperCase(),
              style: TextStyle(fontSize: 10, color: _getStatusColor(app.currentStatus), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target Achieved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.more_horiz, size: 16)),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(value: 0.88, strokeWidth: 12, backgroundColor: AppTheme.backgroundColor, color: AppTheme.primaryColor, strokeCap: StrokeCap.round),
                ),
                const Column(
                  children: [
                    Text('88%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    Text('Success Rate', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildPerformanceItem('Installations Done', '24/30', Colors.green),
          _buildPerformanceItem('Customer Reviews', '4.8/5.0', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPendingTasksCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Critical Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              TextButton(onPressed: () {}, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaskItem('Verify Documents', '3 Pending', Colors.red),
          _buildTaskItem('Site Surveys', '8 Schedule', Colors.orange),
          _buildTaskItem('Pending Payments', 'Rs. 4.5L', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.assignment_turned_in_rounded, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applicationReceived:
        return AppTheme.textLight;
      case ApplicationStatus.subsidyProcess:
        return Colors.blue;
      case ApplicationStatus.installationCompleted:
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }
}
