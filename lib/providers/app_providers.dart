import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/application_model.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import '../models/installation_model.dart';
import '../models/payment_model.dart';
import '../services/application_service.dart';
import '../services/installation_service.dart';
import '../services/payment_service.dart';
import '../services/supabase_service.dart';
import '../services/user_service.dart';
import '../core/constants/app_constants.dart';
import 'inventory_providers.dart';
import 'refresh_providers.dart';

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
      fullName: user.userMetadata?['full_name'] as String?,
      phone: user.userMetadata?['phone'] as String?,
      role: UserRole.staff,
      applicationsAccess: false,
      paymentsAccess: false,
      inventoryAccess: false,
      createdAt: DateTime.now(),
    );

    await SupabaseService.from(
      AppConstants.usersTable,
    ).insert(newUser.toJson());

    print('DEBUG: Created new user with default restricted access');
    return newUser;
  } catch (e) {
    print('DEBUG: Error fetching/creating user: $e');
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      role: UserRole.staff,
      applicationsAccess: false,
      paymentsAccess: false,
      inventoryAccess: false,
      createdAt: DateTime.now(),
    );
  }
});

final userByIdProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  ref.watch(appDataRefreshProvider);
  return await UserService.fetchUser(userId);
});

final realtimeSyncProvider = Provider<void>((ref) {
  Timer? appRefreshDebounce;
  Timer? inventoryRefreshDebounce;
  Timer? userRefreshDebounce;
  final channels = <RealtimeChannel>[];

  void scheduleAppRefresh() {
    appRefreshDebounce?.cancel();
    appRefreshDebounce = Timer(const Duration(milliseconds: 100), () {
      ref.read(appDataRefreshProvider.notifier).bump();

      Future.microtask(() {
        ref.invalidate(documentsProvider);
        ref.invalidate(applicationProvider);
        ref.invalidate(installationByAppProvider);
        ref.invalidate(paymentsProvider);
        ref.invalidate(paymentStatsProvider);
        ref.invalidate(allPaymentsProvider);
        ref.invalidate(paymentRecordsProvider);
        ref.invalidate(revenueReportProvider);
      });
    });
  }

  void scheduleCurrentUserRefresh() {
    userRefreshDebounce?.cancel();
    userRefreshDebounce = Timer(const Duration(milliseconds: 100), () {
      ref.invalidate(currentUserProvider);
    });
  }

  void scheduleInventoryRefresh() {
    inventoryRefreshDebounce?.cancel();
    inventoryRefreshDebounce = Timer(const Duration(milliseconds: 150), () {
      ref.read(inventoryProvider.notifier).loadAll(showLoading: false);
    });
  }

  RealtimeChannel registerChannel(
    String name,
    List<String> tables, {
    required void Function() onChange,
  }) {
    var channel = SupabaseService.channel(name);
    for (final table in tables) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => onChange(),
      );
    }
    channel.subscribe();
    channels.add(channel);
    return channel;
  }

  registerChannel('crm-user-data', [
    AppConstants.usersTable,
  ], onChange: scheduleCurrentUserRefresh);

  registerChannel('crm-app-data', [
    AppConstants.applicationsTable,
    AppConstants.documentsTable,
    'payments',
    'installations',
  ], onChange: scheduleAppRefresh);

  registerChannel('crm-inventory-data', [
    AppConstants.inventoryInvoicesTable,
    AppConstants.panelItemsTable,
    AppConstants.inverterItemsTable,
    AppConstants.meterItemsTable,
    AppConstants.inventoryAllotmentsTable,
  ], onChange: scheduleInventoryRefresh);

  ref.onDispose(() {
    appRefreshDebounce?.cancel();
    inventoryRefreshDebounce?.cancel();
    userRefreshDebounce?.cancel();
    for (final channel in channels) {
      SupabaseService.client.removeChannel(channel);
    }
  });
});

class ApplicationsState {
  final List<ApplicationModel> applications;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final ApplicationStatus? statusFilter;
  final String? stateFilter;
  final Map<String, dynamic> stats;

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
    Map<String, dynamic>? stats,
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
    ref.listen<int>(appDataRefreshProvider, (_, __) {
      Future.microtask(() => loadApplications(showLoading: false));
    });
    return const ApplicationsState();
  }

  Future<void> loadApplications({bool showLoading = true}) async {
    if (showLoading || state.applications.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    } else if (state.error != null) {
      state = state.copyWith(error: null);
    }

    try {
      final results = await Future.wait<dynamic>([
        ApplicationService.fetchApplications(
          searchQuery: state.searchQuery.isNotEmpty ? state.searchQuery : null,
          status: state.statusFilter,
          state: state.stateFilter,
        ),
        ApplicationService.getApplicationStats(),
      ]);

      final applications = results[0] as List<ApplicationModel>;
      final stats = results[1] as Map<String, dynamic>;

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
  ref.watch(appDataRefreshProvider);
  return await DocumentService.fetchDocuments(applicationId);
});

