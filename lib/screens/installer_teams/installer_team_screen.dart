import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/installer_team_model.dart';
import '../../models/application_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/installer_team_providers.dart';
import '../../services/installer_team_service.dart';

class InstallerTeamScreen extends ConsumerStatefulWidget {
  const InstallerTeamScreen({super.key});
  @override
  ConsumerState<InstallerTeamScreen> createState() => _InstallerTeamScreenState();
}

class _InstallerTeamScreenState extends ConsumerState<InstallerTeamScreen> {
  String? _selectedTeamId;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(installerTeamsProvider.notifier).loadTeams();
      ref.read(applicationsProvider.notifier).loadApplications(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamsState = ref.watch(installerTeamsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null || !currentUser.isAdmin) {
      return const Center(child: Text('Access Denied'));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Installer Teams', style: AppTextStyles.heading2),
                    const SizedBox(height: 4),
                    Text(
                      'Create teams, set login credentials, and assign applications',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : () => _showCreateTeamDialog(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Create Team'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatsRow(teamsState.teams),
            const SizedBox(height: 20),
            Expanded(
              child: teamsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : teamsState.teams.isEmpty
                      ? _buildEmptyState()
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildTeamsTable(teamsState.teams)),
                            if (_selectedTeamId != null) ...[
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: _buildAssignmentsPanel()),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<InstallerTeamModel> teams) {
    final active = teams.where((t) => t.isActive).length;
    final inactive = teams.where((t) => !t.isActive).length;
    return Row(
      children: [
        _statCard('Total Teams', teams.length.toString(), Icons.groups_rounded, AppTheme.primaryColor),
        const SizedBox(width: 12),
        _statCard('Active', active.toString(), Icons.check_circle_rounded, AppTheme.successColor),
        const SizedBox(width: 12),
        _statCard('Inactive', inactive.toString(), Icons.block_rounded, AppTheme.errorColor),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppTextStyles.heading3),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.groups_outlined, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text('No installer teams yet', style: AppTextStyles.heading4.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Text('Create a team and assign applications to get started.', style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textSecondary)),
      ]),
    );
  }

  Widget _buildTeamsTable(List<InstallerTeamModel> teams) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: const Row(children: [
            SizedBox(width: 50, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text('Team Name', style: TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text('Phone', style: TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            SizedBox(width: 140, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final isSelected = team.id == _selectedTeamId;
              return InkWell(
                onTap: () => setState(() => _selectedTeamId = isSelected ? null : team.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : null,
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(children: [
                    SizedBox(width: 50, child: Text('${index + 1}')),
                    Expanded(flex: 2, child: Row(children: [
                      CircleAvatar(
                        radius: 16, backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(team.teamName[0].toUpperCase(), style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(team.teamName, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis)),
                    ])),
                    Expanded(flex: 2, child: Text(team.email, style: AppTextStyles.bodySmall)),
                    Expanded(child: Text(team.phone ?? '-', style: AppTextStyles.bodySmall)),
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (team.isActive ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(team.isActive ? 'Active' : 'Inactive',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: team.isActive ? AppTheme.successColor : AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    SizedBox(width: 140, child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.assignment_rounded, size: 20),
                        color: AppTheme.primaryColor,
                        tooltip: 'Assign Applications',
                        onPressed: () => setState(() => _selectedTeamId = team.id),
                      ),
                      IconButton(
                        icon: Icon(team.isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 20),
                        color: team.isActive ? AppTheme.errorColor : AppTheme.successColor,
                        tooltip: team.isActive ? 'Deactivate' : 'Activate',
                        onPressed: () => ref.read(installerTeamsProvider.notifier).toggleTeamStatus(team.id, !team.isActive),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: AppTheme.errorColor,
                        tooltip: 'Delete Team',
                        onPressed: () => _confirmDeleteTeam(team),
                      ),
                    ])),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildAssignmentsPanel() {
    final teamId = _selectedTeamId!;
    final teamsState = ref.watch(installerTeamsProvider);
    final team = teamsState.teams.where((t) => t.id == teamId).firstOrNull;
    if (team == null) return const SizedBox.shrink();

    final assignmentsAsync = ref.watch(teamAssignmentsProvider(teamId));
    final applicationsState = ref.watch(applicationsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(team.teamName, style: AppTextStyles.heading4),
              Text('Assigned Applications', style: AppTextStyles.caption.copyWith(color: AppTheme.textSecondary)),
            ])),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              color: AppTheme.primaryColor,
              tooltip: 'Assign Application',
              onPressed: () => _showAssignApplicationDialog(teamId, applicationsState.applications),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => setState(() => _selectedTeamId = null),
            ),
          ]),
        ),
        Expanded(
          child: assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (assignments) {
              if (assignments.isEmpty) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No applications assigned yet.\nTap + to assign.', textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textSecondary)),
                ));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  final app = applicationsState.applications
                      .where((a) => a.id == assignment.applicationId).firstOrNull;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18, backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.solar_power_rounded, size: 18, color: AppTheme.primaryColor),
                      ),
                      title: Text(app?.fullName ?? 'Unknown', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(app?.applicationNumber ?? assignment.applicationId, style: AppTextStyles.caption),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        color: AppTheme.errorColor,
                        tooltip: 'Remove assignment',
                        onPressed: () async {
                          await InstallerTeamService.removeAssignment(assignment.id);
                          ref.invalidate(teamAssignmentsProvider(teamId));
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _showCreateTeamDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Icon(Icons.group_add_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Create Installer Team'),
          ]),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Team Name', prefixIcon: Icon(Icons.groups_rounded)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Login Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Login Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'The installer team will use this email & password to login on the Installer App.',
                      style: AppTextStyles.caption.copyWith(color: AppTheme.primaryColor),
                    )),
                  ]),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Create Team'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    setState(() => _isCreating = true);
    try {
      await ref.read(installerTeamsProvider.notifier).createTeam(
        teamName: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Installer team created successfully!'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create team: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _showAssignApplicationDialog(String teamId, List<ApplicationModel> allApps) async {
    // Get already assigned app IDs
    final existingAssignments = await InstallerTeamService.fetchAssignmentsForTeam(teamId);
    final assignedIds = existingAssignments.map((a) => a.applicationId).toSet();

    // Filter: show only installationScheduled apps not already assigned
    final eligible = allApps.where((app) =>
      (app.currentStatus == ApplicationStatus.installationScheduled ||
       app.currentStatus == ApplicationStatus.installationCompleted) &&
      !assignedIds.contains(app.id)
    ).toList();

    if (!mounted) return;

    final selectedAppId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Application'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: eligible.isEmpty
              ? Center(child: Text('No eligible applications available.', style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textSecondary)))
              : ListView.builder(
                  itemCount: eligible.length,
                  itemBuilder: (ctx, i) {
                    final app = eligible[i];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16, backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.solar_power_rounded, size: 16, color: AppTheme.primaryColor),
                      ),
                      title: Text(app.fullName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text('${app.applicationNumber} • ${app.statusDisplayName}', style: AppTextStyles.caption),
                      onTap: () => Navigator.pop(ctx, app.id),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );

    if (selectedAppId == null) return;

    try {
      await InstallerTeamService.assignApplication(teamId: teamId, applicationId: selectedAppId);
      ref.invalidate(teamAssignmentsProvider(teamId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application assigned successfully'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _confirmDeleteTeam(InstallerTeamModel team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team?'),
        content: Text('This will permanently delete "${team.teamName}" and all its assignments.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(installerTeamsProvider.notifier).deleteTeam(team.id);
      if (_selectedTeamId == team.id) setState(() => _selectedTeamId = null);
    }
  }
}
