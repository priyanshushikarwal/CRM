import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_providers.dart';
import '../../providers/app_providers.dart';
import 'widgets/brand_details_dialog.dart';
import 'widgets/inverter_details_dialog.dart';


class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Factory Inventory', style: AppTextStyles.heading2),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Solar Panels'),
            Tab(text: 'Inverters'),
            Tab(text: 'Meters'),
          ],
        ),
      ),
      body: inventoryState.isLoading && inventoryState.panels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : inventoryState.error != null
              ? _buildErrorState(inventoryState.error!, ref)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboard(inventoryState),
                    _buildPanelInventory(inventoryState),
                    _buildInverterInventory(inventoryState),
                    _buildMeterInventory(inventoryState),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInventoryDialog(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Stock', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 16),
          Text('Error Loading Inventory', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(inventoryProvider.notifier).loadAll(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(InventoryState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Overview', style: AppTextStyles.heading3),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('Total Panels', state.panels.length.toString(), Icons.solar_power_rounded, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Total Inverters', state.inverters.length.toString(), Icons.settings_input_component_rounded, Colors.teal),
              const SizedBox(width: 16),
              _buildStatCard('Total Meters', state.meters.length.toString(), Icons.speed_rounded, Colors.orange),
            ],
          ),
          const SizedBox(height: 32),
          Text('Solar Panel Stock', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          _buildBrandSummary(state),
          const SizedBox(height: 32),
          Text('Recent Allotments', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          _buildRecentAllotmentsTable(state),
        ],
      ),
    );
  }

  Widget _buildBrandSummary(InventoryState state) {
    final Map<String, List<PanelItem>> groupedByBrand = {};
    for (var p in state.panels) {
      groupedByBrand.putIfAbsent(p.brand, () => []);
      groupedByBrand[p.brand]!.add(p);
    }

    if (groupedByBrand.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(child: Text('No panels in stock.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: groupedByBrand.entries.map((brandEntry) {
        final brand = brandEntry.key;
        final panels = brandEntry.value;
        
        // Group by type and watt
        final Map<String, int> typeWattCounts = {};
        for (var p in panels) {
          if (p.status == 'available') {
            final key = '${p.panelType} (${p.wattCapacity} Watt)';
            typeWattCounts[key] = (typeWattCounts[key] ?? 0) + 1;
          }
        }

        return InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => BrandDetailsDialog(brandName: brand, panels: panels),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(brand.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textLight),
                  ],
                ),
                const Divider(height: 32),
                ...typeWattCounts.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      const Text(' = ', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                      const SizedBox(width: 4),
                      const Text('Panels', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                )).toList(),
                if (typeWattCounts.isNotEmpty) ...[
                  const Divider(height: 16),
                  const Center(
                    child: Text('IN STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 1.2)),
                  ),
                ] else
                  const Text('No available stock', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 12)),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Click to view details', style: TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 10, color: AppTheme.textLight),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(value, style: AppTextStyles.heading1.copyWith(color: color)),
            Text(title, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAllotmentsTable(InventoryState state) {
    if (state.allotments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(child: Text('No allotments found.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.backgroundColor),
          columns: const [
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Ref')),
            DataColumn(label: Text('Item Type')),
            DataColumn(label: Text('Serial No.')),
            DataColumn(label: Text('Date')),
          ],
          rows: state.allotments.take(10).map((allotment) {
            String serial = 'N/A';
            try {
              if (allotment.itemType == InventoryItemType.panel) {
                serial = state.panels.firstWhere((p) => p.id == allotment.itemId).serialNumber;
              } else if (allotment.itemType == InventoryItemType.inverter) {
                serial = state.inverters.firstWhere((i) => i.id == allotment.itemId).serialNumber;
              } else {
                serial = state.meters.firstWhere((m) => m.id == allotment.itemId).serialNumber;
              }
            } catch (_) {}

            return DataRow(cells: [
              DataCell(Text(allotment.customerName, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(allotment.applicationId != null ? 'APP-${allotment.applicationId!.length > 5 ? allotment.applicationId!.substring(0, 5) : allotment.applicationId}...' : 'Manual')),
              DataCell(Text(allotment.itemType.name.toUpperCase())),
              DataCell(Text(serial)),
              DataCell(Text('${allotment.handoverDate.day}/${allotment.handoverDate.month}/${allotment.handoverDate.year}')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPanelInventory(InventoryState state) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STOCK SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                _buildBrandSummary(state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInverterInventory(InventoryState state) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('STOCK SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                _buildInverterSummary(state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInverterSummary(InventoryState state) {
    final Map<String, List<InverterItem>> groupedByBrand = {};
    for (var i in state.inverters) {
      groupedByBrand.putIfAbsent(i.brand, () => []);
      groupedByBrand[i.brand]!.add(i);
    }

    if (groupedByBrand.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(child: Text('No inverters in stock.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: groupedByBrand.entries.map((brandEntry) {
        final brand = brandEntry.key;
        final inverters = brandEntry.value;
        
        final Map<String, int> typeCapCounts = {};
        for (var i in inverters) {
          if (i.status == 'available') {
            final key = '${i.inverterType} (${i.capacityKw} kW)';
            typeCapCounts[key] = (typeCapCounts[key] ?? 0) + 1;
          }
        }

        return InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => InverterDetailsDialog(brandName: brand, inverters: inverters),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(brand.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textLight),
                  ],
                ),
                const Divider(height: 32),
                ...typeCapCounts.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      const Text(' = ', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14)),
                      const SizedBox(width: 4),
                      const Text('Units', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                )).toList(),
                if (typeCapCounts.isNotEmpty) ...[
                  const Divider(height: 16),
                  const Center(
                    child: Text('STOCK AVAILABLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1.2)),
                  ),
                ] else
                  const Text('No available stock', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 12)),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Click for Details', style: TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 10, color: AppTheme.textLight),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMeterInventory(InventoryState state) {
    var meters = state.meters.where((p) => 
      p.serialNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      p.brand.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
    
    if (meters.isEmpty && !state.isLoading) {
      return _buildEmptyCategory('No Meters Found');
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: meters.length,
            itemBuilder: (context, index) {
              final meter = meters[index];
              final invoice = state.invoices.cast<InventoryInvoice?>().firstWhere((inv) => inv?.id == meter.invoiceId, orElse: () => null);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meter.serialNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('${meter.brand} - ${meter.meterCategory} (${meter.meterPhase})', 
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _StatusBadge(status: meter.status),
                              if (meter.status == 'available')
                                IconButton(
                                  icon: const Icon(Icons.assignment_ind_rounded, color: AppTheme.primaryColor),
                                  onPressed: () => _showAllotmentDialog(context, meter.id, InventoryItemType.meter),
                                  tooltip: 'Allot to Customer',
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (invoice != null) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            _buildInfoMiniItem('Invoice No', invoice.invoiceNumber),
                            _buildInfoMiniItem('Date', '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}'),
                            _buildInfoMiniItem('Party', invoice.partyName),
                            _buildInfoMiniItem('Received By', invoice.receivedBy ?? 'N/A'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategory(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: AppTheme.textLight, size: 48),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by serial number or brand...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (v) => setState(() {}),
      ),
    );
  }

  void _showAllotmentDialog(BuildContext context, String itemId, InventoryItemType type) {
    showDialog(
      context: context,
      builder: (context) => _AllotmentDialog(itemId: itemId, itemType: type),
    );
  }

  Widget _buildInfoMiniItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showAddInventoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddInventoryDialog(),
    );
  }
}

class _AddInventoryDialog extends ConsumerStatefulWidget {
  const _AddInventoryDialog();

  @override
  ConsumerState<_AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends ConsumerState<_AddInventoryDialog> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Basic Details
  final _invoiceController = TextEditingController();
  final _partyController = TextEditingController();
  final _brandController = TextEditingController();
  final _receivedByController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  InventoryItemType _selectedType = InventoryItemType.panel;

  // Serial Entry Fields
  final _serialController = TextEditingController();
  final _capacityController = TextEditingController(text: '540');
  
  // Lists
  List<Map<String, dynamic>> _panelEntries = []; // {serial, capacity, type}
  List<String> _inverterSerials = [];
  List<String> _meterSerials = [];

  // Item Specifics
  String _inverterTypeSelection = 'On Grid';
  double _inverterCapacitySelection = 5.0;
  String _meterFullTypeSelection = 'Normal Net Meter';
  String _meterPhaseSelection = 'Single Phase';

  @override
  void initState() {
    super.initState();
    _receivedByController.text = ref.read(currentUserProvider).value?.fullName ?? '';
  }

  void _addPanelEntry(String type) {
    final sn = _serialController.text.trim();
    final cap = int.tryParse(_capacityController.text) ?? 540;
    if (sn.isNotEmpty) {
      if (_panelEntries.any((e) => e['serial'] == sn)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicate serial number in list')));
        return;
      }
      setState(() {
        _panelEntries.add({'serial': sn, 'capacity': cap, 'type': type});
        _serialController.clear();
      });
    }
  }


  Future<void> _save() async {
    final invoice = InventoryInvoice(
      id: '',
      invoiceNumber: _invoiceController.text,
      invoiceDate: _invoiceDate,
      partyName: _partyController.text,
      price: 0,
      receivedBy: _receivedByController.text.trim().isEmpty 
          ? (ref.read(currentUserProvider).value?.fullName ?? 'System')
          : _receivedByController.text.trim(),
      itemType: _selectedType,
      createdAt: DateTime.now(),
    );

    try {
      if (_selectedType == InventoryItemType.panel) {
        if (_panelEntries.isEmpty) return;
        await ref.read(inventoryProvider.notifier).addPanels(
          invoice: invoice,
          brand: _brandController.text,
          panelEntries: _panelEntries,
        );
      } else if (_selectedType == InventoryItemType.inverter) {
        if (_inverterSerials.isEmpty) return;
        await ref.read(inventoryProvider.notifier).addInverters(
          invoice: invoice,
          serialNumbers: _inverterSerials,
          brand: _brandController.text,
          capacityKw: _inverterCapacitySelection,
          inverterType: _inverterTypeSelection,
        );
      } else if (_selectedType == InventoryItemType.meter) {
        if (_meterSerials.isEmpty) return;
        await ref.read(inventoryProvider.notifier).addMeters(
          invoice: invoice,
          brand: _brandController.text,
          serialNumbers: _meterSerials,
          category: _meterFullTypeSelection.contains('Net Meter') ? 'Net Meter' : 'Solar Meter',
          type: _meterFullTypeSelection.startsWith('Normal') 
              ? 'Normal' 
              : _meterFullTypeSelection.startsWith('LT CT') 
                  ? 'LT CT' 
                  : 'HT CT',
          phase: _meterPhaseSelection,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_currentStep == 0 ? 'Add Stock - Step 1' : _currentStep == 1 ? 'Step 2: Basic Details' : 'Step 3: Item Details'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentStep == 0) _buildStep1(),
              if (_currentStep == 1) _buildStep2(),
              if (_currentStep == 2) _buildStep3(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (_currentStep > 0)
          TextButton(onPressed: () => setState(() => _currentStep--), child: const Text('Back')),
        if (_currentStep < 2)
          ElevatedButton(
            onPressed: () {
              if (_currentStep == 1 && !_formKey.currentState!.validate()) return;
              setState(() => _currentStep++);
            },
            child: const Text('Next'),
          ),
        if (_currentStep == 2)
          ElevatedButton(
            onPressed: (_selectedType == InventoryItemType.panel && _panelEntries.isEmpty) ||
                      (_selectedType == InventoryItemType.inverter && _inverterSerials.isEmpty) ||
                      (_selectedType == InventoryItemType.meter && _meterSerials.isEmpty)
                ? null 
                : _save,
            child: const Text('Save Stock'),
          ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        const Text('Select Item Type to continue:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...InventoryItemType.values.map((type) => RadioListTile<InventoryItemType>(
          title: Text(type.name.toUpperCase()),
          value: type,
          groupValue: _selectedType,
          onChanged: (v) => setState(() => _selectedType = v!),
        )),
      ],
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _invoiceController,
            decoration: const InputDecoration(labelText: 'Invoice Number'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Invoice Date'),
            subtitle: Text("${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _invoiceDate, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (d != null) setState(() => _invoiceDate = d);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _partyController,
            decoration: const InputDecoration(labelText: 'Party Name (Supplier)'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(labelText: 'Brand Name'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _receivedByController,
            decoration: const InputDecoration(labelText: 'Received By'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    if (_selectedType == InventoryItemType.panel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelEntrySection('DCR'),
          const Divider(height: 32),
          _buildPanelEntrySection('NDCR'),
        ],
      );
    }
    
    return Column(
      children: [
        if (_selectedType == InventoryItemType.inverter) ...[
          DropdownButtonFormField<String>(
            value: _inverterTypeSelection,
            items: ['On Grid', 'Hybrid', 'Off Grid'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _inverterTypeSelection = v!),
            decoration: const InputDecoration(labelText: 'Inverter Type'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: '5.0',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Capacity (kW)'),
            onChanged: (v) => _inverterCapacitySelection = double.tryParse(v) ?? 5.0,
          ),
          _buildSimpleSerialEntry(_inverterSerials),
        ],
        if (_selectedType == InventoryItemType.meter) ...[
          DropdownButtonFormField<String>(
            value: _meterFullTypeSelection,
            items: [
              'Normal Net Meter',
              'Normal Solar Meter',
              'LT CT Net Meter',
              'LT CT Solar Meter',
              'HT CT Net Meter'
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _meterFullTypeSelection = v!),
            decoration: const InputDecoration(labelText: 'Meter Type'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _meterPhaseSelection,
            items: ['Single Phase', 'Three Phase'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _meterPhaseSelection = v!),
            decoration: const InputDecoration(labelText: 'Meter Phase'),
          ),
          _buildSimpleSerialEntry(_meterSerials),
        ]
      ],
    );
  }

  Widget _buildPanelEntrySection(String type) {
    final entries = _panelEntries.where((e) => e['type'] == type).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$type PANELS', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _serialController,
                decoration: const InputDecoration(hintText: 'Serial Number', isDense: true),
                onSubmitted: (_) => _addPanelEntry(type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _capacityController,
                decoration: const InputDecoration(hintText: 'Watt', isDense: true),
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _addPanelEntry(type)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(8)),
          child: entries.isEmpty 
              ? const Center(child: Text('No entries yet', style: TextStyle(color: Colors.grey, fontSize: 12)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    title: Text(entries[i]['serial']),
                    subtitle: Text('${entries[i]['capacity']}W'),
                    trailing: IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.red), onPressed: () => setState(() => _panelEntries.remove(entries[i]))),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSimpleSerialEntry(List<String> target) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _serialController,
                decoration: const InputDecoration(hintText: 'Enter Serial Number'),
                onSubmitted: (_) {
                  final sn = _serialController.text.trim();
                  if (sn.isNotEmpty && !target.contains(sn)) {
                    setState(() => target.add(sn));
                    _serialController.clear();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add), 
              onPressed: () {
                final sn = _serialController.text.trim();
                if (sn.isNotEmpty && !target.contains(sn)) {
                  setState(() => target.add(sn));
                  _serialController.clear();
                }
              }
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: target.map((sn) => Chip(
            label: Text(sn, style: const TextStyle(fontSize: 10)),
            onDeleted: () => setState(() => target.remove(sn)),
          )).toList(),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isAvailable ? Colors.green : Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AllotmentDialog extends ConsumerStatefulWidget {
  final String itemId;
  final InventoryItemType itemType;

  const _AllotmentDialog({required this.itemId, required this.itemType});

  @override
  ConsumerState<_AllotmentDialog> createState() => _AllotmentDialogState();
}

class _AllotmentDialogState extends ConsumerState<_AllotmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _handoverByController = TextEditingController();
  DateTime _handoverDate = DateTime.now();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(inventoryProvider.notifier).allotItem(
        itemId: widget.itemId,
        itemType: widget.itemType,
        customerName: _customerController.text,
        customerAddress: _addressController.text,
        customerMobile: _mobileController.text,
        handoverBy: _handoverByController.text,
        handoverDate: _handoverDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Allotment / Handover', style: AppTextStyles.heading3),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _customerController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _handoverByController,
                  decoration: const InputDecoration(labelText: 'Handover By (Staff)'),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _handoverDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _handoverDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Handover Date'),
                    child: Text('${_handoverDate.day}/${_handoverDate.month}/${_handoverDate.year}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Confirm Handover')),
      ],
    );
  }
}
