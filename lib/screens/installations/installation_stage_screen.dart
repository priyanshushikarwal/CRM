import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../../core/config/app_mode.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/application_model.dart';
import '../../models/installation_model.dart';
import '../../models/installation_photo_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../services/installation_service.dart';
import '../../services/installation_stage_service.dart';

class InstallationsListScreen extends ConsumerStatefulWidget {
  const InstallationsListScreen({super.key});

  @override
  ConsumerState<InstallationsListScreen> createState() => _InstallationsListScreenState();
}

class _PhotoSkeleton extends StatefulWidget {
  const _PhotoSkeleton();

  @override
  State<_PhotoSkeleton> createState() => _PhotoSkeletonState();
}

class _PhotoSkeletonState extends State<_PhotoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = (_controller.value * 2) - 1;
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + slide, 0),
              end: Alignment(-0.2 + slide, 0),
              colors: const [
                Color(0xFFE9EDF5),
                Color(0xFFD7DEE9),
                Color(0xFFE9EDF5),
              ],
              stops: const [0.15, 0.5, 0.85],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoStepSkeletonCard extends StatefulWidget {
  final int index;
  const _PhotoStepSkeletonCard({required this.index});

  @override
  State<_PhotoStepSkeletonCard> createState() => _PhotoStepSkeletonCardState();
}

class _PhotoStepSkeletonCardState extends State<_PhotoStepSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({required double height, double? width, double radius = 8}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = (_controller.value * 2) - 1;
        return Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + slide, 0),
              end: Alignment(-0.2 + slide, 0),
              colors: const [
                Color(0xFFE9EDF5),
                Color(0xFFD7DEE9),
                Color(0xFFE9EDF5),
              ],
              stops: const [0.15, 0.5, 0.85],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7C4D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFD7DEE9),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _shimmerBox(height: 16, width: 200)),
            ],
          ),
          const SizedBox(height: 12),
          _shimmerBox(height: 180, radius: 14),
          const SizedBox(height: 10),
          _shimmerBox(height: 12, width: 160),
          const SizedBox(height: 6),
          _shimmerBox(height: 12, width: 120),
          const SizedBox(height: 12),
          _shimmerBox(height: 48, radius: 14),
        ],
      ),
    );
  }
}