final applicationProvider = FutureProvider.family<ApplicationModel?, String>((
  ref,
  id,
) async {
  ref.watch(appDataRefreshProvider);
  return await ApplicationService.fetchApplication(id);
});

class InstallationsState {
  final List<InstallationModel> installations;
  final bool isLoading;
  final String? error;

  const InstallationsState({
    this.installations = const [],
    this.isLoading = false,
    this.error,
  });

  InstallationsState copyWith({
    List<InstallationModel>? installations,
    bool? isLoading,
    String? error,
  }) {
    return InstallationsState(
      installations: installations ?? this.installations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InstallationsNotifier extends Notifier<InstallationsState> {
  @override
  InstallationsState build() {
    ref.listen<int>(appDataRefreshProvider, (_, __) {
      Future.microtask(() => loadInstallations(showLoading: false));
    });
    return const InstallationsState();
  }

  Future<void> loadInstallations({bool showLoading = true}) async {
    if (showLoading || state.installations.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    } else if (state.error != null) {
      state = state.copyWith(error: null);
    }
    try {
      final installations = await InstallationService.fetchAllInstallations();
      state = state.copyWith(installations: installations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateInstallation(InstallationModel installation) async {
    try {
      await InstallationService.updateInstallation(installation);
      await loadInstallations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final installationsProvider =
    NotifierProvider<InstallationsNotifier, InstallationsState>(() {
  return InstallationsNotifier();
});

final installationByAppProvider = FutureProvider.family<InstallationModel?, String>((
  ref,
  applicationId,
) async {
  ref.watch(appDataRefreshProvider);
  return await InstallationService.fetchInstallationByApplicationId(applicationId);
});

final paymentsProvider = FutureProvider.family<List<PaymentModel>, String>((
  ref,
  applicationId,
) async {
  ref.watch(appDataRefreshProvider);
  return await PaymentService.fetchPayments(applicationId);
});

final paymentStatsProvider = FutureProvider.family<Map<String, double>, ({String id, double total})>((
  ref,
  arg,
) async {
  ref.watch(appDataRefreshProvider);
  return await PaymentService.getPaymentStats(arg.id, arg.total);
});

final allPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  ref.watch(appDataRefreshProvider);
  return await PaymentService.fetchAllPayments();
});

class PaymentRecordRow {
  final PaymentModel payment;
  final ApplicationModel? application;

  const PaymentRecordRow({
    required this.payment,
    required this.application,
  });
}

final paymentRecordsProvider = FutureProvider<List<PaymentRecordRow>>((ref) async {
  ref.watch(appDataRefreshProvider);
  final payments = await PaymentService.fetchAllPayments();
  final applications = await ApplicationService.fetchAllApplications();
  final applicationsById = {
    for (final application in applications) application.id: application,
  };

  return payments
      .map(
        (payment) => PaymentRecordRow(
          payment: payment,
          application: applicationsById[payment.applicationId],
        ),
      )
      .toList();
});

final revenueReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  ref.watch(appDataRefreshProvider);
  final payments = await ref.watch(allPaymentsProvider.future);
  final now = DateTime.now();
  
  double totalRevenue = 0;
  double monthlyRevenue = 0;
  Map<String, double> monthlyData = {};
  
  for (final payment in payments) {
    totalRevenue += payment.amount;
    
    if (payment.paymentDate.year == now.year && payment.paymentDate.month == now.month) {
      monthlyRevenue += payment.amount;
    }
    
    // Group by Month-Year for chart
    final monthKey = DateFormat('MMM yyyy').format(payment.paymentDate);
    monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + payment.amount;
  }
  
  return {
    'totalRevenue': totalRevenue,
    'monthlyRevenue': monthlyRevenue,
    'monthlyData': monthlyData,
    'recentPayments': payments.take(10).toList(),
  };
});

final globalRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(appDataRefreshProvider.notifier).bump();

    await Future.wait([
      ref.read(applicationsProvider.notifier).loadApplications(),
      ref.read(installationsProvider.notifier).loadInstallations(),
      ref.read(inventoryProvider.notifier).loadAll(),
      ref.refresh(currentUserProvider.future),
      ref.refresh(allPaymentsProvider.future),
      ref.refresh(paymentRecordsProvider.future),
      ref.refresh(revenueReportProvider.future),
    ]);

    ref.invalidate(documentsProvider);
    ref.invalidate(applicationProvider);
    ref.invalidate(installationByAppProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(paymentStatsProvider);
  };
});
