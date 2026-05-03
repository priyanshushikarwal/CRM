import 'package:flutter/foundation.dart';

@immutable
class InstallerTeamModel {
  final String id;
  final String teamName;
  final String email;
  final String? userId;
  final String? phone;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallerTeamModel({
    required this.id,
    required this.teamName,
    required this.email,
    this.userId,
    this.phone,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallerTeamModel.fromJson(Map<String, dynamic> json) {
    return InstallerTeamModel(
      id: json['id'] as String,
      teamName: json['team_name'] as String,
      email: json['email'] as String,
      userId: json['user_id'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_name': teamName,
      'email': email,
      'user_id': userId,
      'phone': phone,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InstallerTeamModel copyWith({
    String? id,
    String? teamName,
    String? email,
    String? userId,
    String? phone,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallerTeamModel(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
