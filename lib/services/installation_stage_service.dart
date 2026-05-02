import 'dart:async';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/installation_photo_model.dart';
import 'supabase_service.dart';

class InstallationStageService {
  static const _uuid = Uuid();

  static Future<List<InstallationPhotoModel>> fetchInstallationPhotos(
    String applicationId,
  ) async {
    final response = await SupabaseService.from(AppConstants.installationPhotosTable)
        .select()
        .eq('application_id', applicationId)
        .order('photo_order', ascending: true)
        .order('updated_at', ascending: false)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException(
            'Loading installation photos timed out. Please check network/Supabase.',
          ),
        );

    // Keep only the latest row per stage order to avoid duplicate-row conflicts in UI logic.
    final latestByOrder = <int, InstallationPhotoModel>{};
    for (final item in response as List) {
      final photo = InstallationPhotoModel.fromJson(item as Map<String, dynamic>);
      latestByOrder.putIfAbsent(photo.photoOrder, () => photo);
    }

    final deduped = latestByOrder.values.toList()
      ..sort((a, b) => a.photoOrder.compareTo(b.photoOrder));
    return deduped;
  }

  static Future<List<InstallationPhotoModel>> fetchPendingVerificationPhotos() async {
    final response = await SupabaseService.from(AppConstants.installationPhotosTable)
        .select()
        .eq('verification_status', InstallationPhotoVerificationStatus.pending.name)
        .order('created_at', ascending: true)
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw TimeoutException(
            'Loading pending verification photos timed out.',
          ),
        );

    return (response as List)
        .map((json) => InstallationPhotoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<InstallationPhotoModel> uploadInstallationPhoto({
    required String installationId,
    required String applicationId,
    required String applicationNumber,
    required int photoOrder,
    required String photoType,
    required File file,
    required String uploadedByUserId,
    required String uploadedByUserName,
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final extension = file.path.split('.').last;
    final storagePath =
        '$applicationId/${photoOrder}_${now.millisecondsSinceEpoch}.$extension';

    await SupabaseService.client.storage
        .from(AppConstants.installationPhotosBucket)
        .upload(storagePath, file);

    final publicUrl = SupabaseService.client.storage
        .from(AppConstants.installationPhotosBucket)
        .getPublicUrl(storagePath);

    final existingRows = await SupabaseService.from(AppConstants.installationPhotosTable)
        .select()
        .eq('application_id', applicationId)
        .eq('photo_order', photoOrder)
        .order('updated_at', ascending: false)
        .limit(1);

    final existingResponse =
        (existingRows as List).isNotEmpty ? existingRows.first as Map<String, dynamic> : null;

    final photoId = existingResponse != null ? existingResponse['id'] as String : _uuid.v4();

    final photo = InstallationPhotoModel(
      id: photoId,
      installationId: installationId,
      applicationId: applicationId,
      applicationNumber: applicationNumber,
      photoOrder: photoOrder,
      photoType: photoType,
      storagePath: storagePath,
      photoUrl: publicUrl,
      latitude: latitude,
      longitude: longitude,
      capturedByUserId: uploadedByUserId,
      capturedByUserName: uploadedByUserName,
      capturedAt: now,
      verificationStatus: InstallationPhotoVerificationStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    final response = existingResponse == null
        ? await SupabaseService.from(AppConstants.installationPhotosTable)
            .insert(photo.toJson())
            .select()
            .single()
        : await SupabaseService.from(AppConstants.installationPhotosTable)
            .update(photo.toJson())
            .eq('id', photoId)
            .select()
            .single();

    return InstallationPhotoModel.fromJson(response);
  }

  static Future<InstallationPhotoModel> verifyPhoto({
    required String photoId,
    required InstallationPhotoVerificationStatus status,
    required String verifiedByUserId,
    required String verifiedByUserName,
    String? remarks,
  }) async {
    final response = await SupabaseService.from(AppConstants.installationPhotosTable)
        .update({
          'verification_status': status.name,
          'verification_remarks': remarks,
          'verified_by_user_id': verifiedByUserId,
          'verified_by_user_name': verifiedByUserName,
          'verified_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', photoId)
        .select()
        .single();

    return InstallationPhotoModel.fromJson(response);
  }
}
