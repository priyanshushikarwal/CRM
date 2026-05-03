import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/installer_team_model.dart';
import '../models/team_assignment_model.dart';
import '../services/installer_team_service.dart';

// ─── Teams State ───

class InstallerTeamsState {
  final List<InstallerTeamModel> teams;
  final bool isLoading;
  final String? error;

  const InstallerTeamsState({
    this.teams = const [],
    this.isLoading = false,
    this.error,
  });

  InstallerTeamsState copyWith({
    List<InstallerTeamModel>? teams,
    bool? isLoading,
    String? error,
  }) {
    return InstallerTeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InstallerTeamsNotifier extends Notifier<InstallerTeamsState> {
  @override
  InstallerTeamsState build() {
    return const InstallerTeamsState();
  }

  Future<void> loadTeams({bool showLoading = true}) async {
    if (showLoading || state.teams.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final teams = await InstallerTeamService.fetchAllTeams();
      state = state.copyWith(teams: teams, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<InstallerTeamModel?> createTeam({
    required String teamName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final team = await InstallerTeamService.createTeamSimple(
        teamName: teamName,
        email: email,
        password: password,
        phone: phone,
      );
      await loadTeams(showLoading: false);
      return team;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleTeamStatus(String teamId, bool isActive) async {
    try {
      await InstallerTeamService.toggleTeamStatus(teamId, isActive);
      await loadTeams(showLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await InstallerTeamService.deleteTeam(teamId);
      await loadTeams(showLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final installerTeamsProvider =
    NotifierProvider<InstallerTeamsNotifier, InstallerTeamsState>(() {
  return InstallerTeamsNotifier();
});

// ─── Team Assignments ───

final teamAssignmentsProvider =
    FutureProvider.family<List<TeamAssignmentModel>, String>((ref, teamId) async {
  return await InstallerTeamService.fetchAssignmentsForTeam(teamId);
});

final assignedApplicationIdsProvider =
    FutureProvider.family<List<String>, String>((ref, teamId) async {
  return await InstallerTeamService.fetchAssignedApplicationIds(teamId);
});

// ─── Installer user's team ───

final installerTeamForUserProvider =
    FutureProvider.family<InstallerTeamModel?, String>((ref, userId) async {
  return await InstallerTeamService.fetchTeamForUser(userId);
});

// ─── Installer user's assigned application IDs ───

final installerAssignedAppIdsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  return await InstallerTeamService.fetchAssignedApplicationIdsForUser(userId);
});
