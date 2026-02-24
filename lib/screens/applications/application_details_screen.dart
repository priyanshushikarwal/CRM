import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/application_model.dart';
import '../../models/document_model.dart';
import '../../providers/app_providers.dart';
import '../../services/application_service.dart';

class ApplicationDetailsScreen extends ConsumerStatefulWidget {
  final String applicationId;

  const ApplicationDetailsScreen({super.key, required this.applicationId});

  @override
  ConsumerState<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState
    extends ConsumerState<ApplicationDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showTrackingPanel = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationAsync = ref.watch(
      applicationProvider(widget.applicationId),
    );
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1100;

    return applicationAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load application',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: AppTextStyles.bodySmall),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/applications'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
      data: (application) {
        if (application == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text('Application not found', style: AppTextStyles.heading3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/applications'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              // Main content
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, application),
                    Expanded(
                      child: Row(
                        children: [
                          // Details content
                          Expanded(child: _buildDetailsContent(application)),
                          // Tracking panel (desktop)
                          if (isDesktop && _showTrackingPanel)
                            Container(
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  left: BorderSide(color: AppTheme.borderColor),
                                ),
                              ),
                              child: _buildTrackingPanel(application),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/applications'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Number: ${app.applicationNumber}',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
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
                    const SizedBox(width: 8),
                    // Approval status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getApprovalStatusColor(
                          app.approvalStatus,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getApprovalStatusIcon(app.approvalStatus),
                            size: 14,
                            color: _getApprovalStatusColor(app.approvalStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            app.approvalStatusDisplayName,
                            style: AppTextStyles.caption.copyWith(
                              color: _getApprovalStatusColor(
                                app.approvalStatus,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Submitted: ${DateFormat('dd MMM yyyy').format(app.applicationSubmissionDate)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showTrackingPanel = !_showTrackingPanel;
              });
            },
            icon: const Icon(Icons.track_changes_rounded, size: 18),
            label: const Text('Track'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/applications/${app.id}/edit'),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 12),
          // Admin approval buttons - only show if pending and user can manage users
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider).value;
              final canApprove = currentUser?.canManageUsers ?? false;

              if (!canApprove || app.approvalStatus != ApprovalStatus.pending) {
                return const SizedBox.shrink();
              }

              return Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleApproval(app, 'approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _handleApproval(app, 'changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Request Changes'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _handleApproval(app, 'reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('Action', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            onSelected: (value) async {
              await _handleActionSelection(value, app);
            },
            itemBuilder: (context) => _buildActionMenuItems(app),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent(ApplicationModel app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          _buildProgressTracker(app),
          const SizedBox(height: 24),
          // Details sections
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSectionCard(
                      'Application Details',
                      Icons.description_rounded,
                      [
                        _buildDetailRow('State', app.state),
                        _buildDetailRow('Name of Discom', app.discomName),
                        _buildDetailRow('Full Name', app.fullName),
                        _buildDetailRow('Gender', app.gender),
                        _buildDetailRow('Address', app.address),
                        _buildDetailRow('Pincode', app.pincode),
                        _buildDetailRow(
                          'Consumer Account Number',
                          app.consumerAccountNumber,
                        ),
                        _buildDetailRow('Mobile', app.mobile),
                        _buildDetailRow('Email', app.email ?? '-'),
                        _buildDetailRow('District', app.district),
                        _buildDetailRow(
                          'Application Submission Date',
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(app.applicationSubmissionDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      'Bank Details',
                      Icons.account_balance_rounded,
                      [
                        _buildDetailRow(
                          'Scheme Name',
                          app.schemeName,
                          highlight: true,
                        ),
                        _buildDetailRow('Bank Name', app.bankName ?? '-'),
                        _buildDetailRow('IFSC Code', app.ifscCode ?? '-'),
                        _buildDetailRow(
                          'Account Holder Name',
                          app.accountHolderName ?? '-',
                        ),
                        _buildDetailRow(
                          'Account Number',
                          app.accountNumber ?? '-',
                        ),
                        _buildDetailRow('Bank Remarks', app.bankRemarks ?? '-'),
                        _buildDetailRow(
                          'Give Up Subsidy',
                          app.giveUpSubsidy ? 'Yes' : 'No',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildSectionCard(
                      'Solar Rooftop Details',
                      Icons.solar_power_rounded,
                      [
                        _buildDetailRow(
                          'Sanctioned Load (kW)',
                          app.sanctionedLoad.toString(),
                        ),
                        _buildDetailRow(
                          'Proposed Capacity (kWp)',
                          app.proposedCapacity.toString(),
                        ),
                        _buildDetailRow(
                          'Latitude',
                          app.latitude?.toString() ?? '-',
                        ),
                        _buildDetailRow(
                          'Longitude',
                          app.longitude?.toString() ?? '-',
                        ),
                        _buildDetailRow('Category Name', app.categoryName),
                        _buildDetailRow(
                          'Existing Installed Capacity (kWp)',
                          app.existingInstalledCapacity.toString(),
                        ),
                        _buildDetailRow(
                          'Net Eligible Capacity (kWp)',
                          app.netEligibleCapacity.toString(),
                        ),
                        _buildDetailRow(
                          'Name of Vendor',
                          app.vendorName,
                          highlight: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard('Loan Details', Icons.payments_rounded, [
                      _buildDetailRow(
                        'Current Status of Loan',
                        app.loanStatus,
                        highlight: true,
                      ),
                      _buildDetailRow(
                        'Loan Application Number',
                        app.loanApplicationNumber ?? '-',
                      ),
                      _buildDetailRow(
                        'Sanction Date',
                        app.sanctionDate != null
                            ? DateFormat('dd/MM/yyyy').format(app.sanctionDate!)
                            : 'Not Available',
                      ),
                      _buildDetailRow(
                        'Sanction Amount (Rs.)',
                        app.sanctionAmount?.toString() ?? '-',
                        highlight: true,
                      ),
                      _buildDetailRow(
                        'Processing Fees (Rs.)',
                        app.processingFees?.toString() ?? '-',
                        highlight: true,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      'Feasibility Details',
                      Icons.check_circle_outline_rounded,
                      [
                        _buildDetailRow(
                          'Feasibility Date',
                          app.feasibilityDate != null
                              ? DateFormat(
                                'dd/MM/yyyy',
                              ).format(app.feasibilityDate!)
                              : '-',
                        ),
                        _buildDetailRow(
                          'Feasibility Person',
                          app.feasibilityPerson ?? '-',
                          highlight: true,
                        ),
                        _buildDetailRow('Status', app.feasibilityStatus),
                        _buildDetailRow(
                          'Approved Capacity (kWp)',
                          app.approvedCapacity?.toString() ?? '-',
                          highlight: true,
                        ),
                        _buildDetailRow('Remarks', app.remarks ?? '-'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Documents section
          _buildDocumentsSection(app),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(ApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Application Progress', style: AppTextStyles.heading4),
              Text(
                '${(app.progressPercentage).toStringAsFixed(0)}% Complete',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ApplicationStatus.values.asMap().entries.map((entry) {
                    final index = entry.key;
                    final status = entry.value;
                    final isCompleted = app.statusIndex > index;
                    final isCurrent = app.statusIndex == index;
                    final isLast = index == ApplicationStatus.values.length - 1;

                    return _buildProgressStep(
                      _getStatusDisplayName(status),
                      _getResponsibleParty(status),
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isLast: isLast,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
    String title,
    String subtitle, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? AppTheme.successColor
                        : isCurrent
                        ? AppTheme.statusInProgress
                        : AppTheme.borderColor,
                shape: BoxShape.circle,
                border:
                    isCurrent
                        ? Border.all(
                          color: AppTheme.statusInProgress.withOpacity(0.3),
                          width: 3,
                        )
                        : null,
              ),
              child:
                  isCompleted
                      ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                      : isCurrent
                      ? const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                      : Icon(Icons.circle, color: AppTheme.textLight, size: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: Column(
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isCompleted || isCurrent
                              ? AppTheme.textPrimary
                              : AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? AppTheme.successColor.withOpacity(0.1)
                              : isCurrent
                              ? AppTheme.statusInProgress.withOpacity(0.1)
                              : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isCompleted
                          ? 'Completed'
                          : isCurrent
                          ? 'In Progress'
                          : 'Pending',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color:
                            isCompleted
                                ? AppTheme.successColor
                                : isCurrent
                                ? AppTheme.statusInProgress
                                : AppTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Container(
            width: 40,
            height: 2,
            margin: const EdgeInsets.only(bottom: 50),
            color: isCompleted ? AppTheme.successColor : AppTheme.borderColor,
          ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.heading4.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    highlight ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(ApplicationModel app) {
    final documentsAsync = ref.watch(documentsProvider(app.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.folder_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Documents',
                      style: AppTextStyles.heading4.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Upload document
                  },
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Upload'),
                ),
              ],
            ),
          ),
          documentsAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, stack) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Failed to load documents',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
            data: (documents) {
              if (documents.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 48,
                          color: AppTheme.textLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No documents uploaded yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return _buildDocumentsTable(documents);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTable(List<DocumentModel> documents) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: const [
              SizedBox(width: 48, child: Text('Sr.No.')),
              Expanded(flex: 2, child: Text('Document Type')),
              Expanded(flex: 3, child: Text('File Name')),
              Expanded(child: Text('Uploaded On')),
              SizedBox(width: 80, child: Text('Action')),
            ],
          ),
        ),
        // Table rows
        ...documents.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text('${index + 1}')),
                Expanded(
                  flex: 2,
                  child: Text(
                    doc.documentType,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(
                        doc.isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        size: 18,
                        color: doc.isPdf ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc.fileName,
                          style: AppTextStyles.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    DateFormat('dd-MM-yyyy').format(doc.uploadedOn),
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: View document
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.visibility_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('View', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTrackingPanel(ApplicationModel app) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track Application', style: AppTextStyles.heading4),
                  Text(
                    '#${app.applicationNumber}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _showTrackingPanel = false;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  ApplicationStatus.values.asMap().entries.map((entry) {
                    final index = entry.key;
                    final status = entry.value;
                    final isCompleted = app.statusIndex > index;
                    final isCurrent = app.statusIndex == index;
                    final isLast = index == ApplicationStatus.values.length - 1;

                    return _buildTrackingItem(
                      status,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isLast: isLast,
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingItem(
    ApplicationStatus status, {
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
              width: 28,
              height: 28,
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
                        size: 16,
                        color: Colors.white,
                      )
                      : isCurrent
                      ? const Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color:
                    isCompleted ? AppTheme.successColor : AppTheme.borderColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusDisplayName(status),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight:
                      isCurrent || isCompleted
                          ? FontWeight.w600
                          : FontWeight.w400,
                  color:
                      isCompleted || isCurrent
                          ? AppTheme.textPrimary
                          : AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(${_getResponsibleParty(status)})',
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              if (isCompleted || isCurrent) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.statusInProgress.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'In Progress',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color:
                              isCompleted
                                  ? AppTheme.successColor
                                  : AppTheme.statusInProgress,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusDisplayName(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.consumerRegistration:
        return 'Registration';
      case ApplicationStatus.consumerApplication:
        return 'Application';
      case ApplicationStatus.discomFeasibility:
        return 'Feasibility';
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

  String _getResponsibleParty(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.consumerRegistration:
      case ApplicationStatus.consumerApplication:
      case ApplicationStatus.consumerVendorSelection:
      case ApplicationStatus.consumerSubsidyRequest:
        return 'Consumer';
      case ApplicationStatus.discomFeasibility:
      case ApplicationStatus.discomInspection:
      case ApplicationStatus.projectCommissioning:
        return 'Discom';
      case ApplicationStatus.vendorUploadAgreement:
      case ApplicationStatus.vendorInstallation:
        return 'Vendor';
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

  // Build action menu items based on current status
  List<PopupMenuEntry<String>> _buildActionMenuItems(ApplicationModel app) {
    final items = <PopupMenuEntry<String>>[];

    // Get the next status if available
    final currentIndex = app.currentStatus.index;
    final canAdvance = currentIndex < ApplicationStatus.values.length - 1;

    if (canAdvance) {
      final nextStatus = ApplicationStatus.values[currentIndex + 1];
      items.add(
        PopupMenuItem(
          value: 'advance_status',
          child: Row(
            children: [
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 12),
              Text('Advance to ${_getStatusDisplayName(nextStatus)}'),
            ],
          ),
        ),
      );
      items.add(const PopupMenuDivider());
    }

    // Add specific actions based on current status
    switch (app.currentStatus) {
      case ApplicationStatus.consumerRegistration:
        items.add(
          const PopupMenuItem(
            value: 'complete_registration',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 18),
                SizedBox(width: 12),
                Text('Complete Registration'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.consumerApplication:
        items.add(
          const PopupMenuItem(
            value: 'submit_application',
            child: Row(
              children: [
                Icon(Icons.send_rounded, size: 18),
                SizedBox(width: 12),
                Text('Submit Application'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.discomFeasibility:
        items.add(
          const PopupMenuItem(
            value: 'approve_feasibility',
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: AppTheme.successColor,
                ),
                SizedBox(width: 12),
                Text('Approve Feasibility'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.consumerVendorSelection:
        items.add(
          const PopupMenuItem(
            value: 'confirm_vendor',
            child: Row(
              children: [
                Icon(Icons.business_rounded, size: 18),
                SizedBox(width: 12),
                Text('Confirm Vendor Selection'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.vendorUploadAgreement:
        items.add(
          const PopupMenuItem(
            value: 'upload_agreement',
            child: Row(
              children: [
                Icon(Icons.upload_file_rounded, size: 18),
                SizedBox(width: 12),
                Text('Upload Agreement'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.vendorInstallation:
        items.add(
          const PopupMenuItem(
            value: 'submit_installation',
            child: Row(
              children: [
                Icon(Icons.construction_rounded, size: 18),
                SizedBox(width: 12),
                Text('Submit Installation'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.discomInspection:
        items.add(
          const PopupMenuItem(
            value: 'approve_inspection',
            child: Row(
              children: [
                Icon(
                  Icons.fact_check_rounded,
                  size: 18,
                  color: AppTheme.successColor,
                ),
                SizedBox(width: 12),
                Text('Approve Inspection'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.projectCommissioning:
        items.add(
          const PopupMenuItem(
            value: 'complete_commissioning',
            child: Row(
              children: [
                Icon(Icons.engineering_rounded, size: 18),
                SizedBox(width: 12),
                Text('Complete Commissioning'),
              ],
            ),
          ),
        );
        break;
      case ApplicationStatus.consumerSubsidyRequest:
        items.add(
          const PopupMenuItem(
            value: 'process_subsidy',
            child: Row(
              children: [
                Icon(
                  Icons.payments_rounded,
                  size: 18,
                  color: AppTheme.successColor,
                ),
                SizedBox(width: 12),
                Text('Process Subsidy Request'),
              ],
            ),
          ),
        );
        break;
    }

    // Add common actions
    items.add(const PopupMenuDivider());
    items.add(
      const PopupMenuItem(
        value: 'update_status',
        child: Row(
          children: [
            Icon(Icons.edit_rounded, size: 18),
            SizedBox(width: 12),
            Text('Update Status Manually'),
          ],
        ),
      ),
    );
    items.add(
      const PopupMenuItem(
        value: 'view_history',
        child: Row(
          children: [
            Icon(Icons.history_rounded, size: 18),
            SizedBox(width: 12),
            Text('View Status History'),
          ],
        ),
      ),
    );

    return items;
  }

  // Handle action selection
  Future<void> _handleActionSelection(
    String action,
    ApplicationModel app,
  ) async {
    ApplicationStatus? newStatus;
    String? actionRemarks;

    switch (action) {
      case 'advance_status':
        final currentIndex = app.currentStatus.index;
        if (currentIndex < ApplicationStatus.values.length - 1) {
          newStatus = ApplicationStatus.values[currentIndex + 1];
          actionRemarks = 'Advanced to ${_getStatusDisplayName(newStatus)}';
        }
        break;
      case 'complete_registration':
        newStatus = ApplicationStatus.consumerApplication;
        actionRemarks = 'Registration completed';
        break;
      case 'submit_application':
        newStatus = ApplicationStatus.discomFeasibility;
        actionRemarks = 'Application submitted for feasibility';
        break;
      case 'approve_feasibility':
        newStatus = ApplicationStatus.consumerVendorSelection;
        actionRemarks = 'Feasibility approved';
        break;
      case 'confirm_vendor':
        newStatus = ApplicationStatus.vendorUploadAgreement;
        actionRemarks = 'Vendor selection confirmed';
        break;
      case 'upload_agreement':
        newStatus = ApplicationStatus.vendorInstallation;
        actionRemarks = 'Agreement uploaded';
        break;
      case 'submit_installation':
        newStatus = ApplicationStatus.discomInspection;
        actionRemarks = 'Installation submitted for inspection';
        break;
      case 'approve_inspection':
        newStatus = ApplicationStatus.projectCommissioning;
        actionRemarks = 'Inspection approved';
        break;
      case 'complete_commissioning':
        newStatus = ApplicationStatus.consumerSubsidyRequest;
        actionRemarks = 'Project commissioned successfully';
        break;
      case 'process_subsidy':
        // Already at final status, show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application is already at the final stage!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        return;
      case 'update_status':
        await _showUpdateStatusDialog(app);
        return;
      case 'view_history':
        await _showStatusHistoryDialog(app);
        return;
      default:
        return;
    }

    if (newStatus != null) {
      await _updateApplicationStatus(app, newStatus, actionRemarks);
    }
  }

  // Update application status
  Future<void> _updateApplicationStatus(
    ApplicationModel app,
    ApplicationStatus newStatus,
    String? remarks,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Updating status...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final result = await ref
          .read(applicationsProvider.notifier)
          .updateApplicationStatus(
            applicationId: app.id,
            newStatus: newStatus,
            stageStatus: StageStatus.completed,
            remarks: remarks,
          );

      // Close loading dialog first
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (result != null) {
        // Refresh the application data
        ref.invalidate(applicationProvider(widget.applicationId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status updated to ${_getStatusDisplayName(newStatus)}',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        // result was null, meaning an error occurred in the provider
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update status. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog first
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Show manual status update dialog
  Future<void> _showUpdateStatusDialog(ApplicationModel app) async {
    ApplicationStatus? selectedStatus = app.currentStatus;
    final remarksController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Text('Update Status'),
                    ],
                  ),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status: ${_getStatusDisplayName(app.currentStatus)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select New Status:',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<ApplicationStatus>(
                            value: selectedStatus,
                            isExpanded: true,
                            underline: const SizedBox(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value;
                              });
                            },
                            items:
                                ApplicationStatus.values.map((status) {
                                  final isCompleted =
                                      status.index < app.currentStatus.index;
                                  final isCurrent = status == app.currentStatus;
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCompleted
                                              ? Icons.check_circle_rounded
                                              : isCurrent
                                              ? Icons
                                                  .radio_button_checked_rounded
                                              : Icons
                                                  .radio_button_unchecked_rounded,
                                          size: 18,
                                          color:
                                              isCompleted
                                                  ? AppTheme.successColor
                                                  : isCurrent
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.textLight,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_getStatusDisplayName(status)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Remarks (optional):',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: remarksController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter remarks...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Update Status'),
                    ),
                  ],
                ),
          ),
    );

    if (result == true &&
        selectedStatus != null &&
        selectedStatus != app.currentStatus) {
      await _updateApplicationStatus(
        app,
        selectedStatus!,
        remarksController.text.isNotEmpty ? remarksController.text : null,
      );
    }
  }

  // Show status history dialog
  Future<void> _showStatusHistoryDialog(ApplicationModel app) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.history_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                const Text('Status History'),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child:
                  app.statusHistory.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: AppTheme.textLight.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No status history available',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: app.statusHistory.length,
                        itemBuilder: (context, index) {
                          final historyItem =
                              app.statusHistory[app.statusHistory.length -
                                  1 -
                                  index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      historyItem.stageStatus ==
                                              StageStatus.completed
                                          ? AppTheme.successColor.withOpacity(
                                            0.1,
                                          )
                                          : historyItem.stageStatus ==
                                              StageStatus.rejected
                                          ? AppTheme.errorColor.withOpacity(0.1)
                                          : AppTheme.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  historyItem.stageStatus ==
                                          StageStatus.completed
                                      ? Icons.check_rounded
                                      : historyItem.stageStatus ==
                                          StageStatus.rejected
                                      ? Icons.close_rounded
                                      : Icons.schedule_rounded,
                                  color:
                                      historyItem.stageStatus ==
                                              StageStatus.completed
                                          ? AppTheme.successColor
                                          : historyItem.stageStatus ==
                                              StageStatus.rejected
                                          ? AppTheme.errorColor
                                          : AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                _getStatusDisplayName(historyItem.status),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(historyItem.timestamp),
                                    style: AppTextStyles.caption,
                                  ),
                                  if (historyItem.remarks != null)
                                    Text(
                                      historyItem.remarks!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  if (historyItem.updatedBy != null)
                                    Text(
                                      'By: ${historyItem.updatedBy}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Color _getApprovalStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return AppTheme.textSecondary;
      case ApprovalStatus.pending:
        return AppTheme.warningColor;
      case ApprovalStatus.approved:
        return AppTheme.successColor;
      case ApprovalStatus.rejected:
        return AppTheme.errorColor;
      case ApprovalStatus.changesRequested:
        return Colors.orange;
    }
  }

  IconData _getApprovalStatusIcon(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return Icons.edit_note_rounded;
      case ApprovalStatus.pending:
        return Icons.pending_rounded;
      case ApprovalStatus.approved:
        return Icons.check_circle_rounded;
      case ApprovalStatus.rejected:
        return Icons.cancel_rounded;
      case ApprovalStatus.changesRequested:
        return Icons.refresh_rounded;
    }
  }

  Future<void> _handleApproval(ApplicationModel app, String action) async {
    final remarksController = TextEditingController();
    String title;
    String message;
    Color color;
    bool requiresRemarks;

    switch (action) {
      case 'approve':
        title = 'Approve Application';
        message = 'Are you sure you want to approve this application?';
        color = AppTheme.successColor;
        requiresRemarks = false;
        break;
      case 'reject':
        title = 'Reject Application';
        message = 'Are you sure you want to reject this application?';
        color = AppTheme.errorColor;
        requiresRemarks = true;
        break;
      case 'changes':
        title = 'Request Changes';
        message = 'Please specify what changes are needed.';
        color = AppTheme.warningColor;
        requiresRemarks = true;
        break;
      default:
        return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  action == 'approve'
                      ? Icons.check_circle_rounded
                      : action == 'reject'
                      ? Icons.cancel_rounded
                      : Icons.edit_note_rounded,
                  color: color,
                ),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Applicant: ${app.fullName}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText:
                          requiresRemarks ? 'Remarks *' : 'Remarks (optional)',
                      hintText:
                          action == 'changes'
                              ? 'Describe the changes needed...'
                              : action == 'reject'
                              ? 'Reason for rejection...'
                              : 'Add any notes...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (requiresRemarks && remarksController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide remarks'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: Text(title.split(' ').last),
              ),
            ],
          ),
    );

    if (result != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        Navigator.pop(context);
        return;
      }

      switch (action) {
        case 'approve':
          await ApplicationService.approveApplication(
            app,
            currentUser.id,
            remarks:
                remarksController.text.isNotEmpty
                    ? remarksController.text
                    : null,
          );
          break;
        case 'reject':
          await ApplicationService.rejectApplication(
            app,
            currentUser.id,
            remarks: remarksController.text,
          );
          break;
        case 'changes':
          await ApplicationService.requestChanges(
            app,
            currentUser.id,
            remarksController.text,
          );
          break;
      }

      // Close loading
      if (mounted) Navigator.pop(context);

      // Refresh the application
      ref.invalidate(applicationProvider(widget.applicationId));
      ref.read(applicationsProvider.notifier).loadApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approve'
                  ? 'Application approved successfully!'
                  : action == 'reject'
                  ? 'Application rejected'
                  : 'Change request sent',
            ),
            backgroundColor: color,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
