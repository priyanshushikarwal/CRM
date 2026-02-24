import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/application_model.dart';
import '../../providers/app_providers.dart';

class ApplicationsListScreen extends ConsumerStatefulWidget {
  const ApplicationsListScreen({super.key});

  @override
  ConsumerState<ApplicationsListScreen> createState() =>
      _ApplicationsListScreenState();
}

class _ApplicationsListScreenState
    extends ConsumerState<ApplicationsListScreen> {
  final _searchController = TextEditingController();
  ApplicationStatus? _selectedStatus;
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(applicationsProvider.notifier).loadApplications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationsState = ref.watch(applicationsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.when(
      data: (user) => user,
      loading: () => null,
      error: (_, __) => null,
    );
    final bool canEdit = currentUser?.canEdit ?? false;
    final bool canDelete = currentUser?.canDelete ?? false;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Applications', style: AppTextStyles.heading2),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Total Applications: ${applicationsState.stats['total'] ?? 0}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Export buttons
                  if (!isMobile) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement export
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentColor,
                        side: const BorderSide(color: AppTheme.accentColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement MIS export
                      },
                      icon: const Icon(Icons.table_chart_rounded, size: 18),
                      label: const Text('MIS Export'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Add button - only visible to users who can edit
                  if (canEdit)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/applications/add'),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(isMobile ? 'Add' : 'Add Application'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Filters section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search by application number, name, mobile...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(applicationsProvider.notifier)
                                          .setSearchQuery('');
                                    },
                                  )
                                  : null,
                        ),
                        onChanged: (value) {
                          ref
                              .read(applicationsProvider.notifier)
                              .setSearchQuery(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status filter
                    if (!isMobile) ...[
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<ApplicationStatus?>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.filter_list_rounded),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Statuses'),
                            ),
                            ...ApplicationStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(_getStatusDisplayName(status)),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStatus = value);
                            ref
                                .read(applicationsProvider.notifier)
                                .setStatusFilter(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // State filter
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String?>(
                          value: _selectedState,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All States'),
                            ),
                            ...AppConstants.indianStates.map((state) {
                              return DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedState = value);
                            ref
                                .read(applicationsProvider.notifier)
                                .setStateFilter(value);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    // Filter button
                    OutlinedButton.icon(
                      onPressed: () {
                        _showFilterDialog(context);
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Filter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Applications table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child:
                  applicationsState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : applicationsState.applications.isEmpty
                      ? _buildEmptyState()
                      : _buildApplicationsTable(
                        applicationsState.applications,
                        isMobile,
                        canEdit,
                        canDelete,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: AppTheme.textLight.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'No applications found',
              style: AppTextStyles.heading3.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/applications/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Application'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsTable(
    List<ApplicationModel> applications,
    bool isMobile,
    bool canEdit,
    bool canDelete,
  ) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Application Number',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isMobile) ...[
                Expanded(
                  flex: 2,
                  child: Text(
                    'Consumer Name',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Mobile',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Capacity (kWp)',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  'Status',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 100, child: Text('Action')),
            ],
          ),
        ),
        // Table body
        Expanded(
          child: ListView.separated(
            itemCount: applications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final app = applications[index];
              return _buildApplicationRow(app, isMobile, canEdit, canDelete);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationRow(
    ApplicationModel app,
    bool isMobile,
    bool canEdit,
    bool canDelete,
  ) {
    return InkWell(
      onTap: () => context.go('/applications/${app.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.applicationNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 4),
                    Text(app.fullName, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            if (!isMobile) ...[
              Expanded(
                flex: 2,
                child: Text(
                  app.fullName,
                  style: AppTextStyles.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(app.mobile, style: AppTextStyles.bodyMedium),
              ),
              Expanded(
                child: Text(
                  app.proposedCapacity.toStringAsFixed(3),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(app.currentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  app.statusDisplayName,
                  style: AppTextStyles.caption.copyWith(
                    color: _getStatusColor(app.currentStatus),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          context.go('/applications/${app.id}');
                          break;
                        case 'edit':
                          context.go('/applications/${app.id}/edit');
                          break;
                        case 'track':
                          _showTrackingDialog(context, app);
                          break;
                        case 'delete':
                          _confirmDelete(context, app);
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_rounded, size: 18),
                                SizedBox(width: 12),
                                Text('View Application'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'track',
                            child: Row(
                              children: [
                                Icon(Icons.track_changes_rounded, size: 18),
                                SizedBox(width: 12),
                                Text('Track Application'),
                              ],
                            ),
                          ),
                          if (canEdit)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 12),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (canDelete) ...[
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Applications'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ApplicationStatus?>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...ApplicationStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusDisplayName(status)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedState,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All States'),
                    ),
                    ...AppConstants.indianStates.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedState = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedState = null;
                  });
                  ref.read(applicationsProvider.notifier).clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(applicationsProvider.notifier)
                      .setStatusFilter(_selectedStatus);
                  ref
                      .read(applicationsProvider.notifier)
                      .setStateFilter(_selectedState);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  void _showTrackingDialog(BuildContext context, ApplicationModel app) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Track Application', style: AppTextStyles.heading3),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#${app.applicationNumber}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Progress tracker
                  ...ApplicationStatus.values.asMap().entries.map((entry) {
                    final index = entry.key;
                    final status = entry.value;
                    final isCompleted = app.statusIndex > index;
                    final isCurrent = app.statusIndex == index;

                    return _buildTrackingStep(
                      _getStatusDisplayName(status),
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isLast: index == ApplicationStatus.values.length - 1,
                    );
                  }),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTrackingStep(
    String title, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? AppTheme.successColor
                        : isCurrent
                        ? AppTheme.statusInProgress
                        : AppTheme.borderColor,
                shape: BoxShape.circle,
              ),
              child:
                  isCompleted
                      ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                      : isCurrent
                      ? const Icon(
                        Icons.more_horiz_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color:
                    isCompleted ? AppTheme.successColor : AppTheme.borderColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color:
                    isCompleted || isCurrent
                        ? AppTheme.textPrimary
                        : AppTheme.textLight,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ApplicationModel app,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Application'),
            content: Text(
              'Are you sure you want to delete application ${app.applicationNumber}? This action cannot be undone.',
            ),
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
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await ref.read(applicationsProvider.notifier).deleteApplication(app.id);
    }
  }

  String _getStatusDisplayName(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.consumerRegistration:
        return 'Consumer Registration';
      case ApplicationStatus.consumerApplication:
        return 'Consumer Application';
      case ApplicationStatus.discomFeasibility:
        return 'Discom Feasibility';
      case ApplicationStatus.consumerVendorSelection:
        return 'Vendor Selection';
      case ApplicationStatus.vendorUploadAgreement:
        return 'Upload Agreement';
      case ApplicationStatus.vendorInstallation:
        return 'Installation';
      case ApplicationStatus.discomInspection:
        return 'Inspection';
      case ApplicationStatus.projectCommissioning:
        return 'Project Commissioning';
      case ApplicationStatus.consumerSubsidyRequest:
        return 'Subsidy Request';
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.consumerRegistration:
      case ApplicationStatus.consumerApplication:
        return AppTheme.statusPending;
      case ApplicationStatus.discomFeasibility:
      case ApplicationStatus.consumerVendorSelection:
      case ApplicationStatus.vendorUploadAgreement:
        return AppTheme.statusInProgress;
      case ApplicationStatus.vendorInstallation:
      case ApplicationStatus.discomInspection:
      case ApplicationStatus.projectCommissioning:
        return AppTheme.warningColor;
      case ApplicationStatus.consumerSubsidyRequest:
        return AppTheme.statusCompleted;
    }
  }
}
