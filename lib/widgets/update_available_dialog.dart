import 'dart:io';

import 'package:flutter/material.dart';
import '../services/updater_service.dart';

enum _UpdateState { initial, downloading, installing, error }

class UpdateAvailableDialog extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateAvailableDialog({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  _UpdateState _state = _UpdateState.initial;
  double _progress = 0.0;
  String _errorMessage = '';

  final UpdaterService _updaterService = UpdaterService();

  Future<void> _startDownload() async {
    setState(() {
      _state = _UpdateState.downloading;
      _progress = 0.0;
    });

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final packageExtension = _resolvePackageExtension(widget.downloadUrl);
    final savePath =
        '${Directory.systemTemp.path}\\app_update_$timestamp$packageExtension';

    try {
      await _updaterService.downloadUpdate(
        widget.downloadUrl,
        savePath,
        (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _state = _UpdateState.installing;
      });

      await _updaterService.installUpdateAndRestart(savePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _UpdateState.error;
        _errorMessage = _buildFriendlyErrorMessage(e);
      });
    }
  }

  String _resolvePackageExtension(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';

    if (path.endsWith('.exe')) {
      return '.exe';
    }

    if (path.endsWith('.msi')) {
      return '.msi';
    }

    return '.zip';
  }

  String _buildFriendlyErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('Status code: 404')) {
      return 'Update file not found (404).\nURL: ${widget.downloadUrl}';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _buildTitle(),
      content: SizedBox(width: 460, child: _buildContent()),
      actions: _buildActions(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildTitle() {
    switch (_state) {
      case _UpdateState.initial:
        return const Row(
          children: [
            Icon(Icons.system_update_alt_rounded, color: Color(0xFF1E3A5F)),
            SizedBox(width: 12),
            Text('Update Available'),
          ],
        );
      case _UpdateState.downloading:
        return const Row(
          children: [
            Icon(Icons.downloading_rounded, color: Color(0xFF2196F3)),
            SizedBox(width: 12),
            Text('Downloading Update'),
          ],
        );
      case _UpdateState.installing:
        return const Row(
          children: [
            Icon(Icons.install_desktop_rounded, color: Color(0xFF4CAF50)),
            SizedBox(width: 12),
            Text('Installing Update'),
          ],
        );
      case _UpdateState.error:
        return const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFE53935)),
            SizedBox(width: 12),
            Text('Update Error'),
          ],
        );
    }
  }

  Widget _buildContent() {
    switch (_state) {
      case _UpdateState.initial:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: Row(
                children: [
                  _versionBadge(widget.currentVersion, 'Current', Colors.grey),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  _versionBadge(
                    widget.newVersion,
                    'New',
                    const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Release Notes:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.releaseNotes,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ],
        );

      case _UpdateState.downloading:
        final percent = (_progress * 100).toInt();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Downloading... $percent%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please do not close the application.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );

      case _UpdateState.installing:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A5F)),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Installing update...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'The application will restart automatically.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );

      case _UpdateState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_state) {
      case _UpdateState.initial:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Update Now'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
            ),
          ),
        ];

      case _UpdateState.downloading:
      case _UpdateState.installing:
        return [];

      case _UpdateState.error:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _state = _UpdateState.initial;
                _errorMessage = '';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
            ),
          ),
        ];
    }
  }

  Widget _versionBadge(String version, String label, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
