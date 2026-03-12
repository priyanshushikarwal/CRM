import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import '../services/application_service.dart';
import '../services/supabase_service.dart';
import '../core/constants/app_constants.dart';

final authStateProvider = StreamProvider<bool>((ref) {
  return SupabaseService.authStateChanges.map((state) => state.session != null);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) {
    print('DEBUG: No current user from Supabase');
    return null;
  }
  print('DEBUG: Current Supabase user: ${user.email}');

  try {
    final response =
        await SupabaseService.from(
          AppConstants.usersTable,
        ).select().eq('id', user.id).maybeSingle();

    if (response != null) {
      print('DEBUG: User found in database: $response');
      return UserModel.fromJson(response);
    }

    print('DEBUG: User not found in database, creating new user record');
    final newUser = UserModel(
      id: user.id,
      email: user.email ?? '',
      role: UserRole.admin, // First user gets admin role
      createdAt: DateTime.now(),
    );

    await SupabaseService.from(
      AppConstants.usersTable,
    ).insert(newUser.toJson());

    print('DEBUG: Created new user with admin role');
    return newUser;
  } catch (e) {
    print('DEBUG: Error fetching/creating user: $e');
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      role: UserRole.staff,
      createdAt: DateTime.now(),
    );
  }
});

class ApplicationsState {
  final List<ApplicationModel> applications;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final ApplicationStatus? statusFilter;
  final String? stateFilter;
  final Map<String, int> stats;

  const ApplicationsState({
    this.applications = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.stateFilter,
    this.stats = const {},
  });

  ApplicationsState copyWith({
    List<ApplicationModel>? applications,
    bool? isLoading,
    String? error,
    String? searchQuery,
    ApplicationStatus? statusFilter,
    String? stateFilter,
    Map<String, int>? stats,
  }) {
    return ApplicationsState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      stateFilter: stateFilter ?? this.stateFilter,
      stats: stats ?? this.stats,
    );
  }
}

class ApplicationsNotifier extends Notifier<ApplicationsState> {
  @override
  ApplicationsState build() {
    return const ApplicationsState();
  }

  Future<void> loadApplications() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final applications = await ApplicationService.fetchApplications(
        searchQuery: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        status: state.statusFilter,
        state: state.stateFilter,
      );

      final stats = await ApplicationService.getApplicationStats();

      state = state.copyWith(
        applications: applications,
        isLoading: false,
        stats: stats,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadApplications();
  }

  void setStatusFilter(ApplicationStatus? status) {
    state = state.copyWith(statusFilter: status);
    loadApplications();
  }

  void setStateFilter(String? stateFilter) {
    state = state.copyWith(stateFilter: stateFilter);
    loadApplications();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      statusFilter: null,
      stateFilter: null,
    );
    loadApplications();
  }

  Future<void> deleteApplication(String id) async {
    try {
      await ApplicationService.deleteApplication(id);
      await loadApplications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<ApplicationModel?> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
    required StageStatus stageStatus,
    String? remarks,
  }) async {
    try {
      print('DEBUG: Starting updateApplicationStatus for $applicationId');
      print('DEBUG: New status: $newStatus, Stage status: $stageStatus');

      final updatedApp = await ApplicationService.updateStatus(
        applicationId: applicationId,
        newStatus: newStatus,
        stageStatus: stageStatus,
        remarks: remarks,
      );

      print('DEBUG: updateStatus completed, reloading applications...');
      await loadApplications();
      print('DEBUG: Applications reloaded successfully');

      return updatedApp;
    } catch (e, stackTrace) {
      print('ERROR updating application status: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(error: e.toString());
      rethrow; // Rethrow so the UI can catch it
    }
  }
}

final applicationsProvider =
    NotifierProvider<ApplicationsNotifier, ApplicationsState>(() {
      return ApplicationsNotifier();
    });

class SelectedApplicationNotifier extends Notifier<ApplicationModel?> {
  @override
  ApplicationModel? build() => null;

  void setApplication(ApplicationModel? app) {
    state = app;
  }

  void clear() {
    state = null;
  }
}

final selectedApplicationProvider =
    NotifierProvider<SelectedApplicationNotifier, ApplicationModel?>(() {
      return SelectedApplicationNotifier();
    });

final documentsProvider = FutureProvider.family<List<DocumentModel>, String>((
  ref,
  applicationId,
) async {
  return await DocumentService.fetchDocuments(applicationId);
});

final applicationProvider = FutureProvider.family<ApplicationModel?, String>((
  ref,
  id,
) async {
  return await ApplicationService.fetchApplication(id);
});
