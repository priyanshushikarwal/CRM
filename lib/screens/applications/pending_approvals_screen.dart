import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/application_model.dart';
import '../../services/application_service.dart';
import '../../providers/app_providers.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState
    extends ConsumerState<PendingApprovalsScreen> {
  List<ApplicationModel> _pendingApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingApplications();
  }

  Future<void> _loadPendingApplications() async {
    setState(() => _isLoading = true);
    try {
      final applications = await ApplicationService.fetchPendingApprovals();
      setState(() {
        _pendingApplications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pending applications: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _pendingApplications.isEmpty
                    ? _buildEmptyState()
                    : _buildApplicationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending Approvals', style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text(
                  '${_pendingApplications.length} applications waiting for your review',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: _loadPendingApplications,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: AppTheme.successColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: AppTextStyles.heading3.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending applications to review',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _pendingApplications.length,
      itemBuilder: (context, index) {
        final app = _pendingApplications[index];
        return _buildApplicationCard(app);
      },
    );
  }

  Widget _buildApplicationCard(ApplicationModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pending_actions_rounded,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.fullName, style: AppTextStyles.heading4),
                      const SizedBox(height: 4),
                      Text(
                        app.applicationNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pending Review',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Card Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Application details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.location_on_outlined,
                        'District',
                        app.district,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.phone_outlined,
                        'Mobile',
                        '+91 ${app.mobile}',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.solar_power_outlined,
                        'Capacity',
                        '${app.proposedCapacity} kW',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.calendar_today_outlined,
                        'Submitted',
                        DateFormat('dd MMM yyyy').format(app.createdAt),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Action buttons
                Row(
                  children: [
                    // View Details button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go('/applications/${app.id}');
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Approve button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApprovalDialog(app, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Request Changes button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showChangesDialog(app),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningColor,
                        ),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Request Changes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reject button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApprovalDialog(app, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showApprovalDialog(ApplicationModel app, bool isApprove) async {
    final remarksController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color:
                      isApprove ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: 12),
                Text(isApprove ? 'Approve Application' : 'Reject Application'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isApprove
                        ? 'Are you sure you want to approve this application?'
                        : 'Are you sure you want to reject this application?',
                    style: AppTextStyles.bodyMedium,
                  ),
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
                          isApprove
                              ? 'Remarks (optional)'
                              : 'Reason for rejection *',
                      hintText:
                          isApprove
                              ? 'Add any notes...'
                              : 'Please provide a reason for rejection',
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
                  if (!isApprove && remarksController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a reason for rejection'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isApprove ? AppTheme.successColor : AppTheme.errorColor,
                ),
                child: Text(isApprove ? 'Approve' : 'Reject'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) return;

        if (isApprove) {
          await ApplicationService.approveApplication(
            app,
            currentUser.id,
            remarks:
                remarksController.text.isNotEmpty
                    ? remarksController.text
                    : null,
          );
        } else {
          await ApplicationService.rejectApplication(
            app,
            currentUser.id,
            remarks: remarksController.text,
          );
        }

        await _loadPendingApplications();
        ref.read(applicationsProvider.notifier).loadApplications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isApprove
                    ? 'Application approved successfully!'
                    : 'Application rejected',
              ),
              backgroundColor:
                  isApprove ? AppTheme.successColor : AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _showChangesDialog(ApplicationModel app) async {
    final remarksController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppTheme.warningColor),
                const SizedBox(width: 12),
                const Text('Request Changes'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please specify what changes are needed for this application.',
                    style: AppTextStyles.bodyMedium,
                  ),
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
                    decoration: const InputDecoration(
                      labelText: 'Required Changes *',
                      hintText: 'Describe the changes needed...',
                    ),
                    maxLines: 4,
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
                  if (remarksController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please describe the required changes'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                ),
                child: const Text('Send Request'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) return;

        await ApplicationService.requestChanges(
          app,
          currentUser.id,
          remarksController.text,
        );

        await _loadPendingApplications();
        ref.read(applicationsProvider.notifier).loadApplications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Change request sent to the employee'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
}
