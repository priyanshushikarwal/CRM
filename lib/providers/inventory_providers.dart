import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';

// ===================== INVENTORY STATE =====================

class InventoryState {
  final List<SolarInventoryItem> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  List<SolarInventoryItem> get filteredItems {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((item) {
      return item.companyName.toLowerCase().contains(q) ||
          item.panelModel.toLowerCase().contains(q) ||
          item.capacityKw.toString().contains(q);
    }).toList();
  }

  int get totalPanels => items.fold(0, (sum, item) => sum + item.totalQuantity);
  int get usedPanels => items.fold(0, (sum, item) => sum + item.usedQuantity);
  int get availablePanels =>
      items.fold(0, (sum, item) => sum + item.availableQuantity);

  InventoryState copyWith({
    List<SolarInventoryItem>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ===================== INVENTORY NOTIFIER =====================

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() => const InventoryState();

  Future<void> loadInventory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await InventoryService.fetchAllInventory();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addItem({
    required String companyName,
    required String panelModel,
    required double capacityKw,
    required int quantity,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await InventoryService.addInventoryItem(
        companyName: companyName,
        panelModel: panelModel,
        capacityKw: capacityKw,
        quantity: quantity,
        description: description,
      );
      await loadInventory();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateItem(SolarInventoryItem item) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await InventoryService.updateInventoryItem(item);
      await loadInventory();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await InventoryService.deleteInventoryItem(itemId);
      await loadInventory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> assignToApplication({
    required String inventoryItemId,
    required String applicationId,
    required String applicationNumber,
    required String consumerName,
    required int quantity,
    String? notes,
  }) async {
    try {
      await InventoryService.assignToApplication(
        inventoryItemId: inventoryItemId,
        applicationId: applicationId,
        applicationNumber: applicationNumber,
        consumerName: consumerName,
        quantity: quantity,
        notes: notes,
      );
      await loadInventory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  () {
    return InventoryNotifier();
  },
);

// Provider for assignments of a specific inventory item
final itemAssignmentsProvider =
    FutureProvider.family<List<SolarAssignment>, String>((
      ref,
      inventoryItemId,
    ) async {
      return await InventoryService.fetchAssignmentsForItem(inventoryItemId);
    });

// Provider for assignments of a specific application
final applicationInventoryProvider = FutureProvider.family<
  List<SolarAssignment>,
  String
>((ref, applicationId) async {
  return await InventoryService.fetchAssignmentsForApplication(applicationId);
});

// Provider for available inventory (for vendor selection dropdown)
final availableInventoryProvider = FutureProvider<List<SolarInventoryItem>>((
  ref,
) async {
  return await InventoryService.fetchAvailableInventory();
});
