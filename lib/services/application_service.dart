import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/application_model.dart';
import '../models/document_model.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

class ApplicationService {
  static const _uuid = Uuid();

  // Fetch all applications
  static Future<List<ApplicationModel>> fetchAllApplications() async {
    final response = await SupabaseService.from(
      AppConstants.applicationsTable,
    ).select().order('created_at', ascending: false);

    return (response as List)
        .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Fetch applications with filters
  static Future<List<ApplicationModel>> fetchApplications({
    String? searchQuery,
    ApplicationStatus? status,
    String? state,
    String? district,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    // Build the query step by step
    var baseQuery =
        SupabaseService.from(AppConstants.applicationsTable).select();

    // Execute with filters
    List<dynamic> response;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      response = await baseQuery
          .or(
            'application_number.ilike.%$searchQuery%,'
            'full_name.ilike.%$searchQuery%,'
            'mobile.ilike.%$searchQuery%,'
            'consumer_account_number.ilike.%$searchQuery%',
          )
          .order('created_at', ascending: false);
    } else if (status != null) {
      response = await baseQuery
          .eq('current_status', status.name)
          .order('created_at', ascending: false);
    } else if (state != null) {
      response = await baseQuery
          .eq('state', state)
          .order('created_at', ascending: false);
    } else {
      response = await baseQuery.order('created_at', ascending: false);
    }

    return response
        .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Fetch single application
  static Future<ApplicationModel?> fetchApplication(String id) async {
    final response =
        await SupabaseService.from(
          AppConstants.applicationsTable,
        ).select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return ApplicationModel.fromJson(response);
  }

  // Create new application
  static Future<ApplicationModel> createApplication(
    ApplicationModel application,
  ) async {
    final now = DateTime.now();
    final newApplication = application.copyWith(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
    );

    final response =
        await SupabaseService.from(
          AppConstants.applicationsTable,
        ).insert(newApplication.toJson()).select().single();

    return ApplicationModel.fromJson(response);
  }

  // Update application
  static Future<ApplicationModel> updateApplication(
    ApplicationModel application,
  ) async {
    print('DEBUG updateApplication: Starting update for ${application.id}');
    final updatedApplication = application.copyWith(updatedAt: DateTime.now());

    try {
      print('DEBUG updateApplication: Sending update to Supabase...');
      final response =
          await SupabaseService.from(AppConstants.applicationsTable)
              .update(updatedApplication.toJson())
              .eq('id', application.id)
              .select()
              .single();

      print('DEBUG updateApplication: Supabase response received');
      return ApplicationModel.fromJson(response);
    } catch (e) {
      print('ERROR updateApplication: $e');
      rethrow;
    }
  }

  // Delete application
  static Future<void> deleteApplication(String id) async {
    // First delete all related documents
    await SupabaseService.from(
      AppConstants.documentsTable,
    ).delete().eq('application_id', id);

    // Then delete the application
    await SupabaseService.from(
      AppConstants.applicationsTable,
    ).delete().eq('id', id);
  }

  // Update application status
  static Future<ApplicationModel> updateStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
    required StageStatus stageStatus,
    String? remarks,
  }) async {
    print(
      'DEBUG ApplicationService.updateStatus: Fetching application $applicationId',
    );
    final application = await fetchApplication(applicationId);
    if (application == null) {
      throw Exception('Application not found');
    }
    print(
      'DEBUG ApplicationService.updateStatus: Application found, creating history item',
    );

    final historyItem = StatusHistoryItem(
      id: _uuid.v4(),
      status: newStatus,
      stageStatus: stageStatus,
      timestamp: DateTime.now(),
      remarks: remarks,
      updatedBy: SupabaseService.currentUser?.email,
    );

    final updatedHistory = [...application.statusHistory, historyItem];
    print(
      'DEBUG ApplicationService.updateStatus: History updated, calling updateApplication',
    );

    final updatedApplication = application.copyWith(
      currentStatus: newStatus,
      statusHistory: updatedHistory,
    );

    print(
      'DEBUG ApplicationService.updateStatus: About to save to database...',
    );
    final result = await updateApplication(updatedApplication);
    print('DEBUG ApplicationService.updateStatus: Save completed!');
    return result;
  }

  // Generate application number
  static String generateApplicationNumber({
    required String state,
    required String scheme,
  }) {
    final stateCode = state.substring(0, 2).toUpperCase();
    final schemeCode = 'RJAJY'; // Rajasthan scheme code
    final year = DateTime.now().year.toString().substring(2);
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(
      7,
    );

    return 'NP-$schemeCode$year-$random';
  }

