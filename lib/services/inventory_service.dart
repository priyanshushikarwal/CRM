import 'package:uuid/uuid.dart';
import '../models/inventory_model.dart';
import '../core/constants/app_constants.dart';
import 'supabase_service.dart';

class InventoryService {
  static const _uuid = Uuid();


  static Future<List<SolarInventoryItem>> fetchAllInventory() async {
    try {
      final response = await SupabaseService.from(
        AppConstants.inventoryTable,
      ).select().order('company_name', ascending: true);

      return (response as List)
          .map(
            (json) => SolarInventoryItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error fetching inventory: $e');
      rethrow;
    }
  }

  static Future<List<SolarInventoryItem>> fetchAvailableInventory() async {
    try {
      final response = await SupabaseService.from(
        AppConstants.inventoryTable,
      ).select().order('company_name', ascending: true);

      return (response as List)
          .map(
            (json) => SolarInventoryItem.fromJson(json as Map<String, dynamic>),
          )
          .where((item) => item.availableQuantity > 0)
          .toList();
    } catch (e) {
      print('Error fetching available inventory: $e');
      rethrow;
    }
  }

  static Future<SolarInventoryItem> addInventoryItem({
    required String companyName,
    required String panelModel,
    required double capacityKw,
    required int quantity,
    String? description,
  }) async {
    final now = DateTime.now();
    final item = SolarInventoryItem(
      id: _uuid.v4(),
      companyName: companyName.trim(),
      panelModel: panelModel.trim(),
      capacityKw: capacityKw,
      totalQuantity: quantity,
      usedQuantity: 0,
      isDcr: true, // Default to true if not specified
      description: description?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      final response =
          await SupabaseService.from(
            AppConstants.inventoryTable,
          ).insert(item.toJson()).select().single();

      return SolarInventoryItem.fromJson(response);
    } catch (e) {
      print('Error adding inventory item: $e');
      rethrow;
    }
  }

  static Future<List<SolarInventoryItem>> addMultipleInventoryItems(
    List<SolarInventoryItem> items,
  ) async {
    try {
      final response =
          await SupabaseService.from(
            AppConstants.inventoryTable,
          ).insert(items.map((e) => e.toJson()).toList()).select();

      return (response as List)
          .map(
            (json) => SolarInventoryItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error adding multiple inventory items: $e');
      rethrow;
    }
  }

  static Future<SolarInventoryItem> updateInventoryItem(
    SolarInventoryItem item,
  ) async {
    final updated = item.copyWith(updatedAt: DateTime.now());

    try {
      final response =
          await SupabaseService.from(
            AppConstants.inventoryTable,
          ).update(updated.toJson()).eq('id', item.id).select().single();

      return SolarInventoryItem.fromJson(response);
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }

  static Future<void> deleteInventoryItem(String itemId) async {
    try {
      await SupabaseService.from(
        AppConstants.inventoryAssignmentsTable,
      ).delete().eq('inventory_item_id', itemId);

      await SupabaseService.from(
        AppConstants.inventoryTable,
      ).delete().eq('id', itemId);
    } catch (e) {
      print('Error deleting inventory item: $e');
      rethrow;
    }
  }


  static Future<SolarAssignment> assignToApplication({
    required String inventoryItemId,
    required String applicationId,
    required String applicationNumber,
    required String consumerName,
    required int quantity,
    String? notes,
  }) async {
    final inventoryResponse =
        await SupabaseService.from(
          AppConstants.inventoryTable,
        ).select().eq('id', inventoryItemId).single();

    final item = SolarInventoryItem.fromJson(inventoryResponse);

    if (item.availableQuantity < quantity) {
      throw Exception(
        'Not enough inventory. Available: ${item.availableQuantity}, Requested: $quantity',
      );
    }

    final now = DateTime.now();
    final assignment = SolarAssignment(
      id: _uuid.v4(),
      inventoryItemId: inventoryItemId,
      applicationId: applicationId,
      applicationNumber: applicationNumber,
      consumerName: consumerName,
      quantityAssigned: quantity,
      assignedAt: now,
      notes: notes,
    );

    await SupabaseService.from(
      AppConstants.inventoryAssignmentsTable,
    ).insert(assignment.toJson());

    await SupabaseService.from(AppConstants.inventoryTable)
        .update({
          'used_quantity': item.usedQuantity + quantity,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', inventoryItemId);

    return assignment;
  }

  static Future<List<SolarAssignment>> fetchAssignmentsForItem(
    String inventoryItemId,
  ) async {
    try {
      final response = await SupabaseService.from(
            AppConstants.inventoryAssignmentsTable,
          )
          .select()
          .eq('inventory_item_id', inventoryItemId)
          .order('assigned_at', ascending: false);

      return (response as List)
          .map((json) => SolarAssignment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching assignments: $e');
      rethrow;
    }
  }

  static Future<List<SolarAssignment>> fetchAssignmentsForApplication(
    String applicationId,
  ) async {
    try {
      final response = await SupabaseService.from(
            AppConstants.inventoryAssignmentsTable,
          )
          .select()
          .eq('application_id', applicationId)
          .order('assigned_at', ascending: false);

      return (response as List)
          .map((json) => SolarAssignment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching application assignments: $e');
      rethrow;
    }
  }

  static Future<void> removeAssignment(
    String assignmentId,
    String inventoryItemId,
    int quantityToReturn,
  ) async {
    try {
      final inventoryResponse =
          await SupabaseService.from(
            AppConstants.inventoryTable,
          ).select().eq('id', inventoryItemId).single();

      final item = SolarInventoryItem.fromJson(inventoryResponse);
      final newUsed = (item.usedQuantity - quantityToReturn).clamp(
        0,
        item.totalQuantity,
      );

      await SupabaseService.from(
        AppConstants.inventoryAssignmentsTable,
      ).delete().eq('id', assignmentId);

      await SupabaseService.from(AppConstants.inventoryTable)
          .update({
            'used_quantity': newUsed,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', inventoryItemId);
    } catch (e) {
      print('Error removing assignment: $e');
      rethrow;
    }
  }
}
