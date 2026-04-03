import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/inventory_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/inventory_providers.dart';

class MeterDetailsDialog extends ConsumerStatefulWidget {
  final String brandName;
  final List<MeterItem> meters;

  const MeterDetailsDialog({
    super.key,
    required this.brandName,
    required this.meters,
  });

  @override
  ConsumerState<MeterDetailsDialog> createState() => _MeterDetailsDialogState();
}

class _MeterDetailsDialogState extends ConsumerState<MeterDetailsDialog> {
  String _searchSerial = '';
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedPhase;
  String? _selectedStatus;

  String _normalizeBrand(String brand) => brand.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final inventoryState = ref.watch(inventoryProvider);
    final canAllotInventory = currentUser?.canAllotInventory ?? false;
    final canEditInventory = currentUser?.canEdit ?? false;
    final currentMeters =
        inventoryState.meters
            .where(
              (m) => _normalizeBrand(m.brand) == _normalizeBrand(widget.brandName),
            )
            .toList();

    final filteredMeters =
        currentMeters.where((m) {
            final matchesSearch =
                _searchSerial.isEmpty ||
                m.serialNumber.toLowerCase().contains(
                  _searchSerial.toLowerCase(),
                );
            final matchesCategory =
                _selectedCategory == null || m.meterCategory == _selectedCategory;
            final matchesType =
                _selectedType == null || m.meterType == _selectedType;
            final matchesPhase =
                _selectedPhase == null || m.meterPhase == _selectedPhase;
            final matchesStatus =
                _selectedStatus == null || m.status == _selectedStatus;
            return matchesSearch &&
                matchesCategory &&
                matchesType &&
                matchesPhase &&
                matchesStatus;
          }).toList()
          ..sort((a, b) => a.serialNumber.compareTo(b.serialNumber));

