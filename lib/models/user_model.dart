import 'package:flutter/foundation.dart';

enum UserRole { admin, staff, factory }

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
  final bool? applicationsAccess;
  final bool? paymentsAccess;
  final bool? inventoryAccess;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.role = UserRole.staff,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.profileImageUrl,
    this.applicationsAccess,
    this.paymentsAccess,
    this.inventoryAccess,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () {
          if (json['role'] == 'superadmin' || json['role'] == 'admin') {
            return UserRole.admin;
          }
          if (json['role'] == 'factory') {
            return UserRole.factory;
          }
          return UserRole.staff;
        },
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt:
          json['last_login_at'] != null
              ? DateTime.parse(json['last_login_at'] as String)
              : null,
      profileImageUrl: json['profile_image_url'] as String?,
      applicationsAccess: json['applications_access'] as bool?,
      paymentsAccess: json['payments_access'] as bool?,
      inventoryAccess: json['inventory_access'] as bool?,
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
      'applications_access': applicationsAccess,
      'payments_access': paymentsAccess,
      'inventory_access': inventoryAccess,
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
    bool? applicationsAccess,
    bool? paymentsAccess,
    bool? inventoryAccess,
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
      applicationsAccess: applicationsAccess ?? this.applicationsAccess,
      paymentsAccess: paymentsAccess ?? this.paymentsAccess,
      inventoryAccess: inventoryAccess ?? this.inventoryAccess,
    );
  }

  String get displayName => fullName ?? email.split('@').first;

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.factory:
        return 'Factory Employee';
    }
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
  bool get isFactory => role == UserRole.factory;
  bool get hasExplicitModuleAssignments =>
      applicationsAccess != null ||
      paymentsAccess != null ||
      inventoryAccess != null;

  bool get canAccessApplications {
    if (isAdmin) return true;
    if (hasExplicitModuleAssignments) return applicationsAccess ?? false;
    return role == UserRole.staff;
  }

  bool get canAccessPayments {
    if (isAdmin) return true;
    if (hasExplicitModuleAssignments) return paymentsAccess ?? false;
    return false;
  }

  bool get canAccessInventory {
    if (isAdmin) return true;
    if (hasExplicitModuleAssignments) return inventoryAccess ?? false;
    return role == UserRole.factory;
  }

  bool get canAddInventoryStock => canAccessInventory;
  bool get canAllotInventory => canAccessInventory;
  bool get canCreateApplication => canAccessApplications;

  bool get canEdit => isAdmin;
  bool get canDelete => isAdmin;
  bool get canManageUsers => isAdmin;
  bool get canViewDashboard => isAdmin;
  bool get canManagePayments => canAccessPayments;
  bool get canManageInstallations => isAdmin;
  bool get canManageAdmins => isAdmin;

  List<String> get assignedWorkLabels {
    final labels = <String>[];
    if (canAccessApplications) labels.add('Applications');
    if (canAccessPayments) labels.add('Payments');
    if (canAccessInventory) labels.add('Inventory');
    return labels;
  }

  String get assignedWorkSummary =>
      assignedWorkLabels.isEmpty ? 'No modules assigned' : assignedWorkLabels.join(', ');
}
