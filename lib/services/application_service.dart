import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/application_model.dart';
import '../models/document_model.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

class ApplicationService {
  static const _uuid = Uuid();

  static Future<List<ApplicationModel>> fetchAllApplications() async {
    final response = await SupabaseService.from(AppConstants.applicationsTable)
        .select()
        .order('created_at', ascending: false)
        .timeout(
          const Duration(seconds: 10),
          onTimeout:
              () =>
                  throw Exception(
                    'Connection timed out. Please restore your Supabase project at supabase.com/dashboard',
                  ),
        );

    return (response as List)
        .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

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
    var query = SupabaseService.from(AppConstants.applicationsTable).select();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'application_number.ilike.%$searchQuery%,'
        'full_name.ilike.%$searchQuery%,'
        'mobile.ilike.%$searchQuery%,'
        'consumer_account_number.ilike.%$searchQuery%',
      );
    }

    if (status != null) {
      query = query.eq('current_status', status.name);
    }

    if (state != null) {
      query = query.eq('state', state);
    }

    if (district != null) {
      query = query.eq('district', district);
    }

    final response = await query
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 10));

    return response.map((json) => ApplicationModel.fromJson(json)).toList();
  }

  static Future<ApplicationModel?> fetchApplication(String id) async {
    final response =
        await SupabaseService.from(
          AppConstants.applicationsTable,
        ).select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return ApplicationModel.fromJson(response);
  }

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

  static Future<ApplicationModel> updateApplication(
    ApplicationModel application,
  ) async {
    final updatedApplication = application.copyWith(updatedAt: DateTime.now());

    try {
      final response =
          await SupabaseService.from(AppConstants.applicationsTable)
              .update(updatedApplication.toJson())
              .eq('id', application.id)
              .select()
              .single();

      return ApplicationModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteApplication(String id) async {
    await SupabaseService.from(
      AppConstants.documentsTable,
    ).delete().eq('application_id', id);

    await SupabaseService.from(
      AppConstants.applicationsTable,
    ).delete().eq('id', id);
  }

  static Future<ApplicationModel> updateStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
    required StageStatus stageStatus,
    String? remarks,
  }) async {
    final application = await fetchApplication(applicationId);
    if (application == null) {
      throw Exception('Application not found');
    }

    final updatedBy = await SupabaseService.currentUserDisplayName();
    final historyItem = StatusHistoryItem(
      id: _uuid.v4(),
      status: newStatus,
      stageStatus: stageStatus,
      timestamp: DateTime.now(),
      remarks: remarks,
      updatedBy: updatedBy,
    );

    final updatedHistory = [...application.statusHistory, historyItem];

    final updatedApplication = application.copyWith(
      currentStatus: newStatus,
      statusHistory: updatedHistory,
    );

    final result = await updateApplication(updatedApplication);

    return result;
  }

  static Future<String> generateApplicationNumber() async {
    const startingNumber = 11011;
    final applications = await fetchAllApplications();

    var maxNumber = startingNumber - 1;
    for (final application in applications) {
      final parsedNumber = int.tryParse(application.applicationNumber.trim());
      if (parsedNumber != null && parsedNumber > maxNumber) {
        maxNumber = parsedNumber;
      }
    }

    return (maxNumber + 1).toString();
  }

  static Future<Map<String, dynamic>> getApplicationStats() async {
    final applications =
        (await fetchAllApplications())
            .where((app) => app.approvalStatus == ApprovalStatus.approved)
            .toList();
    final now = DateTime.now();

    double totalRevenue = 0;
    int completedInstallations = 0;
    int monthlyInstallations = 0;
    int pending = 0;
    double domesticKw = 0;
    double commercialKw = 0;

    for (final app in applications) {
      if (app.categoryName.toLowerCase() == 'domestic') {
        domesticKw += app.proposedCapacity;
      } else if (app.categoryName.toLowerCase() == 'commercial') {
        commercialKw += app.proposedCapacity;
      }

      if (app.currentStatus == ApplicationStatus.applicationReceived) {
        pending++;
      }

      if (app.currentStatus == ApplicationStatus.installationCompleted ||
          app.currentStatus == ApplicationStatus.subsidyProcess ||
          app.currentStatus == ApplicationStatus.completeWorkDone) {
        completedInstallations++;
        totalRevenue += app.finalAmount ?? 0;

        if (app.updatedAt.month == now.month &&
            app.updatedAt.year == now.year) {
          monthlyInstallations++;
        }
      }
    }

    return {
      'total': applications.length,
      'pending': pending,
      'completedInstallations': completedInstallations,
      'monthlyInstallations': monthlyInstallations,
      'totalRevenue': totalRevenue,
      'inProgress': applications.length - pending - completedInstallations,
      'domesticKw': domesticKw,
      'commercialKw': commercialKw,
    };
  }

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

  static Future<List<ApplicationModel>> fetchPendingApprovals() async {
    final response = await SupabaseService.from(AppConstants.applicationsTable)
        .select()
        .eq('approval_status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

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

  static Future<DocumentModel> uploadDocument({
    required String applicationId,
    required String documentType,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final uploadedBy = await SupabaseService.currentUserDisplayName();
    final fileExtension = fileName.split('.').last;
    final storagePath = '$applicationId/${_uuid.v4()}.$fileExtension';

    await SupabaseService.storage
        .from(AppConstants.documentsBucket)
        .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final fileUrl = SupabaseService.storage
        .from(AppConstants.documentsBucket)
        .getPublicUrl(storagePath);

    final document = DocumentModel(
      id: _uuid.v4(),
      applicationId: applicationId,
      documentType: documentType,
      fileName: fileName,
      filePath: storagePath,
      fileUrl: fileUrl,
      fileSize: fileBytes.length,
      uploadedOn: DateTime.now(),
      uploadedBy: uploadedBy,
    );

    await SupabaseService.from(
      AppConstants.documentsTable,
    ).insert(document.toJson());

    return document;
  }

  static Future<void> deleteDocument(DocumentModel document) async {
    await SupabaseService.storage.from(AppConstants.documentsBucket).remove([
      document.filePath,
    ]);

    await SupabaseService.from(
      AppConstants.documentsTable,
    ).delete().eq('id', document.id);
  }

  static Future<void> verifyDocument({
    required String documentId,
    required String status,
  }) async {
    final verifiedBy = await SupabaseService.currentUserDisplayName();
    await SupabaseService.from(AppConstants.documentsTable)
        .update({'verification_status': status, 'verified_by': verifiedBy})
        .eq('id', documentId);
  }
}
