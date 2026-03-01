import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/update_available_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingForUpdates = false;

  static const String _versionJsonUrl =
      'https://raw.githubusercontent.com/priyanshushikarwal/CRM-updates/main/version.json';

  bool _isNewerVersion(String local, String remote) {
    final localParts = local.split('.').map(int.tryParse).toList();
    final remoteParts = remote.split('.').map(int.tryParse).toList();

    final maxLen =
        localParts.length > remoteParts.length
            ? localParts.length
            : remoteParts.length;

    for (int i = 0; i < maxLen; i++) {
      final l = (i < localParts.length ? localParts[i] : null) ?? 0;
      final r = (i < remoteParts.length ? remoteParts[i] : null) ?? 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final currentVersion = AppConstants.appVersion;

      final response = await http.get(Uri.parse(_versionJsonUrl));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to check for updates (HTTP ${response.statusCode})',
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);

      final remoteVersion = data['version'] as String? ?? '';
      final downloadUrl = data['url'] as String? ?? '';
      final releaseNotes =
          data['notes'] as String? ?? 'No release notes available.';

      if (remoteVersion.isEmpty || downloadUrl.isEmpty) {
        throw Exception('Invalid update manifest from server.');
      }

      if (!mounted) return;

      if (_isNewerVersion(currentVersion, remoteVersion)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => UpdateAvailableDialog(
                currentVersion: currentVersion,
                newVersion: remoteVersion,
                releaseNotes: releaseNotes,
                downloadUrl: downloadUrl,
              ),
        );
      } else {
        showDialog(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 12),
                    Text('Up to Date'),
                  ],
                ),
                content: Text(
                  "You're running the latest version (v$currentVersion).",
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Update check failed: $e',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage application preferences',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Updates',
            icon: Icons.system_update_alt_rounded,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.update_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Software Updates',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Check for new versions of the application',
                  style: TextStyle(fontSize: 12),
                ),
                trailing:
                    _checkingForUpdates
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : FilledButton.icon(
                          onPressed: _checkForUpdates,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Check for Updates'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
