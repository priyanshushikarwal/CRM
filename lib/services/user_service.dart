import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteUserResult {
  final bool accessRevoked;
  final bool authDeleted;
  final String? message;

  const DeleteUserResult({
    required this.accessRevoked,
    required this.authDeleted,
    this.message,
  });

  bool get fullyDeleted => accessRevoked && authDeleted;
}

class UserService {
  static Future<List<UserModel>> fetchAllUsers() async {
    final response = await SupabaseService.from(
      AppConstants.usersTable,
    ).select().order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<UserModel?> fetchUser(String id) async {
    final response =
        await SupabaseService.from(
          AppConstants.usersTable,
        ).select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  static Future<UserModel?> fetchUserByEmail(String email) async {
    final response =
        await SupabaseService.from(
          AppConstants.usersTable,
        ).select().eq('email', email).maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  static Future<UserModel> updateUser(UserModel user) async {
    final response =
        await SupabaseService.from(
          AppConstants.usersTable,
        ).update(user.toJson()).eq('id', user.id).select().single();

    return UserModel.fromJson(response);
  }

  static Future<void> revokeUserAccess(String userId) async {
    await SupabaseService.from(AppConstants.usersTable)
        .update({
          'is_active': false,
          'role': UserRole.staff.name,
          'applications_access': false,
          'payments_access': false,
          'inventory_access': false,
        })
        .eq('id', userId);
  }

  static Future<DeleteUserResult> deleteUser(UserModel user) async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == user.id) {
      throw Exception('You cannot delete your own account while logged in.');
    }

    await revokeUserAccess(user.id);

    try {
      await SupabaseService.client.rpc(
        'delete_user_account',
        params: {'target_user_id': user.id},
      );
      return const DeleteUserResult(accessRevoked: true, authDeleted: true);
    } on PostgrestException catch (e) {
      return DeleteUserResult(
        accessRevoked: true,
        authDeleted: false,
        message:
            'User access was removed, but full Supabase deletion failed. '
            'Please add the `delete_user_account` SQL function in Supabase. '
            'Original error: ${e.message}',
      );
    }
  }

  static Future<void> updateUserRole(String userId, UserRole newRole) async {
    await SupabaseService.from(
      AppConstants.usersTable,
    ).update({'role': newRole.name}).eq('id', userId);
  }

  static Future<void> deactivateUser(String userId) async {
    await SupabaseService.from(
      AppConstants.usersTable,
    ).update({'is_active': false}).eq('id', userId);
  }

  static Future<void> activateUser(String userId) async {
    await SupabaseService.from(
      AppConstants.usersTable,
    ).update({'is_active': true}).eq('id', userId);
  }

  static Future<void> updateLastLogin(String userId) async {
    await SupabaseService.from(AppConstants.usersTable)
        .update({'last_login_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  static Future<bool> isUserActive(String userId) async {
    final response =
        await SupabaseService.from(
          AppConstants.usersTable,
        ).select('is_active').eq('id', userId).maybeSingle();

    if (response == null) return false;
    return response['is_active'] as bool? ?? true;
  }

  static Future<UserRole?> getUserRole(String userId) async {
    final response =
        await SupabaseService.from(
          AppConstants.usersTable,
        ).select('role').eq('id', userId).maybeSingle();

    if (response == null) return null;

    return UserRole.values.firstWhere(
      (e) => e.name == response['role'],
      orElse: () => UserRole.staff,
    );
  }
}
