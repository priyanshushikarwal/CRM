import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';

class InventoryState {
  final List<PanelItem> panels;
  final List<InverterItem> inverters;
  final List<MeterItem> meters;
  final List<InventoryInvoice> invoices;
  final List<InventoryAllotment> allotments;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const InventoryState({
    this.panels = const [],
    this.inverters = const [],
    this.meters = const [],
    this.invoices = const [],
    this.allotments = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  InventoryState copyWith({
    List<PanelItem>? panels,
    List<InverterItem>? inverters,
    List<MeterItem>? meters,
    List<InventoryInvoice>? invoices,
    List<InventoryAllotment>? allotments,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return InventoryState(
      panels: panels ?? this.panels,
      inverters: inverters ?? this.inverters,
      meters: meters ?? this.meters,
      invoices: invoices ?? this.invoices,
      allotments: allotments ?? this.allotments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() {
    return const InventoryState();
  }

  String _normalizeSerial(String serial) => serial.trim().toUpperCase();

  Never _throwDuplicateSerialError(String serial, String itemLabel) {
    throw Exception(
      'Duplicate Serial Number: $itemLabel serial "$serial" already exists in inventory.',
    );
  }

  void _ensureUniquePanelSerials(List<Map<String, dynamic>> panelEntries) {
    final existingSerials =
        state.panels.map((item) => _normalizeSerial(item.serialNumber)).toSet();
    final seenSerials = <String>{};

    for (final entry in panelEntries) {
      final originalSerial = (entry['serial'] as String? ?? '').trim();
      final normalizedSerial = _normalizeSerial(originalSerial);

      if (normalizedSerial.isEmpty) {
        continue;
      }

      if (!seenSerials.add(normalizedSerial) ||
          existingSerials.contains(normalizedSerial)) {
        _throwDuplicateSerialError(originalSerial, 'Panel');
      }
    }
  }

  void _ensureUniqueSimpleSerials(
    List<String> serialNumbers,
    Set<String> existingSerials,
    String itemLabel,
  ) {
    final seenSerials = <String>{};

    for (final serial in serialNumbers) {
      final originalSerial = serial.trim();
      final normalizedSerial = _normalizeSerial(originalSerial);

      if (normalizedSerial.isEmpty) {
        continue;
      }

      if (!seenSerials.add(normalizedSerial) ||
          existingSerials.contains(normalizedSerial)) {
        _throwDuplicateSerialError(originalSerial, itemLabel);
      }
    }
  }

  Future<void> loadAll({bool showLoading = true}) async {
    if (showLoading ||
        (state.panels.isEmpty &&
            state.inverters.isEmpty &&
            state.meters.isEmpty)) {
      state = state.copyWith(isLoading: true, error: null);
    } else if (state.error != null) {
      state = state.copyWith(error: null);
    }

    try {
      final results = await Future.wait<dynamic>([
        InventoryService.fetchPanels(),
        InventoryService.fetchInverters(),
        InventoryService.fetchMeters(),
        InventoryService.fetchAllotments(),
        InventoryService.fetchInvoices(InventoryItemType.panel),
        InventoryService.fetchInvoices(InventoryItemType.inverter),
        InventoryService.fetchInvoices(InventoryItemType.meter),
      ]);

      final panels = results[0] as List<PanelItem>;
      final inverters = results[1] as List<InverterItem>;
      final meters = results[2] as List<MeterItem>;
      final fetchedAllotments = results[3] as List<InventoryAllotment>;
      final pInvoices = results[4] as List<InventoryInvoice>;
      final iInvoices = results[5] as List<InventoryInvoice>;
      final mInvoices = results[6] as List<InventoryInvoice>;

      final panelIds = panels.map((item) => item.id).toSet();
      final inverterIds = inverters.map((item) => item.id).toSet();
      final meterIds = meters.map((item) => item.id).toSet();

      final latestAllotmentByItemKey = <String, InventoryAllotment>{};
      for (final allotment in fetchedAllotments) {
        final isActiveItem = switch (allotment.itemType) {
          InventoryItemType.panel => panelIds.contains(allotment.itemId),
          InventoryItemType.inverter => inverterIds.contains(allotment.itemId),
          InventoryItemType.meter => meterIds.contains(allotment.itemId),
          InventoryItemType.battery || InventoryItemType.other => false,
        };

        if (!isActiveItem) continue;

        final key = '${allotment.itemType.name}:${allotment.itemId}';
        final existing = latestAllotmentByItemKey[key];
        if (existing == null ||
            allotment.handoverDate.isAfter(existing.handoverDate) ||
            (allotment.handoverDate.isAtSameMomentAs(existing.handoverDate) &&
                allotment.createdAt.isAfter(existing.createdAt))) {
          latestAllotmentByItemKey[key] = allotment;
        }
      }

      final allotments =
          latestAllotmentByItemKey.values.toList()
            ..sort((a, b) => b.handoverDate.compareTo(a.handoverDate));

      state = state.copyWith(
        panels: panels,
        inverters: inverters,
        meters: meters,
        allotments: allotments,
        invoices: [...pInvoices, ...iInvoices, ...mInvoices],
        isLoading: false,
      );
    } catch (e, stack) {
      print('Inventory Error: $e');
      print(stack);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadStockOnly({bool showLoading = true}) async {
    if (showLoading ||
        (state.panels.isEmpty &&
            state.inverters.isEmpty &&
            state.meters.isEmpty)) {
      state = state.copyWith(isLoading: true, error: null);
    } else if (state.error != null) {
      state = state.copyWith(error: null);
    }

    try {
      final results = await Future.wait<dynamic>([
        InventoryService.fetchPanels(),
        InventoryService.fetchInverters(),
        InventoryService.fetchMeters(),
      ]);

      final panels = results[0] as List<PanelItem>;
      final inverters = results[1] as List<InverterItem>;
      final meters = results[2] as List<MeterItem>;

      state = state.copyWith(
        panels: panels,
        inverters: inverters,
        meters: meters,
        isLoading: false,
      );
    } catch (e, stack) {
      print('Inventory stock load error: $e');
      print(stack);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addPanels({
    required InventoryInvoice invoice,
    required String brand,
    required List<Map<String, dynamic>>
    panelEntries, // [{serial, capacity, type}]
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      _ensureUniquePanelSerials(panelEntries);

      final savedInvoice = await InventoryService.createInvoice(
        invoiceNumber: invoice.invoiceNumber,
        invoiceDate: invoice.invoiceDate,
        partyName: invoice.partyName,
        price: invoice.price,
        receivedBy: invoice.receivedBy,
        itemType: InventoryItemType.panel,
      );

      final items =
          panelEntries
              .map(
                (e) => PanelItem(
                  id: '',
                  invoiceId: savedInvoice.id,
                  serialNumber: (e['serial'] as String).trim(),
                  brand: brand,
                  wattCapacity: e['capacity'] as int,
                  panelType: e['type'] as String,
                  status: 'available',
                  createdAt: DateTime.now(),
                ),
              )
              .toList();

      await InventoryService.addPanelItems(items);
      await loadAll();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('23505')) {
        errorMessage =
            'Duplicate Serial Number: One or more panels already exist in inventory.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> addInverters({
    required InventoryInvoice invoice,
    required List<String> serialNumbers,
    required String brand,
    required double capacityKw,
    required String inverterType,
    required String inverterPhase,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      _ensureUniqueSimpleSerials(
        serialNumbers,
        state.inverters
            .map((item) => _normalizeSerial(item.serialNumber))
            .toSet(),
        'Inverter',
      );

      final savedInvoice = await InventoryService.createInvoice(
        invoiceNumber: invoice.invoiceNumber,
        invoiceDate: invoice.invoiceDate,
        partyName: invoice.partyName,
        price: invoice.price,
        receivedBy: invoice.receivedBy,
        itemType: InventoryItemType.inverter,
      );

      final items =
          serialNumbers
              .map(
                (sn) => InverterItem(
                  id: '',
                  invoiceId: savedInvoice.id,
                  serialNumber: sn.trim(),
                  brand: brand,
                  capacityKw: capacityKw,
                  inverterType: inverterType,
                  inverterPhase: inverterPhase,
                  status: 'available',
                  createdAt: DateTime.now(),
                ),
              )
              .toList();

      await InventoryService.addInverterItems(items);
      await loadAll();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('23505')) {
        errorMessage =
            'Duplicate Serial Number: One or more inverters already exist in inventory.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> addMeters({
    required InventoryInvoice invoice,
    required List<String> serialNumbers,
    required String brand,
    required String category,
    required String type,
    required String phase,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      _ensureUniqueSimpleSerials(
        serialNumbers,
        state.meters.map((item) => _normalizeSerial(item.serialNumber)).toSet(),
        'Meter',
      );

      final savedInvoice = await InventoryService.createInvoice(
        invoiceNumber: invoice.invoiceNumber,
        invoiceDate: invoice.invoiceDate,
        partyName: invoice.partyName,
        price: invoice.price,
        receivedBy: invoice.receivedBy,
        itemType: InventoryItemType.meter,
      );

      final items =
          serialNumbers
              .map(
                (sn) => MeterItem(
                  id: '',
                  invoiceId: savedInvoice.id,
                  serialNumber: sn.trim(),
                  brand: brand,
                  meterCategory: category,
                  meterType: type,
                  meterPhase: phase,
                  status: 'available',
                  createdAt: DateTime.now(),
                ),
              )
              .toList();

      await InventoryService.addMeterItems(items);
      await loadAll();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('23505')) {
        errorMessage =
            'Duplicate Serial Number: One or more meters already exist in inventory.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> updatePanel(PanelItem item) async {
    state = state.copyWith(isLoading: true);
    try {
      await InventoryService.updatePanelItem(item);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateInvoice(InventoryInvoice invoice) async {
    state = state.copyWith(isLoading: true);
    try {
      await InventoryService.updateInvoice(invoice);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deletePanel(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await InventoryService.deletePanelItem(id);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateInverter(InverterItem item) async {
    state = state.copyWith(isLoading: true);
    try {
      await InventoryService.updateInverterItem(item);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteInverter(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await InventoryService.deleteInverterItem(id);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateMeter(MeterItem item) async {
    state = state.copyWith(isLoading: true);
    try {
      await InventoryService.updateMeterItem(item);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteMeter(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await InventoryService.deleteMeterItem(id);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> allotItem({
    required String itemId,
    required InventoryItemType itemType,
    required String customerName,
    String? customerAddress,
    String? customerMobile,
    String? applicationId,
    String? handoverBy,
    required DateTime handoverDate,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final allotment = InventoryAllotment(
        id: '',
        itemId: itemId,
        itemType: itemType,
        customerName: customerName,
        customerAddress: customerAddress,
        customerMobile: customerMobile,
        applicationId: applicationId,
        handoverBy: handoverBy,
        handoverDate: handoverDate,
        createdAt: DateTime.now(),
      );

      await InventoryService.createAllotment(allotment);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> allotMultipleItems({
    required List<String> itemIds,
    required InventoryItemType itemType,
    required String customerName,
    String? customerAddress,
    String? customerMobile,
    String? applicationId,
    String? handoverBy,
    required DateTime handoverDate,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final allotments =
          itemIds
              .map(
                (id) => InventoryAllotment(
                  id: '',
                  itemId: id,
                  itemType: itemType,
                  customerName: customerName,
                  customerAddress: customerAddress,
                  customerMobile: customerMobile,
                  applicationId: applicationId,
                  handoverBy: handoverBy,
                  handoverDate: handoverDate,
                  createdAt: DateTime.now(),
                ),
              )
              .toList();

      await InventoryService.createMultipleAllotments(allotments);
      await loadAll();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  () => InventoryNotifier(),
);
final inventoryInvoicesProvider =
    FutureProvider.family<List<InventoryInvoice>, InventoryItemType>((
      ref,
      type,
    ) async {
      return await InventoryService.fetchInvoices(type);
    });
