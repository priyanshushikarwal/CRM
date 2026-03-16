import 'package:uuid/uuid.dart';
import '../models/installation_model.dart';
import 'supabase_service.dart';

class InstallationService {
  static const _uuid = Uuid();

  static Future<List<InstallationModel>> fetchAllInstallations() async {
    final response = await SupabaseService.from('installations')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => InstallationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<InstallationModel?> fetchInstallationByApplicationId(
    String applicationId,
  ) async {
    final response = await SupabaseService.from('installations')
        .select()
        .eq('application_id', applicationId)
        .maybeSingle();

    if (response == null) return null;
    return InstallationModel.fromJson(response);
  }

  static Future<InstallationModel> createInstallation(
    InstallationModel installation,
  ) async {
    final response = await SupabaseService.from('installations')
        .insert(installation.toJson())
        .select()
        .single();

    return InstallationModel.fromJson(response);
  }

  static Future<InstallationModel> updateInstallation(
    InstallationModel installation,
  ) async {
    final updated = installation.copyWith(updatedAt: DateTime.now());
    final response = await SupabaseService.from('installations')
        .update(updated.toJson())
        .eq('id', installation.id)
        .select()
        .single();

    return InstallationModel.fromJson(response);
  }

  static Future<void> deleteInstallation(String id) async {
    await SupabaseService.from('installations').delete().eq('id', id);
  }

  static Future<InstallationModel> initializeInstallation({
    required String applicationId,
    required String applicationNumber,
    required String consumerName,
  }) async {
    final existing = await fetchInstallationByApplicationId(applicationId);
    if (existing != null) return existing;

    final now = DateTime.now();
    final installation = InstallationModel(
      id: _uuid.v4(),
      applicationId: applicationId,
      applicationNumber: applicationNumber,
      consumerName: consumerName,
      createdAt: now,
      updatedAt: now,
    );

    return await createInstallation(installation);
  }
}
