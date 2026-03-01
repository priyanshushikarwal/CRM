import 'package:flutter/foundation.dart';

enum UserRole { superadmin, admin, vendor, operator, viewer }

@immutable
class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.role = UserRole.viewer,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.viewer,
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt:
          json['last_login_at'] != null
              ? DateTime.parse(json['last_login_at'] as String)
              : null,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'profile_image_url': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  String get displayName => fullName ?? email.split('@').first;

  String get roleDisplayName {
    switch (role) {
      case UserRole.superadmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.operator:
        return 'Operator';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  bool get isSuperAdmin => role == UserRole.superadmin;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superadmin;
  bool get canEdit =>
      role == UserRole.superadmin ||
      role == UserRole.admin ||
      role == UserRole.operator ||
      role == UserRole.vendor;
  bool get canDelete => role == UserRole.superadmin || role == UserRole.admin;
  bool get canManageUsers =>
      role == UserRole.superadmin || role == UserRole.admin;
  bool get canManageAdmins =>
      role == UserRole.superadmin; // Only superadmin can change admin roles
}