class _InstallationsListScreenState extends ConsumerState<InstallationsListScreen> {
  final _picker = ImagePicker();
  String? _selectedApplicationId;
  bool _showClientDetails = false;
  final Map<String, Map<int, InstallationPhotoModel>> _optimisticPhotosByApplication = {};
  final Map<String, Map<int, String>> _localPhotoPathsByApplication = {};
  final Set<String> _uploadingPhotoKeys = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(applicationsProvider.notifier).loadApplications(showLoading: false);
    });
  }

  List<ApplicationModel> _eligibleApplications(List<ApplicationModel> applications) {
    return applications
        .where(
          (application) =>
              application.currentStatus == ApplicationStatus.installationScheduled ||
              application.currentStatus == ApplicationStatus.installationCompleted,
        )
        .toList();
  }

  bool _isStepUnlocked(List<InstallationPhotoModel> photos, int index) {
    if (index <= 1) return true;
    final previousStepPhoto = photos
        .where((photo) => photo.photoOrder == index - 1)
        .cast<InstallationPhotoModel?>()
        .firstWhere(
          (photo) => photo != null,
          orElse: () => null,
        );
    return previousStepPhoto?.verificationStatus ==
        InstallationPhotoVerificationStatus.approved;
  }

  bool _allPhotosApproved(List<InstallationPhotoModel> photos) {
    if (photos.length < AppConstants.installationPhotoTypes.length) return false;
    return photos.every(
      (photo) => photo.verificationStatus == InstallationPhotoVerificationStatus.approved,
    );
  }

  bool _canAdminVerifyStep(List<InstallationPhotoModel> photos, int photoOrder) {
    if (photoOrder <= 1) return true;
    final previous = photos
        .where((photo) => photo.photoOrder == photoOrder - 1)
        .cast<InstallationPhotoModel?>()
        .firstWhere((photo) => photo != null, orElse: () => null);
    return previous?.verificationStatus == InstallationPhotoVerificationStatus.approved;
  }

  Future<Position?> _getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _uploadPhoto(int index, ApplicationModel application) async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;
    if (currentUser.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin cannot capture photos. Installer login is required.')),
        );
      }
      return;
    }

    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    final photoOrder = index + 1;
    _setLocalPhotoPath(application.id, photoOrder, picked.path);
    _setUploadingState(application.id, photoOrder, isUploading: true);

    final position = await _getCurrentPosition();
    if (position == null) {
      _clearLocalPhotoPath(application.id, photoOrder);
      _setUploadingState(application.id, photoOrder, isUploading: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to upload installation photos.')),
        );
      }
      return;
    }

    try {
      final installation = await InstallationService.initializeInstallation(
        applicationId: application.id,
        applicationNumber: application.applicationNumber,
        consumerName: application.fullName,
      );

      final uploaded = await InstallationStageService.uploadInstallationPhoto(
        installationId: installation.id,
        applicationId: application.id,
        applicationNumber: application.applicationNumber,
        photoOrder: photoOrder,
        photoType: AppConstants.installationPhotoTypes[index],
        file: File(picked.path),
        uploadedByUserId: currentUser.id,
        uploadedByUserName: currentUser.displayName,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _setOptimisticPhoto(application.id, uploaded);
      _setUploadingState(application.id, photoOrder, isUploading: false);
      await _refreshWorkflowData(application.id, refreshApplications: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${uploaded.photoType} uploaded successfully')),
        );
      }
    } catch (e) {
      _clearLocalPhotoPath(application.id, photoOrder);
      _setUploadingState(application.id, photoOrder, isUploading: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _verifyPhoto(
    InstallationPhotoModel photo,
    InstallationPhotoVerificationStatus status,
  ) async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null || !currentUser.isAdmin || AppModeConfig.isInstallerOnly) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only admin can approve or reject installation photos.')),
        );
      }
      return;
    }

    String? remarks;
    if (status == InstallationPhotoVerificationStatus.rejected && mounted) {
      remarks = await _askForRemarks();
      if (remarks == null) return;
      if (remarks.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rejection reason is required.')),
        );
        return;
      }
    }

    await InstallationStageService.verifyPhoto(
      photoId: photo.id,
      status: status,
      verifiedByUserId: currentUser.id,
      verifiedByUserName: currentUser.displayName,
      remarks: remarks,
    );

    _setOptimisticPhoto(
      photo.applicationId,
      photo.copyWith(
        verificationStatus: status,
        verificationRemarks: remarks,
        verifiedByUserId: currentUser.id,
        verifiedByUserName: currentUser.displayName,
        verifiedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await _refreshWorkflowData(photo.applicationId, refreshApplications: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo ${status.name}')),
      );
    }
  }

  Future<String?> _askForRemarks() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  void _showPhotoPreview(InstallationPhotoModel photo, String title) {
    showDialog(
      context: context,
      builder: (context) => _PhotoPreviewDialog(
        title: title,
        photoUrl: photo.photoUrl,
        capturedBy: photo.capturedByUserName ?? 'Unknown',
        capturedAt: _formatDateTime(photo.capturedAt),
        latitude: photo.latitude,
        longitude: photo.longitude,
        verificationStatus: photo.verificationStatus.name.toUpperCase(),
        remarks: photo.verificationRemarks,
      ),
    );
  }

  void _showLocalPhotoPreview(String localPath, String title) {
    showDialog(
      context: context,
      builder: (context) => _PhotoPreviewDialog(
        title: title,
        localFilePath: localPath,
        capturedBy: 'You',
        capturedAt: _formatDateTime(DateTime.now()),
      ),
    );
  }

  List<InstallationPhotoModel> _mergeOptimisticPhotos(
    String applicationId,
    List<InstallationPhotoModel> serverPhotos,
  ) {
    final optimistic = _optimisticPhotosByApplication[applicationId];
    if (optimistic == null || optimistic.isEmpty) {
      return serverPhotos;
    }

    final merged = {
      for (final photo in serverPhotos) photo.photoOrder: photo,
      ...optimistic,
    };

    final photos = merged.values.toList()
      ..sort((a, b) => a.photoOrder.compareTo(b.photoOrder));
    return photos;
  }

  void _setOptimisticPhoto(String applicationId, InstallationPhotoModel photo) {
    if (!mounted) return;
    setState(() {
      final photos = _optimisticPhotosByApplication.putIfAbsent(applicationId, () => {});
      photos[photo.photoOrder] = photo;
    });
  }

  void _setLocalPhotoPath(String applicationId, int photoOrder, String path) {
    if (!mounted) return;
    setState(() {
      final photos = _localPhotoPathsByApplication.putIfAbsent(applicationId, () => {});
      photos[photoOrder] = path;
    });
  }

  void _clearLocalPhotoPath(String applicationId, int photoOrder) {
    if (!mounted) return;
    setState(() {
      final photos = _localPhotoPathsByApplication[applicationId];
      photos?.remove(photoOrder);
      if (photos != null && photos.isEmpty) {
        _localPhotoPathsByApplication.remove(applicationId);
      }
    });
  }

  void _setUploadingState(
    String applicationId,
    int photoOrder, {
    required bool isUploading,
  }) {
    if (!mounted) return;
    final key = '$applicationId:$photoOrder';
    setState(() {
      if (isUploading) {
        _uploadingPhotoKeys.add(key);
      } else {
        _uploadingPhotoKeys.remove(key);
      }
    });
  }

  String? _localPhotoPath(String applicationId, int photoOrder) {
    return _localPhotoPathsByApplication[applicationId]?[photoOrder];
  }

  bool _isUploadingPhoto(String applicationId, int photoOrder) {
    return _uploadingPhotoKeys.contains('$applicationId:$photoOrder');
  }

  Future<void> _refreshWorkflowData(
    String applicationId, {
    bool refreshApplications = true,
  }) async {
    if (refreshApplications) {
      await ref.read(applicationsProvider.notifier).loadApplications(showLoading: false);
    }
    await Future.wait([
      ref.refresh(installationPhotosByApplicationProvider(applicationId).future),
      ref.refresh(pendingInstallationPhotosProvider.future),
    ]);
  }

  Future<void> _completeInstallation(ApplicationModel application) async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    final installation = await InstallationService.initializeInstallation(
      applicationId: application.id,
      applicationNumber: application.applicationNumber,
      consumerName: application.fullName,
    );

    await InstallationService.updateInstallation(
      installation.copyWith(status: InstallationStatus.completed),
    );

    await ref.read(applicationsProvider.notifier).updateApplicationStatus(
      applicationId: application.id,
      newStatus: ApplicationStatus.installationCompleted,
      stageStatus: StageStatus.completed,
      remarks: 'Installation approved by ${currentUser.displayName}',
    );

    ref.invalidate(installationByAppProvider(application.id));
    ref.invalidate(applicationsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Installation marked as completed')),
      );
    }
  }

  void _openInstallationWorkflow(UserModel? currentUser, ApplicationModel application) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF8F9FF),
          appBar: AppBar(
            title: const Text('Installation Workflow'),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => _refreshWorkflowData(application.id, refreshApplications: false),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Consumer(
                builder: (context, consumerRef, _) {
                  final user = consumerRef.watch(currentUserProvider).value ?? currentUser;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${application.applicationNumber} - ${application.fullName}',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _buildPhotoWorkflow(user, application, watchRef: consumerRef),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    const mobileBg = Color(0xFFF8F9FF);
    const mobilePrimary = Color(0xFF4343D5);
    final applicationsState = ref.watch(applicationsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.when(
      data: (user) => user,
      loading: () => null,
      error: (_, __) => null,
    );
    final pendingPhotosAsync = ref.watch(pendingInstallationPhotosProvider);
    final eligibleApplications = _eligibleApplications(applicationsState.applications);
    final filteredApplications = eligibleApplications;
    ApplicationModel? selectedApplication;
    for (final app in filteredApplications) {
      if (app.id == _selectedApplicationId) {
        selectedApplication = app;
        break;
      }
    }
    selectedApplication ??= filteredApplications.isNotEmpty ? filteredApplications.first : null;

    return Scaffold(
      backgroundColor: isMobile ? mobileBg : AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scheduled Installations',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: isMobile ? 18 : null,
                        fontWeight: FontWeight.w700,
                        letterSpacing: isMobile ? -0.1 : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a client to view details and begin field workflow.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAD6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${eligibleApplications.length} Pending Today'),
                    ),
                  ],
                ),
                if (!isMobile) ElevatedButton.icon(
                  onPressed: () async {
                    if (_selectedApplicationId != null) {
                      await _refreshWorkflowData(_selectedApplicationId!);
                    } else {
                      await ref.read(applicationsProvider.notifier).loadApplications();
                      await ref.refresh(pendingInstallationPhotosProvider.future);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            pendingPhotosAsync.when(
              data: (photos) => _buildQueueSummary(photos),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            _buildApplicationPicker(filteredApplications),
            const SizedBox(height: 14),
            if (selectedApplication != null) ...[
              _buildClientDetailsSection(selectedApplication),
              const SizedBox(height: 14),
              if (isMobile)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openInstallationWorkflow(currentUser, selectedApplication!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mobilePrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Proceed to Installation'),
                  ),
                ),
              if (!isMobile) ...[
                const SizedBox(height: 14),
                _buildPhotoWorkflow(currentUser, selectedApplication),
              ],
            ] else
              Expanded(
                child: Center(
                  child: Text(
                    'No installation-ready application found',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildQueueSummary(List<InstallationPhotoModel> photos) {
    final pendingCount = photos.where(
      (photo) => photo.verificationStatus == InstallationPhotoVerificationStatus.pending,
    ).length;
    final approvedCount = photos.where(
      (photo) => photo.verificationStatus == InstallationPhotoVerificationStatus.approved,
    ).length;
    final rejectedCount = photos.where(
      (photo) => photo.verificationStatus == InstallationPhotoVerificationStatus.rejected,
    ).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        if (isNarrow) {
          return Column(
            children: [
              _summaryCard('Pending verifications', pendingCount.toString(), Icons.pending_actions_rounded),
              const SizedBox(height: 12),
              _summaryCard('Approved photos', approvedCount.toString(), Icons.verified_rounded),
              const SizedBox(height: 12),
              _summaryCard('Rejected photos', rejectedCount.toString(), Icons.block_rounded),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _summaryCard('Pending verifications', pendingCount.toString(), Icons.pending_actions_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard('Approved photos', approvedCount.toString(), Icons.verified_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard('Rejected photos', rejectedCount.toString(), Icons.block_rounded),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7C4D7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.heading4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationPicker(List<ApplicationModel> applications) {
    final validSelectedId = applications.any((app) => app.id == _selectedApplicationId)
        ? _selectedApplicationId
        : null;
    final selectedId = validSelectedId ?? (applications.isNotEmpty ? applications.first.id : null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7C4D7)),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedId,
        decoration: const InputDecoration(
          labelText: 'Select client / application',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        items: applications
            .map(
              (application) => DropdownMenuItem(
                value: application.id,
                child: Text(
                  '${application.applicationNumber} - ${application.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedApplicationId = value;
          });
        },
      ),
    );
  }

  Widget _buildClientDetails(ApplicationModel application) {
    final screenWidth = MediaQuery.of(context).size.width;
    final chipMaxWidth = screenWidth < 600 ? screenWidth - 64 : 320.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7C4D7)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _detailChip('Application No.', application.applicationNumber, maxWidth: chipMaxWidth),
          _detailChip('Consumer Name', application.fullName, maxWidth: chipMaxWidth),
          _detailChip('Address', application.address, maxWidth: chipMaxWidth),
          _detailChip('Mobile', application.mobile, maxWidth: chipMaxWidth),
          _detailChip('AEN Office', application.divisionName, maxWidth: chipMaxWidth),
          _detailChip('State', application.state, maxWidth: chipMaxWidth),
          _detailChip('Current Stage', application.statusDisplayName, maxWidth: chipMaxWidth),
        ],
      ),
    );
  }

  Widget _detailChip(String label, String value, {double? maxWidth}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall,
      ),
    ),
    );
  }

  Widget _buildPhotoWorkflow(UserModel? currentUser, ApplicationModel application, {WidgetRef? watchRef}) {
    final effectiveRef = watchRef ?? ref;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final photosAsync = effectiveRef.watch(installationPhotosByApplicationProvider(application.id));
    final serverPhotos = photosAsync.maybeWhen(
      data: (value) => value,
      orElse: () => <InstallationPhotoModel>[],
    );
    final photos = _mergeOptimisticPhotos(application.id, serverPhotos);
    final photoByOrder = {for (final photo in photos) photo.photoOrder: photo};
    final isInitialLoading = photosAsync.isLoading && !photosAsync.hasValue;

    return Expanded(
      child: Column(
        children: [
          photosAsync.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Unable to sync photos. You can still continue.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppTheme.errorColor),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => effectiveRef.invalidate(
                      installationPhotosByApplicationProvider(application.id),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isMobile
                ? RefreshIndicator(
                    onRefresh: () => _refreshWorkflowData(application.id, refreshApplications: false),
                    child: ListView(
                      children: isInitialLoading
                          ? [
                              for (var index = 0; index < AppConstants.installationPhotoTypes.length; index++) ...[
                                _PhotoStepSkeletonCard(index: index),
                                if (index != AppConstants.installationPhotoTypes.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ]
                          : [
                              for (var index = 0; index < AppConstants.installationPhotoTypes.length; index++) ...[
                                _buildPhotoStepCard(
                                  application,
                                  currentUser,
                                  photos,
                                  index,
                                  AppConstants.installationPhotoTypes[index],
                                  photoByOrder[index + 1],
                                  _isStepUnlocked(photos, index + 1),
                                ),
                                if (index != AppConstants.installationPhotoTypes.length - 1)
                                  const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 16),
                              _buildAdminPanel(currentUser, application, photos),
                            ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: ListView.separated(
                          itemCount: AppConstants.installationPhotoTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (isInitialLoading) {
                              return _PhotoStepSkeletonCard(index: index);
                            }
                            final step = AppConstants.installationPhotoTypes[index];
                            final photo = photoByOrder[index + 1];
                            final isUnlocked = _isStepUnlocked(photos, index + 1);
                            return _buildPhotoStepCard(
                              application,
                              currentUser,
                              photos,
                              index,
                              step,
                              photo,
                              isUnlocked,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAdminPanel(currentUser, application, photos),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetailsSection(ApplicationModel application) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Client Details',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showClientDetails = !_showClientDetails;
                });
              },
              icon: Icon(
                _showClientDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              ),
              label: Text(_showClientDetails ? 'Minimize' : 'Expand'),
            ),
          ],
        ),
        if (_showClientDetails) _buildClientDetails(application),
      ],
    );
  }

  Widget _buildPhotoStepCard(
    ApplicationModel application,
    UserModel? currentUser,
    List<InstallationPhotoModel> allPhotos,
    int index,
    String title,
    InstallationPhotoModel? photo,
    bool isUnlocked,
  ) {
    final canVerify = (currentUser?.isAdmin ?? false) && !AppModeConfig.isInstallerOnly;
    final canUpload = currentUser != null && !canVerify;
    final canVerifyThisStep = _canAdminVerifyStep(allPhotos, index + 1);
    final localPhotoPath = _localPhotoPath(application.id, index + 1);
    final isUploading = _isUploadingPhoto(application.id, index + 1);
    final hasUploadedPhoto = photo != null || localPhotoPath != null;
    final showPendingSyncSkeleton = localPhotoPath != null && photo == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7C4D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isUnlocked ? AppTheme.successColor : AppTheme.textLight,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                    if (hasUploadedPhoto) ...[
                      const SizedBox(height: 4),
                      Text(
                        isUploading
                            ? 'Photo uploading...'
                            : photo == null
                            ? 'Photo captured successfully'
                            : photo.verificationStatus == InstallationPhotoVerificationStatus.pending
                            ? 'Photo uploaded, awaiting admin review'
                            : photo.verificationStatus == InstallationPhotoVerificationStatus.approved
                            ? 'Photo approved by admin'
                            : 'Photo rejected by admin',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isUploading
                              ? AppTheme.primaryColor
                              : photo?.verificationStatus == InstallationPhotoVerificationStatus.rejected
                              ? AppTheme.errorColor
                              : photo?.verificationStatus == InstallationPhotoVerificationStatus.approved
                              ? AppTheme.successColor
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (photo != null)
                _statusBadge(photo.verificationStatus),
            ],
          ),
          const SizedBox(height: 12),
          if (photo != null || localPhotoPath != null) ...[
            GestureDetector(
              onTap: () {
                if (photo != null) {
                  _showPhotoPreview(photo, title);
                } else if (localPhotoPath != null) {
                  _showLocalPhotoPreview(localPhotoPath, title);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    localPhotoPath != null
                        ? Image.file(
                            File(localPhotoPath),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            photo!.photoUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const _PhotoSkeleton();
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 180,
                              width: double.infinity,
                              color: const Color(0xFFF2F4FA),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined, size: 32),
                            ),
                          ),
                    if (showPendingSyncSkeleton)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.42,
                          child: const _PhotoSkeleton(),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Preview', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (isUploading) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading photo...',
                    style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text('Captured by ${photo?.capturedByUserName ?? currentUser?.displayName ?? 'Unknown'}', style: AppTextStyles.bodySmall),
            Text(
              'Captured at ${_formatDateTime(photo?.capturedAt ?? DateTime.now())}',
              style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            Text(
              '${photo?.latitude?.toStringAsFixed(6) ?? '-'}, ${photo?.longitude?.toStringAsFixed(6) ?? '-'}',
              style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            if (photo?.verificationRemarks != null) ...[
              const SizedBox(height: 8),
              Text('Remarks: ${photo!.verificationRemarks}', style: AppTextStyles.bodySmall),
            ],
          ] else
            Text('No photo uploaded yet.', style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions = canVerify && photo != null && constraints.maxWidth < 340;
              if (stackActions) {
                final verifiedPhoto = photo;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: canVerifyThisStep
                              ? () => _verifyPhoto(verifiedPhoto, InstallationPhotoVerificationStatus.approved)
                              : null,
                          child: const Text('Approve'),
                        ),
                        TextButton(
                          onPressed: canVerifyThisStep
                              ? () => _verifyPhoto(verifiedPhoto, InstallationPhotoVerificationStatus.rejected)
                              : null,
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  if (canUpload)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !isUploading &&
                                isUnlocked &&
                                (photo == null || photo.verificationStatus != InstallationPhotoVerificationStatus.approved)
                            ? () => _uploadPhoto(index, application)
                            : null,
                        icon: isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded),
                        label: Text(isUploading ? 'Uploading...' : photo == null ? 'Capture Photo' : 'Re-upload'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  if (canVerify && photo != null) ...[
                    if (canUpload) const SizedBox(width: 10),
                    TextButton(
                      onPressed: canVerifyThisStep
                          ? () => _verifyPhoto(photo, InstallationPhotoVerificationStatus.approved)
                          : null,
                      child: const Text('Approve'),
                    ),
                    TextButton(
                      onPressed: canVerifyThisStep
                          ? () => _verifyPhoto(photo, InstallationPhotoVerificationStatus.rejected)
                          : null,
                      child: const Text('Reject'),
                    ),
                  ],
                ],
              );
            },
          ),
          if (canVerify && photo != null && !canVerifyThisStep) ...[
            const SizedBox(height: 8),
            Text(
              'Approve previous step first to verify this photo.',
              style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminPanel(
    UserModel? currentUser,
    ApplicationModel application,
    List<InstallationPhotoModel> photos,
  ) {
    if (AppModeConfig.isInstallerOnly || currentUser?.isAdmin != true) {
      return const SizedBox.shrink();
    }

    final canComplete = currentUser?.isAdmin == true && _allPhotosApproved(photos);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Admin Verification', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Text(
            'Approve each uploaded photo in sequence. The final button becomes available after all seven steps are approved.',
            style: AppTextStyles.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ...photos.map(
            (photo) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(photo.photoType),
                subtitle: Text(
                  '${photo.verificationStatus.name.toUpperCase()} | ${photo.capturedByUserName ?? 'Unknown'} | ${_formatDateTime(photo.capturedAt)}',
                ),
                trailing: photo.verificationStatus == InstallationPhotoVerificationStatus.pending
                    ? const Icon(Icons.hourglass_bottom_rounded)
                    : null,
              ),
            ),
          ),
          const Divider(height: 28),
          ElevatedButton.icon(
            onPressed: canComplete ? () => _completeInstallation(application) : null,
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('Complete Installation'),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(InstallationPhotoVerificationStatus status) {
    final color = switch (status) {
      InstallationPhotoVerificationStatus.approved => AppTheme.successColor,
      InstallationPhotoVerificationStatus.rejected => AppTheme.errorColor,
      InstallationPhotoVerificationStatus.pending => AppTheme.warningColor,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PhotoPreviewDialog extends StatefulWidget {
  final String title;
  final String? photoUrl;
  final String? localFilePath;
  final String capturedBy;
  final String capturedAt;
  final double? latitude;
  final double? longitude;
  final String? verificationStatus;
  final String? remarks;

  const _PhotoPreviewDialog({
    required this.title,
    this.photoUrl,
    this.localFilePath,
    required this.capturedBy,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.verificationStatus,
    this.remarks,
  });

  @override
  State<_PhotoPreviewDialog> createState() => _PhotoPreviewDialogState();
}

class _PhotoPreviewDialogState extends State<_PhotoPreviewDialog> {
  bool _isDownloading = false;
  bool _showInfo = false;

  Future<void> _downloadPhoto() async {
    if (widget.photoUrl == null && widget.localFilePath == null) return;

    setState(() => _isDownloading = true);

    try {
      Uint8List bytes;
      String suggestedName;

      if (widget.localFilePath != null) {
        bytes = await File(widget.localFilePath!).readAsBytes();
        suggestedName = widget.localFilePath!.split(Platform.pathSeparator).last;
      } else {
        final response = await http.get(Uri.parse(widget.photoUrl!));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image');
        }
        bytes = response.bodyBytes;
        final ext = widget.photoUrl!.split('.').last.split('?').first;
        suggestedName = '${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      }

      if (Platform.isAndroid || Platform.isIOS) {
        final dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}/$suggestedName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to Downloads: $suggestedName')),
          );
        }
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save installation photo',
          fileName: suggestedName,
          type: FileType.image,
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Photo saved to ${file.path}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isDesktop ? 40 : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 0),
        child: Container(
          width: isDesktop ? 800 : screenSize.width,
          height: isDesktop ? screenSize.height * 0.85 : screenSize.height,
          color: const Color(0xFF111118),
          child: Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFF1A1A24),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.verificationStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.verificationStatus == 'APPROVED'
                                ? AppTheme.successColor.withValues(alpha: 0.2)
                                : widget.verificationStatus == 'REJECTED'
                                    ? AppTheme.errorColor.withValues(alpha: 0.2)
                                    : AppTheme.warningColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.verificationStatus!,
                            style: TextStyle(
                              color: widget.verificationStatus == 'APPROVED'
                                  ? AppTheme.successColor
                                  : widget.verificationStatus == 'REJECTED'
                                      ? AppTheme.errorColor
                                      : AppTheme.warningColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() => _showInfo = !_showInfo),
                        icon: Icon(
                          _showInfo ? Icons.info : Icons.info_outline_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Photo details',
                      ),
                      IconButton(
                        onPressed: _isDownloading ? null : _downloadPhoto,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, color: Colors.white),
                        tooltip: 'Download photo',
                      ),
                    ],
                  ),
                ),
              ),

              // Photo with pinch-to-zoom
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: widget.localFilePath != null
                        ? Image.file(
                            File(widget.localFilePath!),
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            widget.photoUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.white54),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                                SizedBox(height: 12),
                                Text('Failed to load image', style: TextStyle(color: Colors.white38)),
                              ],
                            ),
                          ),
                  ),
                ),
              ),

              // Info panel (toggle)
              if (_showInfo)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1A1A24),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.person_outline_rounded, 'Captured by', widget.capturedBy),
                        const SizedBox(height: 8),
                        _infoRow(Icons.schedule_rounded, 'Captured at', widget.capturedAt),
                        if (widget.latitude != null && widget.longitude != null) ...[
                          const SizedBox(height: 8),
                          _infoRow(
                            Icons.location_on_outlined,
                            'GPS',
                            '${widget.latitude!.toStringAsFixed(6)}, ${widget.longitude!.toStringAsFixed(6)}',
                          ),
                        ],
                        if (widget.remarks != null) ...[
                          const SizedBox(height: 8),
                          _infoRow(Icons.comment_outlined, 'Remarks', widget.remarks!),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
