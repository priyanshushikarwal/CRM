import 'package:flutter/foundation.dart';

@immutable
class TeamAssignmentModel {
  final String id;
  final String teamId;
  final String applicationId;
  final String? assignedBy;
  final DateTime assignedAt;

  const TeamAssignmentModel({
    required this.id,
    required this.teamId,
    required this.applicationId,
    this.assignedBy,
    required this.assignedAt,
  });

  factory TeamAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TeamAssignmentModel(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      applicationId: json['application_id'] as String,
      assignedBy: json['assigned_by'] as String?,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'application_id': applicationId,
      'assigned_by': assignedBy,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }
}
