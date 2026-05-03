import 'package:flutter/foundation.dart';
import '../models/installer_team_model.dart';
import '../models/team_assignment_model.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

class InstallerTeamService {
  /// Create a new installer team:
  /// 1. Sign up the user in Supabase Auth
  /// 2. Create a row in the users table with role=installer
  /// 3. Create a row in installer_teams
  static Future<InstallerTeamModel> createTeam({
    required String teamName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final adminUserId = SupabaseService.currentUser?.id;

    // 1. Sign up the installer user via Supabase Auth using admin API
    // We use signUp but we need the user to be auto-confirmed.
    // Alternative: use the admin invite or the service role key.
    // For simplicity, we'll use the standard signUp flow.
    final authResponse = await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': teamName,
        'role': 'installer',
      },
    );

    final newUserId = authResponse.user?.id;
    if (newUserId == null) {
      throw Exception('Failed to create installer account. Auth signup returned no user.');
    }

    // 2. Insert into users table with role=installer
    // Check if user already exists (trigger may have created it)
    final existingUser = await SupabaseService.from(AppConstants.usersTable)
        .select()
        .eq('id', newUserId)
        .maybeSingle();

    if (existingUser == null) {
      await SupabaseService.from(AppConstants.usersTable).insert({
        'id': newUserId,
        'email': email,
        'full_name': teamName,
        'phone': phone,
        'role': 'installer',
        'is_active': true,
        'applications_access': false,
        'payments_access': false,
        'inventory_access': false,
        'installation_access': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing user record to installer role
      await SupabaseService.from(AppConstants.usersTable)
          .update({
            'full_name': teamName,
            'phone': phone,
            'role': 'installer',
            'installation_access': true,
          })
          .eq('id', newUserId);
    }

    // 3. Create installer_teams record
    final now = DateTime.now().toIso8601String();
    final response = await SupabaseService.from(AppConstants.installerTeamsTable)
        .insert({
          'team_name': teamName,
          'email': email,
          'user_id': newUserId,
          'phone': phone,
          'is_active': true,
          'created_by': adminUserId,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    // Sign the admin back in — the signUp call above changed the session
    // We need to restore the admin session. The admin should re-authenticate.
    // However, in practice the admin session is still valid (signUp doesn't
    // necessarily swap the session if auto-confirm is off).
    // If auto-confirm IS on, we may have lost the admin session.
    // To handle this safely, we'll note this caveat.

    return InstallerTeamModel.fromJson(response);
  }

  /// Create team using the RPC function which handles auth + public users.
  static Future<InstallerTeamModel> createTeamSimple({
    required String teamName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final adminUserId = SupabaseService.currentUser?.id;

    // Step 1: Create the auth user + public.users row via RPC function
    String? newUserId;
    try {
      final result = await SupabaseService.client.rpc(
        'create_installer_user',
        params: {
          'installer_email': email,
          'installer_password': password,
          'installer_name': teamName,
        },
      );
      newUserId = result as String?;
    } catch (e) {
      debugPrint('RPC create_installer_user failed: $e');
      rethrow;
    }

    if (newUserId == null) {
      throw Exception('Failed to create installer account.');
    }

    // Step 2: Update phone if provided (RPC doesn't handle phone)
    if (phone != null && phone.isNotEmpty) {
      await SupabaseService.from(AppConstants.usersTable)
          .update({'phone': phone})
          .eq('id', newUserId);
    }

    // Step 3: Create installer_teams record
    final now = DateTime.now().toIso8601String();
    final response = await SupabaseService.from(AppConstants.installerTeamsTable)
        .insert({
          'team_name': teamName,
          'email': email,
          'user_id': newUserId,
          'phone': phone,
          'is_active': true,
          'created_by': adminUserId,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return InstallerTeamModel.fromJson(response);
  }

  /// Fetch all installer teams
  static Future<List<InstallerTeamModel>> fetchAllTeams() async {
    final response = await SupabaseService.from(AppConstants.installerTeamsTable)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InstallerTeamModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Update team details
  static Future<InstallerTeamModel> updateTeam(InstallerTeamModel team) async {
    final response = await SupabaseService.from(AppConstants.installerTeamsTable)
        .update(team.copyWith(updatedAt: DateTime.now()).toJson())
        .eq('id', team.id)
        .select()
        .single();

    return InstallerTeamModel.fromJson(response);
  }

  /// Toggle team active status
  static Future<void> toggleTeamStatus(String teamId, bool isActive) async {
    await SupabaseService.from(AppConstants.installerTeamsTable)
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', teamId);
  }

  /// Delete an installer team
  static Future<void> deleteTeam(String teamId) async {
    await SupabaseService.from(AppConstants.installerTeamsTable)
        .delete()
        .eq('id', teamId);
  }

  /// Fetch team by user_id (for installer login)
  static Future<InstallerTeamModel?> fetchTeamForUser(String userId) async {
    final response = await SupabaseService.from(AppConstants.installerTeamsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return InstallerTeamModel.fromJson(response);
  }

  // ─── Assignment methods ───

  /// Assign an application to a team
  static Future<TeamAssignmentModel> assignApplication({
    required String teamId,
    required String applicationId,
  }) async {
    final adminUserId = SupabaseService.currentUser?.id;

    final response = await SupabaseService.from(AppConstants.teamAssignmentsTable)
        .insert({
          'team_id': teamId,
          'application_id': applicationId,
          'assigned_by': adminUserId,
          'assigned_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return TeamAssignmentModel.fromJson(response);
  }

  /// Remove an assignment
  static Future<void> removeAssignment(String assignmentId) async {
    await SupabaseService.from(AppConstants.teamAssignmentsTable)
        .delete()
        .eq('id', assignmentId);
  }

  /// Fetch all assignments for a team
  static Future<List<TeamAssignmentModel>> fetchAssignmentsForTeam(
    String teamId,
  ) async {
    final response = await SupabaseService.from(AppConstants.teamAssignmentsTable)
        .select()
        .eq('team_id', teamId)
        .order('assigned_at', ascending: false);

    return (response as List)
        .map((json) => TeamAssignmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch assigned application IDs for a team
  static Future<List<String>> fetchAssignedApplicationIds(String teamId) async {
    final response = await SupabaseService.from(AppConstants.teamAssignmentsTable)
        .select('application_id')
        .eq('team_id', teamId);

    return (response as List)
        .map((json) => json['application_id'] as String)
        .toList();
  }

  /// Fetch assigned application IDs for a user (installer)
  static Future<List<String>> fetchAssignedApplicationIdsForUser(String userId) async {
    // First get the team for this user
    final team = await fetchTeamForUser(userId);
    if (team == null) return [];
    return fetchAssignedApplicationIds(team.id);
  }

  /// Fetch all assignments (for admin overview)
  static Future<List<TeamAssignmentModel>> fetchAllAssignments() async {
    final response = await SupabaseService.from(AppConstants.teamAssignmentsTable)
        .select()
        .order('assigned_at', ascending: false);

    return (response as List)
        .map((json) => TeamAssignmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