    final totalAvailable =
        currentMeters.where((m) => m.status == 'available').length;
    final totalAllotted =
        currentMeters.where((m) => m.status == 'allotted').length;
    final categories =
        currentMeters.map((m) => m.meterCategory).toSet().toList()..sort();
    final types = currentMeters.map((m) => m.meterType).toSet().toList()..sort();
    final phases =
        currentMeters.map((m) => m.meterPhase).toSet().toList()..sort();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 1080,
            height: 680,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.78),
                  const Color(0xFFFFF6EA).withOpacity(0.72),
                  const Color(0xFFFDFBFF).withOpacity(0.7),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A1F3B73),
                  blurRadius: 28,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.38),
                    border: Border.all(color: Colors.white.withOpacity(0.45)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                          ),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.brandName} Meter Inventory',
                              style: AppTextStyles.heading3.copyWith(
                                color: const Color(0xFF172033),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${filteredMeters.length} matching serials across this brand',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildTotalBadge(
                                  'Available Balance',
                                  totalAvailable,
                                  const Color(0xFF16A34A),
                                ),
                                _buildTotalBadge(
                                  'Allotted',
                                  totalAllotted,
                                  const Color(0xFFF59E0B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white.withOpacity(0.32),
                    border: Border.all(color: Colors.white.withOpacity(0.42)),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by serial number',
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                          onChanged: (v) => setState(() => _searchSerial = v),
                        ),
                      ),
                      _buildFilterDropdown(
                        hint: 'Category',
                        value: _selectedCategory,
                        items: categories,
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                      _buildFilterDropdown(
                        hint: 'Type',
                        value: _selectedType,
                        items: types,
                        onChanged: (v) => setState(() => _selectedType = v),
                      ),
                      _buildFilterDropdown(
                        hint: 'Phase',
                        value: _selectedPhase,
                        items: phases,
                        onChanged: (v) => setState(() => _selectedPhase = v),
                      ),
                      _buildFilterDropdown(
                        hint: 'Status',
                        value: _selectedStatus,
                        items: const ['available', 'allotted'],
                        onChanged: (v) => setState(() => _selectedStatus = v),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: IconButton(
                          onPressed: () => setState(() {
                            _searchSerial = '';
                            _selectedCategory = null;
                            _selectedType = null;
                            _selectedPhase = null;
                            _selectedStatus = null;
                          }),
                          icon: const Icon(Icons.refresh_rounded),
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: Colors.white.withOpacity(0.44),
                      border: Border.all(color: Colors.white.withOpacity(0.48)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: DataTable(
                          headingRowHeight: 56,
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 72,
                          horizontalMargin: 18,
                          columnSpacing: 24,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFFFF1D9).withOpacity(0.95),
                          ),
                          columns: const [
                            DataColumn(label: Text('Serial No.', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Phase', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Purchase From', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Invoice / Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredMeters.map((meter) {
                            final invoice = inventoryState.invoices
                                .cast<InventoryInvoice?>()
                                .firstWhere(
                                  (inv) => inv?.id == meter.invoiceId,
                                  orElse: () => null,
                                );

                            return DataRow(
                              cells: [
                                DataCell(Text(meter.serialNumber, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                                DataCell(Text(meter.meterCategory)),
                                DataCell(Text(_displayMeterType(meter.meterType))),
                                DataCell(Text(meter.meterPhase)),
                                DataCell(_StatusBadge(status: meter.status)),
                                DataCell(Text(invoice?.partyName ?? 'N/A')),
                                DataCell(
                                  invoice != null
                                      ? Text(
                                        '${invoice.invoiceNumber}\n${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                                        style: const TextStyle(fontSize: 10, height: 1.4),
                                      )
                                      : const Text('-'),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (meter.status == 'available' && canAllotInventory)
                                        TextButton.icon(
                                          onPressed: () => _showAllotmentDialog(
                                            context,
                                            meter.id,
                                            InventoryItemType.meter,
                                          ),
                                          icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                                          label: const Text('Allot'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      if (canEditInventory)
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, size: 18),
                                          onPressed: () => _showEditMeterDialog(meter),
                                        ),
                                      if (canEditInventory)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: AppTheme.errorColor,
                                          ),
                                          onPressed: () => _confirmDeleteMeter(meter),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayMeterType(String value) {
    if (value == 'LTCT') return 'LT CT';
    if (value == 'HTCT') return 'HT CT';
    return value;
  }

  Future<void> _showEditMeterDialog(MeterItem meter) async {
    final inventoryState = ref.read(inventoryProvider);
    final linkedInvoice =
        meter.invoiceId == null
            ? null
            : inventoryState.invoices
                .cast<InventoryInvoice?>()
                .firstWhere(
                  (invoice) => invoice?.id == meter.invoiceId,
                  orElse: () => null,
                );
    final brandController = TextEditingController(text: meter.brand);
    final partyController = TextEditingController(text: linkedInvoice?.partyName ?? '');
    final invoiceNumberController = TextEditingController(
      text: linkedInvoice?.invoiceNumber ?? '',
    );
    final receivedByController = TextEditingController(
      text: linkedInvoice?.receivedBy ?? '',
    );
    final priceController = TextEditingController(
      text: linkedInvoice?.price?.toString() ?? '',
    );
    String selectedCategory = meter.meterCategory;
    String selectedType = _displayMeterType(meter.meterType);
    String selectedPhase = meter.meterPhase;
    String selectedStatus = meter.status;
    DateTime selectedInvoiceDate = linkedInvoice?.invoiceDate ?? DateTime.now();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFFFBF5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Edit Meter'),
            content: StatefulBuilder(
              builder: (context, setDialogState) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: brandController,
                      decoration: const InputDecoration(labelText: 'Brand'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const ['Net Meter', 'Solar Meter']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged:
                          (value) => selectedCategory = value ?? selectedCategory,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const ['Normal', 'LT CT', 'HT CT']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => selectedType = value ?? selectedType,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPhase,
                      decoration: const InputDecoration(labelText: 'Phase'),
                      items: const ['Single Phase', 'Three Phase']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => selectedPhase = value ?? selectedPhase,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const ['available', 'allotted']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => selectedStatus = value ?? selectedStatus,
                    ),
                    if (linkedInvoice != null) ...[
                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Purchase Details',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: partyController,
                        decoration: const InputDecoration(labelText: 'Party Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(labelText: 'Invoice Number'),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedInvoiceDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedInvoiceDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Invoice Date'),
                          child: Text(
                            '${selectedInvoiceDate.day}/${selectedInvoiceDate.month}/${selectedInvoiceDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: receivedByController,
                        decoration: const InputDecoration(labelText: 'Received By'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Purchase details update all inventory items linked to this invoice.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (shouldSave != true) return;
    final updated = meter.copyWith(
      brand: brandController.text.trim(),
      meterCategory: selectedCategory,
      meterType:
          selectedType == 'LT CT'
              ? 'LTCT'
              : selectedType == 'HT CT'
                  ? 'HTCT'
                  : selectedType,
      meterPhase: selectedPhase,
      status: selectedStatus,
    );
    if (linkedInvoice != null) {
      await ref.read(inventoryProvider.notifier).updateInvoice(
        linkedInvoice.copyWith(
          partyName: partyController.text.trim(),
          invoiceNumber: invoiceNumberController.text.trim(),
          invoiceDate: selectedInvoiceDate,
          receivedBy: receivedByController.text.trim(),
          clearReceivedBy: receivedByController.text.trim().isEmpty,
          price: double.tryParse(priceController.text.trim()),
          clearPrice: priceController.text.trim().isEmpty,
        ),
      );
    }
    await ref.read(inventoryProvider.notifier).updateMeter(updated);
  }

  Future<void> _confirmDeleteMeter(MeterItem meter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFFFAFA),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Delete Meter'),
            content: Text('Delete meter ${meter.serialNumber}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await ref.read(inventoryProvider.notifier).deleteMeter(meter.id);
    }
  }

  Widget _buildTotalBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
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
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          items:
              items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showAllotmentDialog(
    BuildContext context,
    String itemId,
    InventoryItemType type,
  ) {
    showDialog(
      context: context,
      builder: (context) => _AllotmentDialog(itemId: itemId, itemType: type),
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
        color:
            isAvailable
                ? Colors.green.withOpacity(0.12)
                : Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
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
      backgroundColor: const Color(0xFFFFFBF5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  decoration: const InputDecoration(labelText: 'Handover By'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Handover Date'),
                  subtitle: Text(
                    '${_handoverDate.day}/${_handoverDate.month}/${_handoverDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _handoverDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _handoverDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Allot'),
        ),
      ],
    );
  }
}
