import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/installation_model.dart';
import '../../providers/app_providers.dart';

class InstallationsListScreen extends ConsumerStatefulWidget {
  const InstallationsListScreen({super.key});

  @override
  ConsumerState<InstallationsListScreen> createState() => _InstallationsListScreenState();
}

class _InstallationsListScreenState extends ConsumerState<InstallationsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(installationsProvider.notifier).loadInstallations());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(installationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Installation Management', style: AppTextStyles.heading2),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and track solar installations',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => ref.read(installationsProvider.notifier).loadInstallations(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(child: Text('Error: ${state.error}'))
                      : state.installations.isEmpty
                          ? _buildEmptyState()
                          : _buildInstallationsTable(state.installations),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.plumbing_rounded, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No installations found', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Text('Installations will appear here once applications are approved.',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildInstallationsTable(List<InstallationModel> installations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.primaryColor.withOpacity(0.05)),
            columns: const [
              DataColumn(label: Text('App No.', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Consumer', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: installations.map((installation) {
              return DataRow(cells: [
                DataCell(Text(installation.applicationNumber)),
                DataCell(Text(installation.consumerName)),
                DataCell(Text(installation.installationDate != null
                    ? DateFormat('dd-MM-yyyy').format(installation.installationDate!)
                    : 'Not Scheduled')),
                DataCell(Text(installation.assignedTeam ?? 'Not Assigned')),
                DataCell(_buildStatusBadge(installation.status)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                    onPressed: () => _showUpdateDialog(installation),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InstallationStatus status) {
    Color color;
    switch (status) {
      case InstallationStatus.completed:
        color = AppTheme.successColor;
        break;
      case InstallationStatus.inProgress:
        color = AppTheme.statusInProgress;
        break;
      case InstallationStatus.scheduled:
        color = AppTheme.accentColor;
        break;
      case InstallationStatus.cancelled:
        color = AppTheme.errorColor;
        break;
      default:
        color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showUpdateDialog(InstallationModel installation) {
    // Basic update dialog implementation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Installation: ${installation.applicationNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Schedule Date'),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  ref.read(installationsProvider.notifier).updateInstallation(
                    installation.copyWith(installationDate: date, status: InstallationStatus.scheduled),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            // Add more fields as needed (Team, Material List etc)
          ],
        ),
      ),
    );
  }
}