  // Get application statistics
  static Future<Map<String, int>> getApplicationStats() async {
    final applications = await fetchAllApplications();

    final stats = <String, int>{
      'total': applications.length,
      'pending': 0,
      'inProgress': 0,
      'completed': 0,
      'rejected': 0,
    };

    for (final app in applications) {
      if (app.currentStatus == ApplicationStatus.consumerSubsidyRequest) {
        stats['completed'] = stats['completed']! + 1;
      } else if (app.statusHistory.any(
        (h) => h.stageStatus == StageStatus.rejected,
      )) {
        stats['rejected'] = stats['rejected']! + 1;
      } else if (app.statusHistory.any(
        (h) => h.stageStatus == StageStatus.inProgress,
      )) {
        stats['inProgress'] = stats['inProgress']! + 1;
      } else {
        stats['pending'] = stats['pending']! + 1;
      }
    }

    return stats;
  }

  // ============ APPROVAL WORKFLOW METHODS ============

  // Submit application for admin approval
  static Future<ApplicationModel> submitForApproval(
    ApplicationModel application,
    String submittedByUserId,
  ) async {
    final updatedApplication = application.copyWith(
      approvalStatus: ApprovalStatus.pending,
      submittedBy: submittedByUserId,
    );
    return await updateApplication(updatedApplication);
  }

  // Admin approves the application
  static Future<ApplicationModel> approveApplication(
    ApplicationModel application,
    String approvedByUserId, {
    String? remarks,
  }) async {
    final updatedApplication = application.copyWith(
      approvalStatus: ApprovalStatus.approved,
      approvedBy: approvedByUserId,
      approvalDate: DateTime.now(),
      approvalRemarks: remarks,
    );
    return await updateApplication(updatedApplication);
  }

  // Admin rejects the application
  static Future<ApplicationModel> rejectApplication(
    ApplicationModel application,
    String rejectedByUserId, {
    String? remarks,
  }) async {
    final updatedApplication = application.copyWith(
      approvalStatus: ApprovalStatus.rejected,
      approvedBy: rejectedByUserId,
      approvalDate: DateTime.now(),
      approvalRemarks: remarks,
    );
    return await updateApplication(updatedApplication);
  }

  // Admin requests changes
  static Future<ApplicationModel> requestChanges(
    ApplicationModel application,
    String requestedByUserId,
    String remarks,
  ) async {
    final updatedApplication = application.copyWith(
      approvalStatus: ApprovalStatus.changesRequested,
      approvedBy: requestedByUserId,
      approvalDate: DateTime.now(),
      approvalRemarks: remarks,
    );
    return await updateApplication(updatedApplication);
  }

  // Fetch applications pending approval (for admin dashboard)
  static Future<List<ApplicationModel>> fetchPendingApprovals() async {
    final response = await SupabaseService.from(AppConstants.applicationsTable)
        .select()
        .eq('approval_status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Fetch applications by approval status
  static Future<List<ApplicationModel>> fetchByApprovalStatus(
    ApprovalStatus status,
  ) async {
    final response = await SupabaseService.from(AppConstants.applicationsTable)
        .select()
        .eq('approval_status', status.name)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

class DocumentService {
  static const _uuid = Uuid();

  // Fetch documents for an application
  static Future<List<DocumentModel>> fetchDocuments(
    String applicationId,
  ) async {
    final response = await SupabaseService.from(AppConstants.documentsTable)
        .select()
        .eq('application_id', applicationId)
        .order('uploaded_on', ascending: false);

    return (response as List)
        .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Upload document
  static Future<DocumentModel> uploadDocument({
    required String applicationId,
    required String documentType,
    required File file,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileExtension = fileName.split('.').last;
    final storagePath = '$applicationId/${_uuid.v4()}.$fileExtension';

    // Upload to Supabase Storage
    await SupabaseService.storage
        .from(AppConstants.documentsBucket)
        .upload(storagePath, file);

    // Get public URL
    final fileUrl = SupabaseService.storage
        .from(AppConstants.documentsBucket)
        .getPublicUrl(storagePath);

    // Create document record
    final document = DocumentModel(
      id: _uuid.v4(),
      applicationId: applicationId,
      documentType: documentType,
      fileName: fileName,
      filePath: storagePath,
      fileUrl: fileUrl,
      fileSize: await file.length(),
      uploadedOn: DateTime.now(),
      uploadedBy: SupabaseService.currentUser?.email,
    );

    await SupabaseService.from(
      AppConstants.documentsTable,
    ).insert(document.toJson());

    return document;
  }

  // Delete document
  static Future<void> deleteDocument(DocumentModel document) async {
    // Delete from storage
    await SupabaseService.storage.from(AppConstants.documentsBucket).remove([
      document.filePath,
    ]);

    // Delete record
    await SupabaseService.from(
      AppConstants.documentsTable,
    ).delete().eq('id', document.id);
  }
}
