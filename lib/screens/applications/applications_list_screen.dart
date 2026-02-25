import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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
                        final apps =
                            ref.read(applicationsProvider).applications;
                        _exportToCSV(apps);
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
                        final apps =
                            ref.read(applicationsProvider).applications;
                        _exportToPDF(apps);
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
              const SizedBox(width: 110, child: Text('Action')),
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
              width: 110,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Quick Progress View button (icon only)
                  Tooltip(
                    message: 'View Progress',
                    child: InkWell(
                      onTap: () => _showTrackingDialog(context, app),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.timeline_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
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

  // ─────────────────────────────────────────────────────────────
  // CSV Export
  // ─────────────────────────────────────────────────────────────
  void _exportToCSV(List<ApplicationModel> applications) {
    if (applications.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final fmt = DateFormat('dd-MM-yyyy');

    // Header row
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
    final blob = html.Blob([Uint8List.fromList(bytes)], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final fileName =
        'applications_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${applications.length} applications to CSV'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MIS PDF Export
  // ─────────────────────────────────────────────────────────────
  void _exportToPDF(List<ApplicationModel> applications) {
    if (applications.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final fmt = DateFormat('dd-MM-yyyy');
    final now = DateTime.now();

    // ── Create PDF document ──
    final document = PdfDocument();
    document.pageSettings.orientation = PdfPageOrientation.landscape;
    document.pageSettings.margins.all = 20;

    final page = document.pages.add();
    final pageWidth = page.getClientSize().width;

    // ── Fonts ──
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

    // ── Header ──
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

    // Divider line
    page.graphics.drawLine(
      PdfPen(PdfColor(30, 64, 175), width: 1.5),
      Offset(0, yPos),
      Offset(pageWidth, yPos),
    );
    yPos += 10;

    // ── Summary Stats Box ──
    final pending =
        applications
            .where(
              (a) =>
                  a.currentStatus == ApplicationStatus.consumerRegistration ||
                  a.currentStatus == ApplicationStatus.consumerApplication,
            )
            .length;
    final inProgress =
        applications
            .where(
              (a) =>
                  a.currentStatus != ApplicationStatus.consumerRegistration &&
                  a.currentStatus != ApplicationStatus.consumerApplication &&
                  a.currentStatus != ApplicationStatus.consumerSubsidyRequest,
            )
            .length;
    final completed =
        applications
            .where(
              (a) =>
                  a.currentStatus == ApplicationStatus.consumerSubsidyRequest,
            )
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

    // ── Main Table ──
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

    // Table header row
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

    // Table data rows
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

      // Row height
      const rowH = 14.0;

      // Alternate row shading
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

      // Bottom border
      page.graphics.drawLine(
        PdfPen(PdfColor(220, 220, 220)),
        Offset(0, yPos + rowH),
        Offset(pageWidth, yPos + rowH),
      );
      yPos += rowH;

      // Add new page if needed
      if (yPos > page.getClientSize().height - 30 &&
          rowIdx < applications.length - 1) {
        final newPage = document.pages.add();
        yPos = 0;
        // Redraw header on new page
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

    // Footer on last page
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

    // ── Save & Download ──
    final List<int> bytes = document.saveSync();
    document.dispose();

    final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final fileName =
        'MIS_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';

    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('MIS PDF exported: $fileName'),
        backgroundColor: AppTheme.successColor,
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
                  // Header row
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
                  // Horizontal stepper
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
                                // Step column
                                SizedBox(
                                  width: 90,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Circle
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
                                      // Step label
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
                                      // Status badge
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
                                // Connector line
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
                  // Progress bar
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
