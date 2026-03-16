import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/inventory_model.dart';
import '../../../providers/inventory_providers.dart';

class BrandDetailsDialog extends ConsumerStatefulWidget {
  final String brandName;
  final List<PanelItem> panels;

  const BrandDetailsDialog({
    super.key,
    required this.brandName,
    required this.panels,
  });

  @override
  ConsumerState<BrandDetailsDialog> createState() => _BrandDetailsDialogState();
}

class _BrandDetailsDialogState extends ConsumerState<BrandDetailsDialog> {
  String _searchSerial = '';
  String? _selectedWatt;
  String? _selectedType; // DCR, NDCR
  String? _selectedStatus; // available, allotted

  @override
  Widget build(BuildContext context) {
    final filteredPanels = widget.panels.where((p) {
      final matchesSerial = p.serialNumber.toLowerCase().contains(_searchSerial.toLowerCase());
      final matchesWatt = _selectedWatt == null || p.wattCapacity.toString() == _selectedWatt;
      final matchesType = _selectedType == null || p.panelType == _selectedType;
      final matchesStatus = _selectedStatus == null || p.status == _selectedStatus;
      return matchesSerial && matchesWatt && matchesType && matchesStatus;
    }).toList()
      ..sort((a, b) {
        // Sort by type then watt
        int c = a.panelType.compareTo(b.panelType);
        if (c != 0) return c;
        return a.wattCapacity.compareTo(b.wattCapacity);
      });

    final totalAvailable = widget.panels.where((p) => p.status == 'available').length;
    final totalAllotted = widget.panels.where((p) => p.status == 'allotted').length;

    final watts = widget.panels.map((p) => p.wattCapacity.toString()).toSet().toList()..sort();
    final types = widget.panels.map((p) => p.panelType).toSet().toList()..sort();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.brandName} - Panel Inventory', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildTotalBadge('Available (Balance)', totalAvailable, Colors.green),
                  const SizedBox(width: 12),
                  _buildTotalBadge('Allotted', totalAllotted, Colors.orange),
                ],
              ),
            ],
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
      content: SizedBox(
        width: 1000,
        height: 600,
        child: Column(
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Serial No.',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _searchSerial = v),
                  ),
                ),
                const SizedBox(width: 16),
                _buildFilterDropdown(
                  hint: 'Watt',
                  value: _selectedWatt,
                  items: watts,
                  onChanged: (v) => setState(() => _selectedWatt = v),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  hint: 'Type (DCR/NDCR)',
                  value: _selectedType,
                  items: types,
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  hint: 'Status',
                  value: _selectedStatus,
                  items: const ['available', 'allotted'],
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() {
                    _searchSerial = '';
                    _selectedWatt = null;
                    _selectedType = null;
                    _selectedStatus = null;
                  }),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Clear Filters',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.backgroundColor),
                      columns: const [
                        DataColumn(label: Text('Serial No.', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Wattage', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Purchase From', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Invoice / Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredPanels.map((p) {
                        final inventoryState = ref.watch(inventoryProvider);
                        final invoice = inventoryState.invoices.cast<InventoryInvoice?>().firstWhere((inv) => inv?.id == p.invoiceId, orElse: () => null);
                        
                        return DataRow(cells: [
                          DataCell(Text(p.serialNumber, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text('${p.wattCapacity}W')),
                          DataCell(Text(p.panelType)),
                          DataCell(_StatusBadge(status: p.status)),
                          DataCell(Text(invoice?.partyName ?? 'N/A')),
                          DataCell(
                            invoice != null 
                              ? Text('${invoice.invoiceNumber}\n${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}', style: const TextStyle(fontSize: 10))
                              : const Text('-')
                          ),
                          DataCell(
                            p.status == 'available'
                                ? TextButton.icon(
                                    onPressed: () => _showAllotmentDialog(context, p.id, InventoryItemType.panel),
                                    icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                                    label: const Text('Allot'),
                                  )
                                : const Text('-'),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllotmentDialog(BuildContext context, String itemId, InventoryItemType type) {
    // We need to access the parent's _showAllotmentDialog or redefine it.
    // For now, I'll assume the parent can call it or I'll implement a callback.
    // Since I'm in a separate file, I'll need to define it or pass it.
    // However, I can just use the one from inventory_screen if I make it public or export it.
    // To keep it simple, I'll show the dialog here as well if needed.
    showDialog(
      context: context,
      builder: (context) => _AllotmentDialog(itemId: itemId, itemType: type),
    );
  }

  Widget _buildTotalBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(count.toString(), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

// I need the AllotmentDialog here too if I want to allow allotment from the popup.
// I'll copy the _AllotmentDialog implementation here as well for now, or move it to a common file.
// Moving to a common file is better later, but for now copying is faster to fulfill the request.

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
