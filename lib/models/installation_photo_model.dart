import 'package:flutter/foundation.dart';

enum InstallationPhotoVerificationStatus { pending, approved, rejected }

@immutable
class InstallationPhotoModel {
  final String id;
  final String installationId;
  final String applicationId;
  final String applicationNumber;
  final int photoOrder;
  final String photoType;
  final String storagePath;
  final String photoUrl;
  final double? latitude;
  final double? longitude;
  final String? capturedByUserId;
  final String? capturedByUserName;
  final DateTime? capturedAt;
  final InstallationPhotoVerificationStatus verificationStatus;
  final String? verificationRemarks;
  final String? verifiedByUserId;
  final String? verifiedByUserName;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallationPhotoModel({
    required this.id,
    required this.installationId,
    required this.applicationId,
    required this.applicationNumber,
    required this.photoOrder,
    required this.photoType,
    required this.storagePath,
    required this.photoUrl,
    this.latitude,
    this.longitude,
    this.capturedByUserId,
    this.capturedByUserName,
    this.capturedAt,
    this.verificationStatus = InstallationPhotoVerificationStatus.pending,
    this.verificationRemarks,
    this.verifiedByUserId,
    this.verifiedByUserName,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallationPhotoModel.fromJson(Map<String, dynamic> json) {
    return InstallationPhotoModel(
      id: json['id'] as String,
      installationId: json['installation_id'] as String,
      applicationId: json['application_id'] as String,
      applicationNumber: json['application_number'] as String,
      photoOrder: (json['photo_order'] as num).toInt(),
      photoType: json['photo_type'] as String,
      storagePath: json['storage_path'] as String,
      photoUrl: json['photo_url'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      capturedByUserId: json['captured_by_user_id'] as String?,
      capturedByUserName: json['captured_by_user_name'] as String?,
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'] as String)
          : null,
      verificationStatus: InstallationPhotoVerificationStatus.values.firstWhere(
        (value) => value.name == (json['verification_status'] as String? ?? 'pending'),
        orElse: () => InstallationPhotoVerificationStatus.pending,
      ),
      verificationRemarks: json['verification_remarks'] as String?,
      verifiedByUserId: json['verified_by_user_id'] as String?,
      verifiedByUserName: json['verified_by_user_name'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'installation_id': installationId,
      'application_id': applicationId,
      'application_number': applicationNumber,
      'photo_order': photoOrder,
      'photo_type': photoType,
      'storage_path': storagePath,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'captured_by_user_id': capturedByUserId,
      'captured_by_user_name': capturedByUserName,
      'captured_at': capturedAt?.toIso8601String(),
      'verification_status': verificationStatus.name,
      'verification_remarks': verificationRemarks,
      'verified_by_user_id': verifiedByUserId,
      'verified_by_user_name': verifiedByUserName,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InstallationPhotoModel copyWith({
    String? id,
    String? installationId,
    String? applicationId,
    String? applicationNumber,
    int? photoOrder,
    String? photoType,
    String? storagePath,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? capturedByUserId,
    String? capturedByUserName,
    DateTime? capturedAt,
    InstallationPhotoVerificationStatus? verificationStatus,
    String? verificationRemarks,
    String? verifiedByUserId,
    String? verifiedByUserName,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallationPhotoModel(
      id: id ?? this.id,
      installationId: installationId ?? this.installationId,
      applicationId: applicationId ?? this.applicationId,
      applicationNumber: applicationNumber ?? this.applicationNumber,
      photoOrder: photoOrder ?? this.photoOrder,
      photoType: photoType ?? this.photoType,
      storagePath: storagePath ?? this.storagePath,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedByUserId: capturedByUserId ?? this.capturedByUserId,
      capturedByUserName: capturedByUserName ?? this.capturedByUserName,
      capturedAt: capturedAt ?? this.capturedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationRemarks: verificationRemarks ?? this.verificationRemarks,
      verifiedByUserId: verifiedByUserId ?? this.verifiedByUserId,
      verifiedByUserName: verifiedByUserName ?? this.verifiedByUserName,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
