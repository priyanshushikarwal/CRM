import 'package:flutter/foundation.dart';

enum InstallationStatus { pending, scheduled, inProgress, completed, cancelled }

@immutable
class InstallationModel {
  final String id;
  final String applicationId;
  final String applicationNumber;
  final String consumerName;
  final DateTime? installationDate;
  final String? assignedTeam;
  final List<String> materialList;
  final String? completionReport;
  final String? customerSignatureUrl;
  final InstallationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallationModel({
    required this.id,
    required this.applicationId,
    required this.applicationNumber,
    required this.consumerName,
    this.installationDate,
    this.assignedTeam,
    this.materialList = const [],
    this.completionReport,
    this.customerSignatureUrl,
    this.status = InstallationStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallationModel.fromJson(Map<String, dynamic> json) {
    return InstallationModel(
      id: json['id'] as String,
      applicationId: json['application_id'] as String,
      applicationNumber: json['application_number'] as String,
      consumerName: json['consumer_name'] as String,
      installationDate: json['installation_date'] != null
          ? DateTime.parse(json['installation_date'] as String)
          : null,
      assignedTeam: json['assigned_team'] as String?,
      materialList: (json['material_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      completionReport: json['completion_report'] as String?,
      customerSignatureUrl: json['customer_signature_url'] as String?,
      status: InstallationStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => InstallationStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'application_number': applicationNumber,
      'consumer_name': consumerName,
      'installation_date': installationDate?.toIso8601String(),
      'assigned_team': assignedTeam,
      'material_list': materialList,
      'completion_report': completionReport,
      'customer_signature_url': customerSignatureUrl,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InstallationModel copyWith({
    String? id,
    String? applicationId,
    String? applicationNumber,
    String? consumerName,
    DateTime? installationDate,
    String? assignedTeam,
    List<String>? materialList,
    String? completionReport,
    String? customerSignatureUrl,
    InstallationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallationModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      applicationNumber: applicationNumber ?? this.applicationNumber,
      consumerName: consumerName ?? this.consumerName,
      installationDate: installationDate ?? this.installationDate,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      materialList: materialList ?? this.materialList,
      completionReport: completionReport ?? this.completionReport,
      customerSignatureUrl: customerSignatureUrl ?? this.customerSignatureUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
