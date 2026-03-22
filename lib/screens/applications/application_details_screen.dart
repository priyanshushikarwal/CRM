import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/application_model.dart';
import '../../models/document_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../services/application_service.dart';
import '../../services/installation_service.dart';
import '../../services/payment_service.dart';
import '../../models/payment_model.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_providers.dart';

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
  ApplicationModel? _applicationOverride;
  String _inventorySearchQuery = '';
  String _inventoryTypeFilter = 'all';

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
              _applicationOverride != null
                  ? _buildApplicationScaffold(
                    context,
                    _applicationOverride!,
                    isDesktop,
                  )
                  : const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
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

        return _buildApplicationScaffold(
          context,
          _applicationOverride ?? application,
          isDesktop,
        );
      },
    );
  }

  Widget _buildApplicationScaffold(
    BuildContext context,
    ApplicationModel application,
    bool isDesktop,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, application),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildDetailsContent(application)),
                if (isDesktop && _showTrackingPanel)
                  Container(
                    width: 380,
                    margin: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: _buildTrackingPanel(application),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ApplicationModel app) {
    final currentUser = ref.watch(currentUserProvider).value;
    final canEditApplication = currentUser?.canEdit ?? false;
    final canAccessPayments = currentUser?.canAccessPayments ?? false;
    final canAccessInventory = currentUser?.canAccessInventory ?? false;
    final canResubmitRequestedChanges =
        (currentUser?.canAccessApplications ?? false) &&
        app.submittedBy == currentUser?.id &&
        app.approvalStatus == ApprovalStatus.changesRequested;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/applications'),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      app.applicationNumber,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _getStatusColor(app.currentStatus).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        app.statusDisplayName.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: _getStatusColor(app.currentStatus), fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(app.fullName, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('Submitted: ${DateFormat('dd MMM yyyy').format(app.applicationSubmissionDate)}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showTrackingPanel = !_showTrackingPanel),
            icon: Icon(_showTrackingPanel ? Icons.visibility_off_rounded : Icons.track_changes_rounded, size: 18),
            label: Text(_showTrackingPanel ? 'Hide Timeline' : 'Timeline'),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          if (canAccessInventory) ...[
            ElevatedButton.icon(
              onPressed: () => _showInventoryAllotmentDialog(app),
              icon: const Icon(Icons.solar_power_rounded, size: 18),
              label: const Text('Allot Solar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (canEditApplication || canResubmitRequestedChanges) ...[
            OutlinedButton.icon(
              onPressed: () => context.go('/applications/${app.id}/edit'),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(
                canResubmitRequestedChanges && !canEditApplication
                    ? 'Update & Resubmit'
                    : 'Edit',
              ),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(width: 12),
          ],
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider).value;
              final canApprove = currentUser?.canManageUsers ?? false;
              if (!canApprove || app.approvalStatus != ApprovalStatus.pending) return const SizedBox.shrink();
              return Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleApproval(app, 'approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),
          if (canEditApplication || canAccessPayments || canAccessInventory || currentUser?.canManageUsers == true)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) async => await _handleActionSelection(value, app),
              itemBuilder: (context) => _buildActionMenuItems(app),
              style: IconButton.styleFrom(backgroundColor: AppTheme.backgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent(ApplicationModel app) {
    final currentUser = ref.watch(currentUserProvider).value;
    final canAccessPayments = currentUser?.canAccessPayments ?? false;
    final canAccessInventory = currentUser?.canAccessInventory ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressTracker(app),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSectionCard(
                      'Application Details',
                      Icons.description_outlined,
                      [
                        _buildDetailRow('Actual Name', app.fullName, highlight: true),
                        _buildDetailRow(
                          'Name As Per Bill',
                          _optionalText(app.nameAsPerBill),
                          highlight: true,
                        ),
                        _buildDetailRow('Phone Number', app.mobile),
                        _buildDetailRow('K No.', app.consumerAccountNumber),
                        _buildDetailRow('Full Address', app.address),
                        _buildDetailRow('District / State', '${app.district} / ${app.state}'),
                        _buildDetailRow('Discom', _optionalText(app.discomName)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      'Bank & Settlement',
                      Icons.account_balance_outlined,
                      [
                        _buildDetailRow('Scheme', app.schemeName, highlight: true),
                        _buildDetailRow('Bank Name', _optionalText(app.bankName)),
                        _buildDetailRow('IFSC Code', _optionalText(app.ifscCode)),
                        _buildDetailRow('Account Holder', _optionalText(app.accountHolderName)),
                        _buildDetailRow('Account No.', _optionalText(app.accountNumber)),
                        _buildDetailRow('Subsidy Opt-out', app.giveUpSubsidy ? 'Yes' : 'No'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildSectionCard(
                      'Technical Specifications',
                      Icons.solar_power_outlined,
                      [
                        _buildDetailRow('Solar Plant Capacity', '${app.proposedCapacity} kWp', highlight: true),
                        _buildDetailRow('Sanctioned Load', '${app.sanctionedLoad} kW'),
                        _buildDetailRow('Category', app.categoryName),
                        _buildDetailRow('Vendor', _optionalText(app.vendorName), highlight: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      'Financial & Loan',
                      Icons.payments_outlined,
                      [
                        _buildDetailRow('Loan Status', app.loanStatus, highlight: true),
                        _buildDetailRow('Loan App #', _optionalText(app.loanApplicationNumber)),
                        _buildDetailRow(
                          'Sanction Date',
                          app.sanctionDate != null
                              ? DateFormat('dd MMM yyyy').format(app.sanctionDate!)
                              : 'Option not available',
                        ),
                        _buildDetailRow('Sanction Amount', '₹${NumberFormat('#,##,###', 'en_IN').format(app.sanctionAmount ?? 0)}', highlight: true),
                        _buildDetailRow('Processing Fees', '₹${NumberFormat('#,##,###', 'en_IN').format(app.processingFees ?? 0)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canAccessPayments) ...[
            const SizedBox(height: 32),
            _buildPaymentSection(app),
          ],
          if (canAccessInventory) ...[
            const SizedBox(height: 32),
            _buildInventoryAllotmentSection(app),
          ],
          const SizedBox(height: 32),
          _buildOwnershipSection(app),
          const SizedBox(height: 32),
          _buildDocumentsSection(app),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOwnershipSection(ApplicationModel app) {
    final submittedByAsync =
        app.submittedBy != null
            ? ref.watch(userByIdProvider(app.submittedBy!))
            : const AsyncValue<UserModel?>.data(null);
    final approvedByAsync =
        app.approvedBy != null
            ? ref.watch(userByIdProvider(app.approvedBy!))
            : const AsyncValue<UserModel?>.data(null);

    final submittedByName = submittedByAsync.value?.displayName ?? '-';
    final approvedByName = approvedByAsync.value?.displayName ?? '-';

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
          const Text(
            'Work Tracking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildMetaInfoItem('Submitted By', submittedByName),
              _buildMetaInfoItem(
                'Approved / Reviewed By',
                app.approvedBy != null ? approvedByName : '-',
              ),
              _buildMetaInfoItem(
                'Approval Date',
                app.approvalDate != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(app.approvalDate!)
                    : '-',
              ),
              _buildMetaInfoItem(
                'Approval Remarks',
                (app.approvalRemarks?.trim().isNotEmpty ?? false)
                    ? app.approvalRemarks!
                    : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfoItem(String label, String value) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAllotmentSection(ApplicationModel app) {
    final inventoryState = ref.watch(inventoryProvider);
    final appAllotments =
        inventoryState.allotments.where((a) => a.applicationId == app.id).toList();
    final filteredAllotments =
        appAllotments.where((allotment) {
          if (_inventoryTypeFilter != 'all' &&
              allotment.itemType.name != _inventoryTypeFilter) {
            return false;
          }

          if (_inventorySearchQuery.trim().isEmpty) {
            return true;
          }

          final resolved = _resolveAllotmentDisplay(allotment, inventoryState);
          final query = _inventorySearchQuery.trim().toLowerCase();
          return resolved['serial']!.toLowerCase().contains(query) ||
              resolved['details']!.toLowerCase().contains(query) ||
              allotment.itemType.name.toLowerCase().contains(query) ||
              (allotment.handoverBy ?? '').toLowerCase().contains(query);
        }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(AppTheme.cardRadius), topRight: Radius.circular(AppTheme.cardRadius)),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 12),
                    Text('Inventory Allotment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          appAllotments.isEmpty
                              ? null
                              : () => _exportInventoryAllotmentsPdf(
                                app,
                                filteredAllotments,
                                inventoryState,
                              ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Export PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showInventoryAllotmentDialog(app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('Allot Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: appAllotments.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No inventory items allotted to this application', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged:
                                  (value) => setState(
                                    () => _inventorySearchQuery = value,
                                  ),
                              decoration: InputDecoration(
                                hintText: 'Search by serial no. or item details',
                                prefixIcon: const Icon(Icons.search_rounded),
                                isDense: true,
                                filled: true,
                                fillColor: AppTheme.backgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              value: _inventoryTypeFilter,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.backgroundColor,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Items')),
                                DropdownMenuItem(value: 'panel', child: Text('Panels')),
                                DropdownMenuItem(value: 'inverter', child: Text('Inverters')),
                                DropdownMenuItem(value: 'meter', child: Text('Meters')),
                              ],
                              onChanged:
                                  (value) => setState(
                                    () => _inventoryTypeFilter = value ?? 'all',
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (filteredAllotments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No allotments match the selected search or filter.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAllotments.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final allotment = filteredAllotments[index];
                            final resolved = _resolveAllotmentDisplay(allotment, inventoryState);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  allotment.itemType == InventoryItemType.panel
                                      ? Icons.solar_power_outlined
                                      : allotment.itemType == InventoryItemType.inverter
                                      ? Icons.electrical_services_outlined
                                      : Icons.speed_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                'S/N: ${resolved['serial']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${resolved['details']}\nAssigned by: ${allotment.handoverBy ?? '-'}',
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                DateFormat('dd MMM yyyy').format(allotment.handoverDate),
                                style: AppTextStyles.caption,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(ApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(32),
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
              const Text('Application Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${(app.progressPercentage).toStringAsFixed(0)}% Complete', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: app.progressPercentage / 100, minHeight: 8, backgroundColor: AppTheme.backgroundColor, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
          ),
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ApplicationStatus.values.asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                final isCompleted = app.statusIndex > index;
                final isCurrent = app.statusIndex == index;
                final isLast = index == ApplicationStatus.values.length - 1;

                final historyItems = app.statusHistory.where((h) => h.status == status).toList();
                DateTime? statusDate;
                if (historyItems.isNotEmpty) {
                  statusDate = historyItems.last.timestamp;
                } else if (status == ApplicationStatus.applicationReceived) {
                  statusDate = app.applicationSubmissionDate;
                }

                return _buildProgressStep(
                  _getStatusDisplayName(status),
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isLast: isLast,
                  date: statusDate,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
    String title, {
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    DateTime? date,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : (isCurrent ? AppTheme.primaryColor : AppTheme.backgroundColor),
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 4) : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                  : (isCurrent ? const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20) : null),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              child: Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500, color: isCurrent ? AppTheme.textPrimary : AppTheme.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            if (date != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        if (!isLast)
          Container(
            width: 60,
            height: 2,
            margin: const EdgeInsets.only(bottom: 60),
            color: isCompleted ? Colors.green : AppTheme.borderColor,
          ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(AppTheme.cardRadius), topRight: Radius.circular(AppTheme.cardRadius)),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _optionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty || normalized == '-') {
      return 'Option not available';
    }
    return normalized;
  }

  Map<String, String> _resolveAllotmentDisplay(
    InventoryAllotment allotment,
    InventoryState inventoryState,
  ) {
    try {
      if (allotment.itemType == InventoryItemType.panel) {
        final item = inventoryState.panels.firstWhere((p) => p.id == allotment.itemId);
        return {
          'serial': item.serialNumber,
          'details': '${item.brand} - ${item.wattCapacity}W (${item.panelType})',
        };
      }
      if (allotment.itemType == InventoryItemType.inverter) {
        final item = inventoryState.inverters.firstWhere((i) => i.id == allotment.itemId);
        return {
          'serial': item.serialNumber,
          'details': '${item.brand} - ${item.capacityKw}kW (${item.inverterType})',
        };
      }
      final item = inventoryState.meters.firstWhere((m) => m.id == allotment.itemId);
      return {
        'serial': item.serialNumber,
        'details': '${item.brand} - ${item.meterCategory} (${item.meterPhase})',
      };
    } catch (_) {
      return {
        'serial': 'ID: ${allotment.itemId}',
        'details': allotment.itemType.name.toUpperCase(),
      };
    }
  }

  Widget _buildDocumentsSection(ApplicationModel app) {
    final documentsAsync = ref.watch(documentsProvider(app.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(AppTheme.cardRadius), topRight: Radius.circular(AppTheme.cardRadius)),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder_outlined, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 12),
                    Text('Documentation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUploadDocumentDialog(context, app),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.upload_rounded, size: 16),
                  label: const Text('Upload File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          documentsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
            error: (error, stack) => const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('Failed to load documents'))),
            data: (documents) {
              if (documents.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.folder_open_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No documents uploaded yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
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

  void _showUploadDocumentDialog(BuildContext context, ApplicationModel app) {
    String selectedDocType = AppConstants.documentTypes.first;
    PlatformFile? pickedFile;
    bool isUploading = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 480,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upload Document',
                              style: AppTextStyles.heading3,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed:
                                  isUploading ? null : () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${app.applicationNumber} • ${app.fullName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        DropdownButtonFormField<String>(
                          value: selectedDocType,
                          decoration: const InputDecoration(
                            labelText: 'Document Type',
                            prefixIcon: Icon(Icons.label_outline_rounded),
                          ),
                          items:
                              AppConstants.documentTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                          onChanged:
                              isUploading
                                  ? null
                                  : (val) => setDialogState(
                                    () => selectedDocType = val!,
                                  ),
                        ),
                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap:
                              isUploading
                                  ? null
                                  : () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: [
                                            'pdf',
                                            'jpg',
                                            'jpeg',
                                            'png',
                                            'doc',
                                            'docx',
                                          ],
                                          withData: true, // Required for web
                                        );
                                    if (result != null &&
                                        result.files.isNotEmpty) {
                                      setDialogState(() {
                                        pickedFile = result.files.first;
                                        errorMsg = null;
                                      });
                                    }
                                  },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  pickedFile != null
                                      ? AppTheme.successColor.withOpacity(0.05)
                                      : AppTheme.backgroundColor,
                              border: Border.all(
                                color:
                                    pickedFile != null
                                        ? AppTheme.successColor.withOpacity(0.4)
                                        : AppTheme.borderColor,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                pickedFile == null
                                    ? Column(
                                      children: [
                                        Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 40,
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Click to select file',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF, JPG, PNG, DOC supported',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                        ),
                                      ],
                                    )
                                    : Row(
                                      children: [
                                        Icon(
                                          pickedFile!.extension
                                                      ?.toLowerCase() ==
                                                  'pdf'
                                              ? Icons.picture_as_pdf_rounded
                                              : Icons.image_rounded,
                                          color:
                                              pickedFile!.extension
                                                          ?.toLowerCase() ==
                                                      'pdf'
                                                  ? Colors.red
                                                  : Colors.blue,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pickedFile!.name,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color:
                                                          AppTheme
                                                              .textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                          onPressed:
                                              () => setDialogState(
                                                () => pickedFile = null,
                                              ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),

                        if (errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMsg!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                (isUploading || pickedFile == null)
                                    ? null
                                    : () async {
                                      if (pickedFile?.bytes == null) {
                                        setDialogState(() {
                                          errorMsg =
                                              'File data not loaded. Please select again.';
                                        });
                                        return;
                                      }

                                      setDialogState(() {
                                        isUploading = true;
                                        errorMsg = null;
                                      });

                                      try {
                                        final ext =
                                            pickedFile!.extension
                                                ?.toLowerCase() ??
                                            'bin';
                                        final mimeType =
                                            ext == 'pdf'
                                                ? 'application/pdf'
                                                : (ext == 'png'
                                                    ? 'image/png'
                                                    : ext == 'jpg' ||
                                                        ext == 'jpeg'
                                                    ? 'image/jpeg'
                                                    : 'application/octet-stream');

                                        await DocumentService.uploadDocument(
                                          applicationId: app.id,
                                          documentType: selectedDocType,
                                          fileBytes: pickedFile!.bytes!,
                                          fileName: pickedFile!.name,
                                          mimeType: mimeType,
                                        );

                                        ref.invalidate(
                                          documentsProvider(app.id),
                                        );

                                        if (ctx.mounted) Navigator.pop(ctx);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${pickedFile!.name} uploaded successfully!',
                                              ),
                                              backgroundColor:
                                                  AppTheme.successColor,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          isUploading = false;
                                          errorMsg =
                                              'Upload failed: ${e.toString()}';
                                        });
                                      }
                                    },
                            icon:
                                isUploading
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.upload_rounded),
                            label: Text(
                              isUploading ? 'Uploading...' : 'Upload Document',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildDocumentsTable(List<DocumentModel> documents) {
    final canEditApplication = ref.watch(currentUserProvider).value?.canEdit ?? false;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 48, child: Text('SR.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
              Expanded(flex: 2, child: Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
              Expanded(flex: 3, child: Text('FILE NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
              Expanded(child: Text('UPLOADED BY / DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
              Expanded(child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
              SizedBox(width: 120, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary), textAlign: TextAlign.right)),
            ],
          ),
        ),
        ...documents.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text('${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text(doc.documentType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, size: 16, color: doc.isPdf ? Colors.red : AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(doc.fileName, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.uploadedBy ?? '-', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      Text(DateFormat('dd MMM yyyy').format(doc.uploadedOn), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _getDocStatusColor(doc.verificationStatus).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(doc.verificationStatus.toUpperCase(), style: TextStyle(fontSize: 10, color: _getDocStatusColor(doc.verificationStatus), fontWeight: FontWeight.w800)),
                          ),
                          if (doc.verifiedBy != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'By: ${doc.verifiedBy}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () => _viewDocument(doc), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 16),
                      IconButton(icon: const Icon(Icons.download_outlined, size: 18), onPressed: () => _viewDocument(doc), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      if (canEditApplication && doc.verificationStatus == 'pending') ...[
                        const SizedBox(width: 16),
                        IconButton(icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green), onPressed: () => _updateDocumentStatus(doc.id, 'verified'), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getDocStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.warningColor;
    }
  }


  Future<void> _viewDocument(DocumentModel doc) async {
    final url = doc.fileUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')),
          );
        }
      }
    }
  }

  Future<void> _updateDocumentStatus(String documentId, String status) async {
    try {
      await DocumentService.verifyDocument(
        documentId: documentId,
        status: status,
      );
      
      // Update the whole list or just the specific app
      ref.invalidate(documentsProvider(widget.applicationId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document ${status == 'verified' ? 'verified' : 'rejected'}'),
            backgroundColor: status == 'verified' ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
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
    final canEditApplication = ref.watch(currentUserProvider).value?.canEdit ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            InkWell(
              onTap: canEditApplication ? () => _updateStatus(status) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
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
                    if (isCurrent && !canEditApplication) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Admin update only',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
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
    }
  }

  String _getResponsibleParty(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applicationReceived:
      case ApplicationStatus.documentsVerified:
      case ApplicationStatus.siteSurveyPending:
      case ApplicationStatus.siteSurveyCompleted:
      case ApplicationStatus.solarDemandPending:
      case ApplicationStatus.solarDemandDeposit:
      case ApplicationStatus.meterTested:
      case ApplicationStatus.installationScheduled:
      case ApplicationStatus.installationCompleted:
      case ApplicationStatus.subsidyProcess:
        return 'Admin/Staff';
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
        return AppTheme.warningColor;
      case ApplicationStatus.subsidyProcess:
        return AppTheme.statusCompleted;
    }
  }

  List<PopupMenuEntry<String>> _buildActionMenuItems(ApplicationModel app) {
    final items = <PopupMenuEntry<String>>[];
    final currentUser = ref.read(currentUserProvider).value;
    final canEditApplication = currentUser?.canEdit ?? false;
    final canAccessInventory = currentUser?.canAccessInventory ?? false;
    final canManageInstallations =
        currentUser?.canManageInstallations ?? false;

    final currentIndex = app.currentStatus.index;
    final canAdvance = currentIndex < ApplicationStatus.values.length - 1;

    if (canAdvance && canEditApplication) {
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

    switch (app.currentStatus) {
      case ApplicationStatus.applicationReceived:
      case ApplicationStatus.documentsVerified:
      case ApplicationStatus.siteSurveyPending:
      case ApplicationStatus.siteSurveyCompleted:
      case ApplicationStatus.solarDemandPending:
      case ApplicationStatus.solarDemandDeposit:
      case ApplicationStatus.meterTested:
      case ApplicationStatus.installationScheduled:
      case ApplicationStatus.installationCompleted:
      case ApplicationStatus.subsidyProcess:
        break;
    }

    if (canEditApplication && items.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }
    if (canEditApplication) {
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
    }
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
    
    if (canAccessInventory) {
      items.add(
        const PopupMenuItem(
          value: 'allot_solar',
          child: Row(
            children: [
              Icon(Icons.solar_power_rounded, size: 18),
              SizedBox(width: 12),
              Text('Allot Solar / Inventory'),
            ],
          ),
        ),
      );
    }
    
    if (canManageInstallations &&
        app.statusIndex >= ApplicationStatus.installationScheduled.index) {
      items.add(
        const PopupMenuItem(
          value: 'view_installation',
          child: Row(
            children: [
              Icon(Icons.plumbing_rounded, size: 18),
              SizedBox(width: 12),
              Text('View Installation'),
            ],
          ),
        ),
      );
    }

    if (canEditApplication) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider());
      }
      items.add(
        const PopupMenuItem(
          value: 'delete_application',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppTheme.errorColor,
              ),
              SizedBox(width: 12),
              Text('Delete Application'),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const PopupMenuItem(
          enabled: false,
          child: Text('No actions available'),
        ),
      );
    }

    return items;
  }

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
      case 'update_status':
        await _updateStatus();
        return;
      case 'view_history':
        await _showStatusHistoryDialog(app);
        return;
      case 'view_installation':
        context.go('/installations');
        return;
      case 'allot_solar':
        _showInventoryAllotmentDialog(app);
        return;
      case 'delete_application':
        await _confirmDeleteApplication(app);
        return;
      default:
        return;
    }

    if (newStatus != null) {
      await _updateApplicationStatus(app, newStatus, actionRemarks);
    }
  }

  Future<void> _confirmDeleteApplication(ApplicationModel app) async {
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

    if (confirmed != true) return;

    await ref.read(applicationsProvider.notifier).deleteApplication(app.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application deleted successfully.')),
    );
    context.go('/applications');
  }

  Future<void> _updateApplicationStatus(
    ApplicationModel app,
    ApplicationStatus newStatus,
    String? remarks,
  ) async {
    var loaderShown = false;
    showDialog(
      context: context,
      useRootNavigator: true,
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
    loaderShown = true;

    try {
      if (newStatus == ApplicationStatus.installationScheduled) {
        await InstallationService.initializeInstallation(
          applicationId: app.id,
          applicationNumber: app.applicationNumber,
          consumerName: app.fullName,
        );
      }

      final result = await ref
          .read(applicationsProvider.notifier)
          .updateApplicationStatus(
            applicationId: app.id,
            newStatus: newStatus,
            stageStatus: StageStatus.completed,
            remarks: remarks,
          );

      if (mounted && loaderShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loaderShown = false;
      }

      if (result != null) {
        ref.invalidate(applicationProvider(widget.applicationId));
        await ref.refresh(applicationProvider(widget.applicationId).future);

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
      if (mounted && loaderShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loaderShown = false;
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

  Future<void> _updateStatus([ApplicationStatus? preSelectedStatus]) async {
    final applicationAsync = ref.read(applicationProvider(widget.applicationId));
    final app = applicationAsync.value;
    if (app == null) return;

    ApplicationStatus? selectedStatus = preSelectedStatus ?? app.currentStatus;
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

    var loadingShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        if (loadingShown && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }

      ApplicationModel? updatedApplication;
      switch (action) {
        case 'approve':
          updatedApplication = await ApplicationService.approveApplication(
            app,
            currentUser.id,
            remarks:
                remarksController.text.isNotEmpty
                    ? remarksController.text
                    : null,
          );
          break;
        case 'reject':
          updatedApplication = await ApplicationService.rejectApplication(
            app,
            currentUser.id,
            remarks: remarksController.text,
          );
          break;
        case 'changes':
          updatedApplication = await ApplicationService.requestChanges(
            app,
            currentUser.id,
            remarksController.text,
          );
          break;
      }

      if (loadingShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingShown = false;
      }

      if (mounted && updatedApplication != null) {
        setState(() {
          _applicationOverride = updatedApplication;
        });
      }

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
        if (loadingShown) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildPaymentSection(ApplicationModel app) {
    final paymentStatsAsync = ref.watch(paymentStatsProvider((id: app.id, total: app.finalAmount ?? 0.0)));
    final paymentsAsync = ref.watch(paymentsProvider(app.id));
    final canManagePayments = ref.watch(currentUserProvider).value?.canEdit ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(AppTheme.cardRadius), topRight: Radius.circular(AppTheme.cardRadius)),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payments_outlined, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 12),
                    Text('Payment Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final payments = await ref.read(paymentsProvider(app.id).future);
                        await _exportPaymentSummaryPdf(app, payments);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Export PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPaymentDialog(app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('New Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                paymentStatsAsync.when(
                  data: (stats) => Row(
                    children: [
                      _buildStatItem('Total Amount', stats['totalAmount']!, Icons.account_balance_wallet_outlined, Colors.blue),
                      const SizedBox(width: 16),
                      _buildStatItem('Paid Amount', stats['totalPaid']!, Icons.check_circle_outline_rounded, Colors.green),
                      const SizedBox(width: 16),
                      _buildStatItem('Remaining', stats['remainingAmount']!, Icons.pending_actions_rounded, Colors.orange),
                    ],
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading stats: $e'),
                ),
                const SizedBox(height: 32),
                const Text('Transaction History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                paymentsAsync.when(
                  data: (payments) => payments.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No payments recorded yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                              headingRowHeight: 48,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 60,
                              headingRowColor: WidgetStateProperty.all(AppTheme.backgroundColor),
                              horizontalMargin: 24,
                              columns: [
                                DataColumn(label: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                DataColumn(label: Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                DataColumn(label: Text('MODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                DataColumn(label: Text('TRANSACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                DataColumn(label: Text('COLLECTED BY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                DataColumn(label: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                DataColumn(label: Text('RECEIPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                                if (canManagePayments)
                                  const DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary))),
                              ],
                              rows: payments.map((p) => DataRow(cells: [
                                DataCell(Text(DateFormat('dd MMM yyyy').format(p.paymentDate), style: const TextStyle(fontSize: 13))),
                                DataCell(Text(p.paymentType.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                DataCell(Text(p.paymentMode.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                DataCell(Text(p.transactionNumber ?? '-', style: const TextStyle(fontSize: 13))),
                                DataCell(Text(p.collectedBy ?? '-', style: const TextStyle(fontSize: 13))),
                                DataCell(Text(
                                  '₹${NumberFormat('#,##,###', 'en_IN').format(p.amount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green, fontSize: 13),
                                )),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                                    onPressed: () => _downloadPaymentReceipt(app, p),
                                    tooltip: 'Download Receipt',
                                  ),
                                ),
                                if (canManagePayments)
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, size: 18),
                                          onPressed: () => _showEditPaymentDialog(app, p),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorColor),
                                          onPressed: () => _confirmDeletePayment(app, p),
                                        ),
                                      ],
                                    ),
                                  ),
                              ])).toList(),
                              ),
                            ),
                          ),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading payments: $e'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '₹${NumberFormat('#,##,###', 'en_IN').format(value)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPaymentSummaryPdf(
    ApplicationModel app,
    List<PaymentModel> payments,
  ) async {
    if (payments.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No payments available to export.')),
        );
      }
      return;
    }

    final document = PdfDocument();
    final page = document.pages.add();
    final pageWidth = page.getClientSize().width;
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      14,
      style: PdfFontStyle.bold,
    );
    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.bold,
    );
    final cellFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    double y = 0;
    page.graphics.drawString(
      'Payment Summary - ${app.applicationNumber}',
      titleFont,
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    y += 20;
    page.graphics.drawString(
      '${app.fullName} | ${app.mobile}',
      cellFont,
      bounds: Rect.fromLTWH(0, y, pageWidth, 14),
    );
    y += 20;

    const headers = ['Date', 'Type', 'Mode', 'Transaction', 'Collected By', 'Amount'];
    const widths = [70.0, 55.0, 55.0, 110.0, 120.0, 70.0];
    double x = 0;
    for (var i = 0; i < headers.length; i++) {
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(30, 64, 175)),
        bounds: Rect.fromLTWH(x, y, widths[i], 18),
      );
      page.graphics.drawString(
        headers[i],
        headerFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(x + 2, y + 3, widths[i] - 4, 12),
      );
      x += widths[i];
    }
    y += 18;

    for (final payment in payments) {
      x = 0;
      final row = [
        DateFormat('dd MMM yyyy').format(payment.paymentDate),
        payment.paymentType.name.toUpperCase(),
        payment.paymentMode.name.toUpperCase(),
        payment.transactionNumber?.trim().isNotEmpty == true
            ? payment.transactionNumber!
            : '-',
        payment.collectedBy ?? '-',
        'Rs.${NumberFormat('#,##,###', 'en_IN').format(payment.amount)}',
      ];
      for (var i = 0; i < row.length; i++) {
        page.graphics.drawString(
          row[i],
          cellFont,
          bounds: Rect.fromLTWH(x + 2, y + 3, widths[i] - 4, 12),
        );
        x += widths[i];
      }
      y += 16;
    }

    final bytes = document.saveSync();
    document.dispose();

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Payment Summary PDF',
      fileName: 'payment_summary_${app.applicationNumber}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (path == null) return;

    await File(path).writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment PDF exported successfully.')),
      );
    }
  }

  Future<void> _exportInventoryAllotmentsPdf(
    ApplicationModel app,
    List<InventoryAllotment> allotments,
    InventoryState inventoryState,
  ) async {
    if (allotments.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No inventory allotments available to export.')),
        );
      }
      return;
    }

    final document = PdfDocument();
    final page = document.pages.add();
    final pageWidth = page.getClientSize().width;
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      14,
      style: PdfFontStyle.bold,
    );
    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      8,
      style: PdfFontStyle.bold,
    );
    final cellFont = PdfStandardFont(PdfFontFamily.helvetica, 7);

    double y = 0;
    page.graphics.drawString(
      'Inventory Allotment - ${app.applicationNumber}',
      titleFont,
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    y += 20;
    page.graphics.drawString(
      '${app.fullName} | ${app.mobile}',
      cellFont,
      bounds: Rect.fromLTWH(0, y, pageWidth, 14),
    );
    y += 20;

    const headers = ['Type', 'Serial No.', 'Details', 'Assigned By', 'Date'];
    const widths = [60.0, 110.0, 170.0, 120.0, 70.0];
    double x = 0;
    for (var i = 0; i < headers.length; i++) {
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(30, 64, 175)),
        bounds: Rect.fromLTWH(x, y, widths[i], 18),
      );
      page.graphics.drawString(
        headers[i],
        headerFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(x + 2, y + 3, widths[i] - 4, 12),
      );
      x += widths[i];
    }
    y += 18;

    for (final allotment in allotments) {
      x = 0;
      final resolved = _resolveAllotmentDisplay(allotment, inventoryState);
      final row = [
        allotment.itemType.name.toUpperCase(),
        resolved['serial'] ?? '-',
        resolved['details'] ?? '-',
        allotment.handoverBy ?? '-',
        DateFormat('dd MMM yyyy').format(allotment.handoverDate),
      ];
      for (var i = 0; i < row.length; i++) {
        page.graphics.drawString(
          row[i],
          cellFont,
          bounds: Rect.fromLTWH(x + 2, y + 3, widths[i] - 4, 12),
        );
        x += widths[i];
      }
      y += 16;
    }

    final bytes = document.saveSync();
    document.dispose();

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Inventory Allotment PDF',
      fileName: 'inventory_allotment_${app.applicationNumber}.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (path == null) return;

    await File(path).writeAsBytes(bytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory allotment PDF exported successfully.')),
      );
    }
  }

  Future<void> _confirmDeletePayment(
    ApplicationModel app,
    PaymentModel payment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Delete payment of Rs.${NumberFormat('#,##,###', 'en_IN').format(payment.amount)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PaymentService.deletePayment(
        payment.id,
        receiptFilePath: payment.receiptFilePath,
      );
      ref.invalidate(paymentsProvider(app.id));
      ref.invalidate(allPaymentsProvider);
      ref.invalidate(
        paymentStatsProvider((id: app.id, total: app.finalAmount ?? 0.0)),
      );
      await ref.refresh(paymentsProvider(app.id).future);
      await ref.refresh(
        paymentStatsProvider((id: app.id, total: app.finalAmount ?? 0.0)).future,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showEditPaymentDialog(
    ApplicationModel app,
    PaymentModel payment,
  ) async {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(0),
    );
    final transactionController = TextEditingController(
      text: payment.transactionNumber ?? '',
    );
    final remarksController = TextEditingController(
      text: payment.remarks ?? '',
    );
    PaymentMode selectedMode = payment.paymentMode;
    PaymentType selectedType = payment.paymentType;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Rs.)',
                    prefixText: 'Rs. ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Payment Type'),
                  items: PaymentType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMode>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: PaymentMode.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedMode = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: transactionController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Number / Reference',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (Optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid payment amount.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                final updatedPayment = payment.copyWith(
                  amount: amount,
                  paymentMode: selectedMode,
                  paymentType: selectedType,
                  transactionNumber: transactionController.text.trim(),
                  remarks: remarksController.text.trim(),
                );

                final paymentWithReceipt = await _attachPaymentReceipt(
                  app,
                  updatedPayment,
                );
                await PaymentService.updatePayment(paymentWithReceipt);
                ref.invalidate(paymentsProvider(app.id));
                ref.invalidate(allPaymentsProvider);
                ref.invalidate(
                  paymentStatsProvider((id: app.id, total: app.finalAmount ?? 0.0)),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment updated successfully.'),
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _sanitizeReceiptFileName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Uint8List _buildPaymentReceiptPdfBytes(
    ApplicationModel app,
    PaymentModel payment,
  ) {
    final document = PdfDocument();
    final page = document.pages.add();
    final pageSize = page.getClientSize();

    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      18,
      style: PdfFontStyle.bold,
    );
    final headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      11,
      style: PdfFontStyle.bold,
    );
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

    double y = 0;

    page.graphics.drawString(
      AppConstants.companyName,
      titleFont,
      brush: PdfSolidBrush(PdfColor(30, 64, 175)),
      bounds: Rect.fromLTWH(0, y, pageSize.width, 24),
    );
    y += 28;

    page.graphics.drawString(
      'Payment Receipt',
      PdfStandardFont(
        PdfFontFamily.helvetica,
        14,
        style: PdfFontStyle.bold,
      ),
      bounds: Rect.fromLTWH(0, y, pageSize.width, 18),
    );
    y += 26;

    final rows = <List<String>>[
      ['Consumer Name', app.fullName],
      ['Application No.', app.applicationNumber],
      ['Mobile Number', app.mobile],
      ['Payment Date', DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate)],
      ['Payment Type', payment.paymentType.name.toUpperCase()],
      ['Payment Mode', payment.paymentMode.name.toUpperCase()],
      ['Transaction No.', (payment.transactionNumber?.trim().isNotEmpty ?? false) ? payment.transactionNumber! : '-'],
      ['Amount Received', 'Rs.${NumberFormat('#,##,###', 'en_IN').format(payment.amount)}'],
      ['Collected By', payment.collectedBy ?? '-'],
      ['Remarks', (payment.remarks?.trim().isNotEmpty ?? false) ? payment.remarks! : '-'],
    ];

    for (final row in rows) {
      page.graphics.drawString(
        row[0],
        headerFont,
        bounds: Rect.fromLTWH(0, y, 140, 16),
      );
      page.graphics.drawString(
        row[1],
        bodyFont,
        bounds: Rect.fromLTWH(150, y, pageSize.width - 150, 16),
      );
      y += 22;
    }

    y += 12;
    page.graphics.drawLine(
      PdfPen(PdfColor(200, 200, 200), width: 1),
      Offset(0, y),
      Offset(pageSize.width, y),
    );
    y += 12;

    page.graphics.drawString(
      'Receipt generated automatically after payment entry.',
      PdfStandardFont(PdfFontFamily.helvetica, 9),
      brush: PdfSolidBrush(PdfColor(110, 110, 110)),
      bounds: Rect.fromLTWH(0, y, pageSize.width, 14),
    );

    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }

  Future<PaymentModel> _attachPaymentReceipt(
    ApplicationModel app,
    PaymentModel payment,
  ) async {
    final bytes = _buildPaymentReceiptPdfBytes(app, payment);
    final upload = await PaymentService.uploadReceiptPdf(
      applicationId: app.id,
      paymentId: payment.id,
      bytes: bytes,
    );

    return payment.copyWith(
      receiptFilePath: upload['path'],
      receiptFileUrl: upload['url'],
    );
  }

  Future<PaymentModel> _ensurePaymentReceipt(
    ApplicationModel app,
    PaymentModel payment,
  ) async {
    if ((payment.receiptFileUrl?.trim().isNotEmpty ?? false) &&
        (payment.receiptFilePath?.trim().isNotEmpty ?? false)) {
      return payment;
    }

    final paymentWithReceipt = await _attachPaymentReceipt(app, payment);
    await PaymentService.updateReceiptFields(
      paymentId: payment.id,
      receiptFilePath: paymentWithReceipt.receiptFilePath!,
      receiptFileUrl: paymentWithReceipt.receiptFileUrl!,
    );
    ref.invalidate(paymentsProvider(app.id));
    ref.invalidate(allPaymentsProvider);
    return paymentWithReceipt;
  }

  Future<void> _downloadPaymentReceipt(
    ApplicationModel app,
    PaymentModel payment,
  ) async {
    try {
      final ensuredPayment = await _ensurePaymentReceipt(app, payment);
      final bytes = _buildPaymentReceiptPdfBytes(app, ensuredPayment);
      final consumerName = _sanitizeReceiptFileName(app.fullName);
      final receiptDate = DateFormat('yyyyMMdd_HHmm').format(
        ensuredPayment.paymentDate,
      );

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Download Payment Receipt',
        fileName: '${consumerName}_payment_receipt_$receiptDate.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (path == null) return;

      await File(path).writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt downloaded successfully.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt download failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAddPaymentDialog(ApplicationModel app) {
    final amountController = TextEditingController();
    final transactionController = TextEditingController();
    final remarksController = TextEditingController();
    PaymentMode selectedMode = PaymentMode.cash;
    PaymentType selectedType = PaymentType.partial;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)', prefixText: 'Rs. '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Payment Type'),
                  items: PaymentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMode>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: PaymentMode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => selectedMode = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: transactionController,
                  decoration: const InputDecoration(labelText: 'Transaction Number / Reference'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid payment amount.'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                  return;
                }

                final now = DateTime.now();
                final payment = PaymentModel(
                  id: const Uuid().v4(),
                  applicationId: app.id,
                  amount: amount,
                  paymentMode: selectedMode,
                  paymentType: selectedType,
                  transactionNumber: transactionController.text.trim(),
                  paymentDate: now,
                  remarks: remarksController.text.trim(),
                  collectedBy:
                      ref.read(currentUserProvider).value?.fullName ??
                      ref.read(currentUserProvider).value?.email,
                  createdAt: now,
                );

                try {
                  final paymentWithReceipt = await _attachPaymentReceipt(
                    app,
                    payment,
                  );
                  final savedPayment = await PaymentService.addPayment(
                    paymentWithReceipt,
                  );
                  ref.invalidate(paymentsProvider(app.id));
                  ref.invalidate(allPaymentsProvider);
                  ref.invalidate(
                    paymentStatsProvider((id: app.id, total: app.finalAmount ?? 0.0)),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Payment added successfully.'),
                        backgroundColor: AppTheme.successColor,
                        action: SnackBarAction(
                          label: 'Download Receipt',
                          textColor: Colors.white,
                          onPressed: () => _downloadPaymentReceipt(app, savedPayment),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add payment: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInventoryAllotmentDialog(ApplicationModel app) {
    int currentStep = 0;
    InventoryItemType selectedType = InventoryItemType.panel;
    String? selectedBrand;
    String? selectedCategory;
    List<String> selectedItemIds = [];

    // Ensure inventory is loaded
    final currentInventory = ref.read(inventoryProvider);
    if (currentInventory.panels.isEmpty && !currentInventory.isLoading) {
      ref.read(inventoryProvider.notifier).loadAll();
    }

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final inventoryState = ref.watch(inventoryProvider);
          
          return StatefulBuilder(
            builder: (context, setDialogState) {
              
              List<String> getAvailableBrands() {
                if (selectedType == InventoryItemType.panel) {
                  return inventoryState.panels.where((p) => p.status == 'available').map((p) => p.brand).toSet().toList();
                } else if (selectedType == InventoryItemType.inverter) {
                  return inventoryState.inverters.where((i) => i.status == 'available').map((i) => i.brand).toSet().toList();
                } else {
                  return inventoryState.meters.where((m) => m.status == 'available').map((m) => m.brand).toSet().toList();
                }
              }

              List<String> getAvailableCategories(String brand) {
                if (selectedType == InventoryItemType.panel) {
                  return inventoryState.panels.where((p) => p.status == 'available' && p.brand == brand).map((p) => p.panelType).toSet().toList();
                } else if (selectedType == InventoryItemType.inverter) {
                  return inventoryState.inverters.where((i) => i.status == 'available' && i.brand == brand).map((i) => i.inverterType).toSet().toList();
                } else {
                  return inventoryState.meters.where((m) => m.status == 'available' && m.brand == brand).map((m) => m.meterCategory).toSet().toList();
                }
              }

              List<dynamic> getFilteredItems() {
                if (selectedType == InventoryItemType.panel) {
                  return inventoryState.panels.where((p) => p.status == 'available' && p.brand == selectedBrand && p.panelType == selectedCategory).toList();
                } else if (selectedType == InventoryItemType.inverter) {
                  return inventoryState.inverters.where((i) => i.status == 'available' && i.brand == selectedBrand && i.inverterType == selectedCategory).toList();
                } else {
                  return inventoryState.meters.where((m) => m.status == 'available' && m.brand == selectedBrand && m.meterCategory == selectedCategory).toList();
                }
              }

              return AlertDialog(
                title: Text(currentStep == 0 ? 'Allot: Select Item & Brand' : currentStep == 1 ? 'Select Category' : 'Choose Serial Numbers'),
                content: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (inventoryState.isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        else if (currentStep == 0) ...[
                          DropdownButtonFormField<InventoryItemType>(
                            value: selectedType,
                            decoration: const InputDecoration(labelText: 'Item Type'),
                            items: InventoryItemType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                            onChanged: (v) => setDialogState(() {
                              selectedType = v!;
                              selectedBrand = null;
                            }),
                          ),
                          const SizedBox(height: 16),
                          const Text('Select Brand:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 12),
                          if (getAvailableBrands().isEmpty)
                            const Text('No stock available for this type.', style: TextStyle(color: Colors.red, fontSize: 12))
                          else
                            Wrap(
                              spacing: 8,
                              children: getAvailableBrands().map((brand) => ChoiceChip(
                                label: Text(brand),
                                selected: selectedBrand == brand,
                                onSelected: (s) {
                                  if (s) {
                                    setDialogState(() {
                                      selectedBrand = brand;
                                      selectedCategory = null;
                                      currentStep = 1;
                                    });
                                  }
                                },
                              )).toList(),
                            ),
                        ]
                        else if (currentStep == 1) ...[
                          Text('Brand: $selectedBrand', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text('Select Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: getAvailableCategories(selectedBrand!).map((cat) => ChoiceChip(
                              label: Text(cat),
                              selected: selectedCategory == cat,
                              onSelected: (s) {
                                if (s) {
                                  setDialogState(() {
                                    selectedCategory = cat;
                                    selectedItemIds = [];
                                    currentStep = 2;
                                  });
                                }
                              },
                            )).toList(),
                          ),
                        ]
                        else if (currentStep == 2) ...[
                          Text('$selectedBrand - $selectedCategory', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Available stock: ${getFilteredItems().length}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const Divider(),
                          const SizedBox(height: 8),
                          ...getFilteredItems().map((item) {
                            String sn = '';
                            String id = '';
                            String sub = '';
                            if (item is PanelItem) { sn = item.serialNumber; id = item.id; sub = '${item.wattCapacity}W'; }
                            else if (item is InverterItem) { sn = item.serialNumber; id = item.id; sub = '${item.capacityKw}kW'; }
                            else if (item is MeterItem) { sn = item.serialNumber; id = item.id; sub = item.meterPhase; }

                            return CheckboxListTile(
                              title: Text(sn),
                              subtitle: Text(sub, style: const TextStyle(fontSize: 10)),
                              value: selectedItemIds.contains(id),
                              onChanged: (v) {
                                setDialogState(() {
                                  if (v!) selectedItemIds.add(id);
                                  else selectedItemIds.remove(id);
                                });
                              },
                              dense: true,
                            );
                          }).toList(),
                          if (getFilteredItems().isEmpty)
                            const Text('No items found.', style: TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  if (currentStep > 0)
                    TextButton(onPressed: () => setDialogState(() => currentStep--), child: const Text('Back')),
                  if (currentStep == 2)
                    ElevatedButton(
                      onPressed: selectedItemIds.isEmpty ? null : () async {
                        final user = ref.read(currentUserProvider).value;
                        await ref.read(inventoryProvider.notifier).allotMultipleItems(
                          itemIds: selectedItemIds,
                          itemType: selectedType,
                          customerName: app.fullName,
                          applicationId: app.id,
                          handoverBy: user?.fullName ?? 'System',
                          handoverDate: DateTime.now(),
                        );
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Allot Selected'),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
