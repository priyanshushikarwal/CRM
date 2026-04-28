import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/application_model.dart';
import '../../providers/app_providers.dart';

enum _StageProgressFilter { all, atStage, completed, pending }

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
  ApplicationStatus _selectedStageForInsights =
      ApplicationStatus.completeWorkDone;
  _StageProgressFilter _stageProgressFilter = _StageProgressFilter.atStage;

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

  Future<void> _refreshApplications() async {
    await ref.read(applicationsProvider.notifier).loadApplications();
    if (!mounted) return;
    final error = ref.read(applicationsProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Applications refreshed successfully.'
              : 'Refresh failed: $error',
        ),
        backgroundColor:
            error == null ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
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
    final bool canCreateApplication =
        currentUser?.canCreateApplication ?? false;
    final bool canEdit = currentUser?.canEdit ?? false;
    final bool canDelete = currentUser?.canDelete ?? false;
    final approvedApplications =
        applicationsState.applications
            .where((app) => app.approvalStatus == ApprovalStatus.approved)
            .toList();
    final pendingApplications =
        currentUser == null
            ? const <ApplicationModel>[]
            : applicationsState.applications
                .where(
                  (app) =>
                      app.submittedBy == currentUser.id &&
                      (app.approvalStatus == ApprovalStatus.pending ||
                          app.approvalStatus ==
                              ApprovalStatus.changesRequested),
                )
                .toList();
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final stageCompletedApplications =
        approvedApplications
            .where((app) => _isStageCompleted(app, _selectedStageForInsights))
            .toList();
    final stagePendingApplications =
        approvedApplications
            .where((app) => !_isStageCompleted(app, _selectedStageForInsights))
            .toList();
    final stageCompletedKw = stageCompletedApplications.fold<double>(
      0,
      (sum, app) => sum + app.proposedCapacity,
    );
    final stagePendingKw = stagePendingApplications.fold<double>(
      0,
      (sum, app) => sum + app.proposedCapacity,
    );

    List<ApplicationModel> stageFilteredApplications;
    switch (_stageProgressFilter) {
      case _StageProgressFilter.atStage:
        stageFilteredApplications =
            approvedApplications
                .where(
                  (app) => _isAtSelectedStage(app, _selectedStageForInsights),
                )
                .toList();
      case _StageProgressFilter.completed:
        stageFilteredApplications = stageCompletedApplications;
      case _StageProgressFilter.pending:
        stageFilteredApplications = stagePendingApplications;
      case _StageProgressFilter.all:
        stageFilteredApplications = approvedApplications;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Applications',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1.0,
                    ),
                  ),
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
                          'Total Applications: ${approvedApplications.length}',
                          style: const TextStyle(
                            fontSize: 12,
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
                  IconButton(
                    onPressed: _refreshApplications,
                    tooltip: 'Refresh Applications',
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isMobile) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        final apps = approvedApplications;
                        _exportToCSV(apps);
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        final apps = approvedApplications;
                        _exportToPDF(apps);
                      },
                      icon: const Icon(Icons.table_chart_rounded, size: 18),
                      label: const Text('MIS Export'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (canCreateApplication)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/applications/add'),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(isMobile ? 'Add' : 'New Application'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by number, name, mobile...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppTheme.backgroundColor.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged:
                        (value) => ref
                            .read(applicationsProvider.notifier)
                            .setSearchQuery(value),
                  ),
                ),
                const SizedBox(width: 16),
                if (!isMobile) ...[
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<ApplicationStatus?>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        prefixIcon: const Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        ...ApplicationStatus.values.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusDisplayName(status)),
                          ),
                        ),
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
                ],
                OutlinedButton.icon(
                  onPressed: () => _showFilterDialog(context),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('More Filters'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildStageInsightsPanel(
            totalConsumers: approvedApplications.length,
            completedConsumers: stageCompletedApplications.length,
            pendingConsumers: stagePendingApplications.length,
            completedKw: stageCompletedKw,
            pendingKw: stagePendingKw,
          ),

          const SizedBox(height: 32),
          if (pendingApplications.isNotEmpty) ...[
            _buildPendingSection(pendingApplications),
            const SizedBox(height: 24),
          ],

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  applicationsState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : stageFilteredApplications.isEmpty
                      ? _buildEmptyState(canCreateApplication)
                      : _buildApplicationsTable(
                        stageFilteredApplications,
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

  Widget _buildEmptyState(bool canCreateApplication) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            const Text(
              'No applications found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            if (canCreateApplication)
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

  Widget _buildStageInsightsPanel({
    required int totalConsumers,
    required int completedConsumers,
    required int pendingConsumers,
    required double completedKw,
    required double pendingKw,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<ApplicationStatus>(
                  value: _selectedStageForInsights,
                  decoration: const InputDecoration(
                    labelText: 'Stage-wise Filter',
                    prefixIcon: Icon(
                      Icons.stacked_line_chart_rounded,
                      size: 20,
                    ),
                  ),
                  items:
                      ApplicationStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusDisplayName(status)),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStageForInsights = value);
                  },
                ),
              ),
              ChoiceChip(
                label: const Text('All Applications'),
                selected: _stageProgressFilter == _StageProgressFilter.all,
                onSelected: (_) {
                  setState(
                    () => _stageProgressFilter = _StageProgressFilter.all,
                  );
                },
              ),
              ChoiceChip(
                label: const Text('At Stage'),
                selected: _stageProgressFilter == _StageProgressFilter.atStage,
                onSelected: (_) {
                  setState(
                    () => _stageProgressFilter = _StageProgressFilter.atStage,
                  );
                },
              ),
              ChoiceChip(
                label: const Text('Completed'),
                selected:
                    _stageProgressFilter == _StageProgressFilter.completed,
                onSelected: (_) {
                  setState(
                    () => _stageProgressFilter = _StageProgressFilter.completed,
                  );
                },
              ),
              ChoiceChip(
                label: const Text('Pending'),
                selected: _stageProgressFilter == _StageProgressFilter.pending,
                onSelected: (_) {
                  setState(
                    () => _stageProgressFilter = _StageProgressFilter.pending,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Selected Stage: ${_getStatusDisplayName(_selectedStageForInsights)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStageKpiCard(
                title: 'Total Consumers',
                value: '$totalConsumers',
                subtitle: 'Approved applications',
                color: AppTheme.primaryColor,
              ),
              _buildStageKpiCard(
                title: 'Completed',
                value: '$completedConsumers',
                subtitle: '${completedKw.toStringAsFixed(2)} kW',
                color: AppTheme.successColor,
              ),
              _buildStageKpiCard(
                title: 'Pending',
                value: '$pendingConsumers',
                subtitle: '${pendingKw.toStringAsFixed(2)} kW',
                color: AppTheme.warningColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection(List<ApplicationModel> pendingApplications) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Applications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'These applications are waiting for admin approval or need your updates.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pendingApplications.map(_buildPendingApplicationCard),
        ],
      ),
    );
  }

  Widget _buildPendingApplicationCard(ApplicationModel app) {
    final needsChanges = app.approvalStatus == ApprovalStatus.changesRequested;
    final statusColor =
        needsChanges ? AppTheme.errorColor : AppTheme.warningColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.applicationNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  needsChanges
                      ? (app.approvalRemarks?.trim().isNotEmpty ?? false)
                          ? 'Changes requested: ${app.approvalRemarks}'
                          : 'Admin requested changes on this application.'
                      : 'Application is waiting for admin approval.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              needsChanges ? 'Changes Requested' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (needsChanges)
            OutlinedButton.icon(
              onPressed: () => context.go('/applications/${app.id}/edit'),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Update'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => context.go('/applications/${app.id}'),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View'),
            ),
        ],
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor.withOpacity(0.4),
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'CLIENT & ACCOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isMobile) ...[
                const Expanded(
                  flex: 1,
                  child: Text(
                    'PHONE NUMBER',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'CAPACITY',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: canDelete ? 120 : 80,
                child: const Text(
                  'ACTION',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: applications.length,
            separatorBuilder:
                (_, __) =>
                    const Divider(height: 1, color: AppTheme.borderColor),
            itemBuilder: (context, index) {
              return _buildApplicationRow(
                applications[index],
                isMobile,
                canEdit,
                canDelete,
              );
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      app.fullName[0],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${app.applicationNumber} • ${DateFormat('dd MMM yyyy').format(app.applicationSubmissionDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              Expanded(
                child: Text(
                  app.mobile,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${app.proposedCapacity} kW',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  app.district,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 150,
                    maxWidth: 232,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(app.currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    app.statusDisplayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(app.currentStatus),
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: canDelete ? 120 : 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    onPressed: () => context.go('/applications/${app.id}'),
                    color: AppTheme.primaryColor,
                  ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppTheme.errorColor,
                      ),
                      onPressed: () => _confirmDelete(context, app),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV(List<ApplicationModel> applications) async {
    if (applications.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final fmt = DateFormat('dd-MM-yyyy');

    final headers = [
      'Sr.No.',
      'Application Number',
      'Full Name',
      'Mobile',
      'Email',
      'Gender',
      'State',
      'District',
      'Address',
      'Pincode',
      'Discom Name',
      'Circle',
      'Division',
      'Sub-Division',
      'Consumer Account No.',
      'Category',
      'Scheme',
      'Proposed Capacity (kWp)',
      'Sanctioned Load (kW)',
      'Net Eligible Capacity (kWp)',
      'Vendor Name',
      'Loan Status',
      'Loan App. Number',
      'Sanction Amount (Rs.)',
      'Processing Fees (Rs.)',
      'Feasibility Status',
      'Approved Capacity (kWp)',
      'Current Stage',
      'Approval Status',
      'Submission Date',
      'Created At',
    ];

    final rows = <List<String>>[headers];

    for (var i = 0; i < applications.length; i++) {
      final app = applications[i];
      rows.add([
        '${i + 1}',
        app.applicationNumber,
        app.fullName,
        app.mobile,
        app.email ?? '',
        app.gender,
        app.state,
        app.district,
        '"${app.address.replaceAll('"', '""')}"', // escape quotes
        app.pincode,
        app.discomName,
        app.circleName,
        app.divisionName,
        app.subdivisionName,
        app.consumerAccountNumber,
        app.categoryName,
        app.schemeName,
        app.proposedCapacity.toStringAsFixed(3),
        app.sanctionedLoad.toStringAsFixed(3),
        app.netEligibleCapacity.toStringAsFixed(3),
        app.vendorName,
        app.loanStatus,
        app.loanApplicationNumber ?? '',
        app.sanctionAmount?.toStringAsFixed(2) ?? '',
        app.processingFees?.toStringAsFixed(2) ?? '',
        app.feasibilityStatus,
        app.approvedCapacity?.toStringAsFixed(3) ?? '',
        app.statusDisplayName,
        app.approvalStatusDisplayName,
        fmt.format(app.applicationSubmissionDate),
        fmt.format(app.createdAt),
      ]);
    }

    final csvContent = rows.map((row) => row.join(',')).join('\n');
    final bytes = utf8.encode(csvContent);
    final fileName =
        'applications_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV Export',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${applications.length} applications to CSV',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF(List<ApplicationModel> applications) async {
    if (applications.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final fmt = DateFormat('dd-MM-yyyy');
    final now = DateTime.now();

    final document = PdfDocument();
    document.pageSettings.orientation = PdfPageOrientation.landscape;
    document.pageSettings.margins.all = 20;

    final page = document.pages.add();
    final pageWidth = page.getClientSize().width;

    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      16,
      style: PdfFontStyle.bold,
    );
    final subFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      8,
      style: PdfFontStyle.bold,
    );
    final cellFont = PdfStandardFont(PdfFontFamily.helvetica, 7);

    double yPos = 0;

    page.graphics.drawString(
      AppConstants.companyName,
      titleFont,
      brush: PdfSolidBrush(PdfColor(30, 64, 175)),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 22),
    );
    yPos += 24;

    page.graphics.drawString(
      'MIS Report – Applications',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 16),
    );
    yPos += 18;

    page.graphics.drawString(
      'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}   |   Total Records: ${applications.length}',
      subFont,
      brush: PdfSolidBrush(PdfColor(100, 100, 100)),
      bounds: Rect.fromLTWH(0, yPos, pageWidth, 12),
    );
    yPos += 20;

    page.graphics.drawLine(
      PdfPen(PdfColor(30, 64, 175), width: 1.5),
      Offset(0, yPos),
      Offset(pageWidth, yPos),
    );
    yPos += 10;

    final pending =
        applications
            .where(
              (a) =>
                  a.currentStatus == ApplicationStatus.applicationReceived ||
                  a.currentStatus == ApplicationStatus.documentsVerified,
            )
            .length;
    final inProgress =
        applications
            .where(
              (a) =>
                  a.currentStatus != ApplicationStatus.applicationReceived &&
                  a.currentStatus != ApplicationStatus.documentsVerified &&
                  a.currentStatus != ApplicationStatus.completeWorkDone,
            )
            .length;
    final completed =
        applications
            .where((a) => a.currentStatus == ApplicationStatus.completeWorkDone)
            .length;
    final totalKWp = applications.fold<double>(
      0,
      (sum, a) => sum + a.proposedCapacity,
    );

    final statsData = [
      ['Total', '${applications.length}'],
      ['Pending', '$pending'],
      ['In Progress', '$inProgress'],
      ['Completed', '$completed'],
      ['Total kWp', totalKWp.toStringAsFixed(2)],
    ];
    final statWidth = pageWidth / statsData.length;
    for (var i = 0; i < statsData.length; i++) {
      final x = i * statWidth;
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(
          i == 0
              ? PdfColor(30, 64, 175)
              : i == 3
              ? PdfColor(21, 128, 61)
              : PdfColor(243, 244, 246),
        ),
        bounds: Rect.fromLTWH(x, yPos, statWidth - 4, 32),
      );
      page.graphics.drawString(
        statsData[i][1],
        PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(
          i == 0 || i == 3 ? PdfColor(255, 255, 255) : PdfColor(30, 64, 175),
        ),
        bounds: Rect.fromLTWH(x + 6, yPos + 2, statWidth - 8, 16),
      );
      page.graphics.drawString(
        statsData[i][0],
        PdfStandardFont(PdfFontFamily.helvetica, 7),
        brush: PdfSolidBrush(
          i == 0 || i == 3 ? PdfColor(200, 220, 255) : PdfColor(100, 100, 100),
        ),
        bounds: Rect.fromLTWH(x + 6, yPos + 18, statWidth - 8, 10),
      );
    }
    yPos += 44;

    final tableHeaders = [
      'Sr.',
      'App. No.',
      'Full Name',
      'Mobile',
      'State',
      'District',
      'kWp',
      'Vendor',
      'Current Stage',
      'Feasibility',
      'Loan Status',
      'Submission Date',
    ];
    final colWidths = [
      22.0,
      90.0,
      90.0,
      65.0,
      60.0,
      60.0,
      35.0,
      70.0,
      90.0,
      65.0,
      60.0,
      65.0,
    ];

    double xPos = 0;
    for (var i = 0; i < tableHeaders.length; i++) {
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(30, 64, 175)),
        bounds: Rect.fromLTWH(xPos, yPos, colWidths[i], 18),
      );
      page.graphics.drawString(
        tableHeaders[i],
        headerFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(xPos + 2, yPos + 3, colWidths[i] - 4, 14),
        format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.middle),
      );
      xPos += colWidths[i];
    }
    yPos += 18;

    for (var rowIdx = 0; rowIdx < applications.length; rowIdx++) {
      final app = applications[rowIdx];
      final rowData = [
        '${rowIdx + 1}',
        app.applicationNumber,
        app.fullName,
        app.mobile,
        app.state,
        app.district,
        app.proposedCapacity.toStringAsFixed(2),
        app.vendorName,
        app.statusDisplayName,
        app.feasibilityStatus,
        app.loanStatus,
        fmt.format(app.applicationSubmissionDate),
      ];

      const rowH = 14.0;

      if (rowIdx % 2 == 0) {
        page.graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(239, 246, 255)),
          bounds: Rect.fromLTWH(0, yPos, pageWidth, rowH),
        );
      }

      xPos = 0;
      for (var col = 0; col < rowData.length; col++) {
        page.graphics.drawString(
          rowData[col],
          cellFont,
          bounds: Rect.fromLTWH(
            xPos + 2,
            yPos + 1,
            colWidths[col] - 4,
            rowH - 2,
          ),
          format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.middle),
        );
        xPos += colWidths[col];
      }

      page.graphics.drawLine(
        PdfPen(PdfColor(220, 220, 220)),
        Offset(0, yPos + rowH),
        Offset(pageWidth, yPos + rowH),
      );
      yPos += rowH;

      if (yPos > page.getClientSize().height - 30 &&
          rowIdx < applications.length - 1) {
        final newPage = document.pages.add();
        yPos = 0;
        xPos = 0;
        for (var i = 0; i < tableHeaders.length; i++) {
          newPage.graphics.drawRectangle(
            brush: PdfSolidBrush(PdfColor(30, 64, 175)),
            bounds: Rect.fromLTWH(xPos, yPos, colWidths[i], 18),
          );
          newPage.graphics.drawString(
            tableHeaders[i],
            headerFont,
            brush: PdfSolidBrush(PdfColor(255, 255, 255)),
            bounds: Rect.fromLTWH(xPos + 2, yPos + 3, colWidths[i] - 4, 14),
          );
          xPos += colWidths[i];
        }
        yPos += 18;
      }
    }

    final lastPage = document.pages[document.pages.count - 1];
    lastPage.graphics.drawString(
      '© ${now.year} ${AppConstants.companyName} | Confidential MIS Report',
      PdfStandardFont(PdfFontFamily.helvetica, 7),
      brush: PdfSolidBrush(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(
        0,
        lastPage.getClientSize().height - 14,
        pageWidth,
        12,
      ),
    );

    final List<int> bytes = document.saveSync();
    document.dispose();

    final fileName =
        'MIS_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save MIS PDF Report',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MIS PDF exported: $fileName'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
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
    final totalSteps = ApplicationStatus.values.length;
    final completedSteps =
        app.statusIndex; // steps before current are completed
    final progressPercent = ((completedSteps / totalSteps) * 100).round();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 900,
              constraints: const BoxConstraints(maxWidth: 920),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application Progress',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${app.applicationNumber} • ${app.fullName}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '$progressPercent% Complete',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          ApplicationStatus.values.asMap().entries.map((entry) {
                            final index = entry.key;
                            final status = entry.value;
                            final isCompleted = app.statusIndex > index;
                            final isCurrent = app.statusIndex == index;
                            final isLast =
                                index == ApplicationStatus.values.length - 1;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color:
                                              isCompleted
                                                  ? AppTheme.successColor
                                                  : isCurrent
                                                  ? AppTheme.primaryColor
                                                  : const Color(0xFFE5E7EB),
                                          shape: BoxShape.circle,
                                          boxShadow:
                                              (isCompleted || isCurrent)
                                                  ? [
                                                    BoxShadow(
                                                      color: (isCompleted
                                                              ? AppTheme
                                                                  .successColor
                                                              : AppTheme
                                                                  .primaryColor)
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        child: Icon(
                                          isCompleted
                                              ? Icons.check_rounded
                                              : isCurrent
                                              ? Icons.more_horiz_rounded
                                              : Icons.circle_outlined,
                                          color:
                                              (isCompleted || isCurrent)
                                                  ? Colors.white
                                                  : const Color(0xFFAAAAAA),
                                          size: isCompleted ? 20 : 18,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _getStatusDisplayName(status),
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.caption.copyWith(
                                          color:
                                              isCompleted
                                                  ? AppTheme.textPrimary
                                                  : isCurrent
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textLight,
                                          fontWeight:
                                              isCurrent
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isCompleted
                                                  ? AppTheme.successColor
                                                      .withOpacity(0.12)
                                                  : isCurrent
                                                  ? AppTheme.primaryColor
                                                      .withOpacity(0.12)
                                                  : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          isCompleted
                                              ? 'Completed'
                                              : isCurrent
                                              ? 'In Progress'
                                              : 'Pending',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isCompleted
                                                    ? AppTheme.successColor
                                                    : isCurrent
                                                    ? AppTheme.primaryColor
                                                    : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 19),
                                    child: Container(
                                      width: 32,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color:
                                            isCompleted
                                                ? AppTheme.successColor
                                                : const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Progress',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$completedSteps of $totalSteps steps completed',
                            style: AppTextStyles.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completedSteps / totalSteps,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.successColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
      case ApplicationStatus.applicationReceived:
        return 'Application Received';
      case ApplicationStatus.documentsVerified:
        return 'Documents Verified';
      case ApplicationStatus.siteSurveyPending:
        return 'Site Survey Pending';
      case ApplicationStatus.siteSurveyCompleted:
        return 'Site Survey Completed';
      case ApplicationStatus.solarDemandPending:
        return 'Solar Demand Pending';
      case ApplicationStatus.solarDemandDeposit:
        return 'Solar Demand Deposit';
      case ApplicationStatus.meterTested:
        return 'Meter Tested';
      case ApplicationStatus.installationScheduled:
        return 'Installation Scheduled';
      case ApplicationStatus.installationCompleted:
        return 'Installation Completed';
      case ApplicationStatus.subsidyProcess:
        return 'Subsidy Process';
      case ApplicationStatus.completeWorkDone:
        return 'Complete Work Done';
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applicationReceived:
      case ApplicationStatus.documentsVerified:
        return AppTheme.statusPending;
      case ApplicationStatus.siteSurveyPending:
      case ApplicationStatus.siteSurveyCompleted:
      case ApplicationStatus.solarDemandPending:
      case ApplicationStatus.solarDemandDeposit:
        return AppTheme.statusInProgress;
      case ApplicationStatus.meterTested:
      case ApplicationStatus.installationScheduled:
      case ApplicationStatus.installationCompleted:
      case ApplicationStatus.subsidyProcess:
        return AppTheme.warningColor;
      case ApplicationStatus.completeWorkDone:
        return AppTheme.statusCompleted;
    }
  }

  bool _isStageCompleted(ApplicationModel app, ApplicationStatus stage) {
    return app.statusIndex >= stage.index;
  }

  bool _isAtSelectedStage(ApplicationModel app, ApplicationStatus stage) {
    return app.currentStatus == stage;
  }
}
