import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';


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
  int get totalDcrPanels => items
      .where((i) => i.isDcr)
      .fold(0, (sum, item) => sum + item.availableQuantity);
  int get totalNonDcrPanels => items
      .where((i) => !i.isDcr)
      .fold(0, (sum, item) => sum + item.availableQuantity);

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
    bool isDcr = true,
    String? invoiceNumber,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final item = SolarInventoryItem(
        id: const Uuid().v4(),
        companyName: companyName.trim(),
        panelModel: panelModel.trim(),
        capacityKw: capacityKw,
        totalQuantity: quantity,
        usedQuantity: 0,
        isDcr: isDcr,
        invoiceNumber: invoiceNumber?.trim(),
        description: description?.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await InventoryService.addMultipleInventoryItems([item]);
      await loadInventory();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> addMultipleItems({
    required String companyName,
    required List<Map<String, dynamic>> dcrModels,
    required List<Map<String, dynamic>> nonDcrModels,
    String? invoiceNumber,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final newItems = <SolarInventoryItem>[];

      for (final model in dcrModels) {
        newItems.add(
          SolarInventoryItem(
            id: const Uuid().v4(),
            companyName: companyName.trim(),
            panelModel: model['name'].toString().trim(),
            capacityKw: model['capacityKw'] as double,
            totalQuantity: model['quantity'] as int,
            usedQuantity: 0,
            isDcr: true,
            invoiceNumber: invoiceNumber?.trim(),
            description: description?.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      for (final model in nonDcrModels) {
        newItems.add(
          SolarInventoryItem(
            id: const Uuid().v4(),
            companyName: companyName.trim(),
            panelModel: model['name'].toString().trim(),
            capacityKw: model['capacityKw'] as double,
            totalQuantity: model['quantity'] as int,
            usedQuantity: 0,
            isDcr: false,
            invoiceNumber: invoiceNumber?.trim(),
            description: description?.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (newItems.isNotEmpty) {
        await InventoryService.addMultipleInventoryItems(newItems);
        await loadInventory();
      } else {
        state = state.copyWith(isLoading: false);
      }
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

final itemAssignmentsProvider =
    FutureProvider.family<List<SolarAssignment>, String>((
      ref,
      inventoryItemId,
    ) async {
      return await InventoryService.fetchAssignmentsForItem(inventoryItemId);
    });

final applicationInventoryProvider = FutureProvider.family<
  List<SolarAssignment>,
  String
>((ref, applicationId) async {
  return await InventoryService.fetchAssignmentsForApplication(applicationId);
});

final availableInventoryProvider = FutureProvider<List<SolarInventoryItem>>((
  ref,
) async {
  return await InventoryService.fetchAvailableInventory();
});
