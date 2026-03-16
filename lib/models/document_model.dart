import 'package:flutter/foundation.dart';

@immutable
class DocumentModel {
  final String id;
  final String applicationId;
  final String documentType;
  final String fileName;
  final String filePath;
  final String? fileUrl;
  final int? fileSize;
  final DateTime uploadedOn;
  final String? uploadedBy;
  final String? remarks;
  final String verificationStatus;
  final String? verifiedBy;

  const DocumentModel({
    required this.id,
    required this.applicationId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    this.fileUrl,
    this.fileSize,
    required this.uploadedOn,
    this.uploadedBy,
    this.remarks,
    this.verificationStatus = 'pending',
    this.verifiedBy,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      applicationId: json['application_id'] as String,
      documentType: json['document_type'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileUrl: json['file_url'] as String?,
      fileSize: json['file_size'] as int?,
      uploadedOn: DateTime.parse(json['uploaded_on'] as String),
      uploadedBy: json['uploaded_by'] as String?,
      remarks: json['remarks'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verifiedBy: json['verified_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'document_type': documentType,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_size': fileSize,
      'uploaded_on': uploadedOn.toIso8601String(),
      'uploaded_by': uploadedBy,
      'remarks': remarks,
      'verification_status': verificationStatus,
      'verified_by': verifiedBy,
    };
  }

  DocumentModel copyWith({
    String? id,
    String? applicationId,
    String? documentType,
    String? fileName,
    String? filePath,
    String? fileUrl,
    int? fileSize,
    DateTime? uploadedOn,
    String? uploadedBy,
    String? remarks,
    String? verificationStatus,
    String? verifiedBy,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedOn: uploadedOn ?? this.uploadedOn,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      remarks: remarks ?? this.remarks,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '-';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  bool get isPdf => fileExtension.toLowerCase() == 'pdf';
  bool get isImage => [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ].contains(fileExtension.toLowerCase());
}
