import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/application_model.dart';
import '../../../models/inventory_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/inventory_providers.dart';

class InverterDetailsDialog extends ConsumerStatefulWidget {
  final String brandName;
  final List<InverterItem> inverters;

  const InverterDetailsDialog({
    super.key,
    required this.brandName,
    required this.inverters,
  });

  @override
  ConsumerState<InverterDetailsDialog> createState() =>
      _InverterDetailsDialogState();
}

class _InverterDetailsDialogState extends ConsumerState<InverterDetailsDialog> {
  String _searchSerial = '';
  bool _filtersExpanded = false;
  String? _selectedCapacity;
  String? _selectedType; // On Grid, Hybrid, Off Grid
  String? _selectedPhase; // Single Phase, Three Phase
  String? _selectedStatus; // available, allotted

  String _normalizeBrand(String brand) => brand.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 720;
    final currentUser = ref.watch(currentUserProvider).value;
    final inventoryState = ref.watch(inventoryProvider);
    final canAllotInventory = currentUser?.canAllotInventory ?? false;
    final canEditInventory = currentUser?.canEdit ?? false;
    final currentInverters =
        inventoryState.inverters
            .where(
              (i) =>
                  _normalizeBrand(i.brand) == _normalizeBrand(widget.brandName),
            )
            .toList();
    final filteredInverters =
        currentInverters.where((i) {
            final matchesSerial = i.serialNumber.toLowerCase().contains(
              _searchSerial.toLowerCase(),
            );
            final matchesCapacity =
                _selectedCapacity == null ||
                i.capacityKw.toString() == _selectedCapacity;
            final matchesType =
                _selectedType == null || i.inverterType == _selectedType;
            final matchesPhase =
                _selectedPhase == null || i.inverterPhase == _selectedPhase;
            final matchesStatus =
                _selectedStatus == null || i.status == _selectedStatus;
            return matchesSerial &&
                matchesCapacity &&
                matchesType &&
                matchesPhase &&
                matchesStatus;
          }).toList()
          ..sort((a, b) {
            int c = a.inverterType.compareTo(b.inverterType);
            if (c != 0) return c;
            return a.capacityKw.compareTo(b.capacityKw);
          });

    final inverterAllotmentsByItemId = <String, InventoryAllotment>{};
    for (final allotment in inventoryState.allotments.where(
      (a) => a.itemType == InventoryItemType.inverter,
    )) {
      final existing = inverterAllotmentsByItemId[allotment.itemId];
      if (existing == null ||
          allotment.handoverDate.isAfter(existing.handoverDate)) {
        inverterAllotmentsByItemId[allotment.itemId] = allotment;
      }
    }

    final totalAvailable =
        currentInverters.where((i) => i.status == 'available').length;
    final totalAllotted =
        currentInverters.where((i) => i.status == 'allotted').length;

    final capacities =
        currentInverters.map((i) => i.capacityKw.toString()).toSet().toList()
          ..sort();
    final types =
        currentInverters.map((i) => i.inverterType).toSet().toList()..sort();
    final phases =
        currentInverters.map((i) => i.inverterPhase).toSet().toList()..sort();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 1080,
            height: isCompact ? MediaQuery.of(context).size.height * 0.82 : 680,
            padding: EdgeInsets.all(isCompact ? 18 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.78),
                  const Color(0xFFEEF8F7).withOpacity(0.72),
                  const Color(0xFFF8FBFF).withOpacity(0.7),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
                width: 1.2,
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
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
                            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3314B8A6),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.electrical_services_rounded,
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
                              '${widget.brandName} Inverter Inventory',
                              style: AppTextStyles.heading3.copyWith(
                                color: const Color(0xFF172033),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${filteredInverters.length} matching serials across this brand',
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
                  child:
                      isCompact
                          ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search by serial number',
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(
                                          0.7,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.35,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0F766E),
                                          ),
                                        ),
                                      ),
                                      onChanged:
                                          (v) =>
                                              setState(() => _searchSerial = v),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _filtersExpanded =
                                                    !_filtersExpanded,
                                          ),
                                      icon: Icon(
                                        _filtersExpanded
                                            ? Icons.filter_alt_off_rounded
                                            : Icons.filter_alt_rounded,
                                      ),
                                      color: const Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 180),
                                crossFadeState:
                                    _filtersExpanded
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                firstChild: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Column(
                                    children: [
                                      _buildFilterDropdown(
                                        hint: 'Capacity (kW)',
                                        value: _selectedCapacity,
                                        items: capacities,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedCapacity = v,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildFilterDropdown(
                                        hint: 'Type',
                                        value: _selectedType,
                                        items: types,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedType = v,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildFilterDropdown(
                                        hint: 'Phase',
                                        value: _selectedPhase,
                                        items: phases,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedPhase = v,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildFilterDropdown(
                                        hint: 'Status',
                                        value: _selectedStatus,
                                        items: const ['available', 'allotted'],
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedStatus = v,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.75,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed:
                                                () => setState(() {
                                                  _searchSerial = '';
                                                  _selectedCapacity = null;
                                                  _selectedType = null;
                                                  _selectedPhase = null;
                                                  _selectedStatus = null;
                                                  _filtersExpanded = false;
                                                }),
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                            ),
                                            color: const Color(0xFF0F766E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondChild: const SizedBox.shrink(),
                              ),
                            ],
                          )
                          : Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 380,
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search by serial number',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
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
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                  onChanged:
                                      (v) => setState(() => _searchSerial = v),
                                ),
                              ),
                              _buildFilterDropdown(
                                hint: 'Capacity (kW)',
                                value: _selectedCapacity,
                                items: capacities,
                                onChanged:
                                    (v) =>
                                        setState(() => _selectedCapacity = v),
                              ),
                              _buildFilterDropdown(
                                hint: 'Type',
                                value: _selectedType,
                                items: types,
                                onChanged:
                                    (v) => setState(() => _selectedType = v),
                              ),
                              _buildFilterDropdown(
                                hint: 'Phase',
                                value: _selectedPhase,
                                items: phases,
                                onChanged:
                                    (v) => setState(() => _selectedPhase = v),
                              ),
                              _buildFilterDropdown(
                                hint: 'Status',
                                value: _selectedStatus,
                                items: const ['available', 'allotted'],
                                onChanged:
                                    (v) => setState(() => _selectedStatus = v),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed:
                                      () => setState(() {
                                        _searchSerial = '';
                                        _selectedCapacity = null;
                                        _selectedType = null;
                                        _selectedPhase = null;
                                        _selectedStatus = null;
                                      }),
                                  icon: const Icon(Icons.refresh_rounded),
                                  color: const Color(0xFF0F766E),
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
                      child:
                          isCompact
                              ? ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredInverters.length,
                                itemBuilder: (context, index) {
                                  final i = filteredInverters[index];
                                  final invoice = inventoryState.invoices
                                      .cast<InventoryInvoice?>()
                                      .firstWhere(
                                        (inv) => inv?.id == i.invoiceId,
                                        orElse: () => null,
                                      );
                                  final allotment =
                                      inverterAllotmentsByItemId[i.id];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.78),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          i.serialNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildMetaRow(
                                          'Capacity',
                                          '${i.capacityKw}kW',
                                        ),
                                        _buildMetaRow('Type', i.inverterType),
                                        _buildMetaRow('Phase', i.inverterPhase),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: 68,
                                              child: Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _StatusBadge(status: i.status),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        _buildMetaRow(
                                          'Purchase',
                                          invoice?.partyName ?? 'N/A',
                                        ),
                                        _buildMetaRow(
                                          'Invoice',
                                          invoice != null
                                              ? '${invoice.invoiceNumber} • ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}'
                                              : '-',
                                        ),
                                        if (allotment != null)
                                          _buildMetaRow(
                                            'Allotted To',
                                            '${allotment.customerName} (${_formatApplicationRef(allotment.applicationId)})',
                                          ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (i.status == 'available' &&
                                                canAllotInventory)
                                              TextButton.icon(
                                                onPressed:
                                                    () => _showAllotmentDialog(
                                                      context,
                                                      i.id,
                                                      InventoryItemType
                                                          .inverter,
                                                    ),
                                                icon: const Icon(
                                                  Icons.assignment_ind_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text('Allot'),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFF0F766E,
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFEAF7F5,
                                                  ),
                                                ),
                                              ),
                                            if (canEditInventory)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                  size: 18,
                                                ),
                                                onPressed:
                                                    () =>
                                                        _showEditInverterDialog(
                                                          i,
                                                        ),
                                              ),
                                            if (canEditInventory)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: AppTheme.errorColor,
                                                ),
                                                onPressed:
                                                    () =>
                                                        _confirmDeleteInverter(
                                                          i,
                                                        ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                              : SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: DataTable(
                                  headingRowHeight: 56,
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 96,
                                  horizontalMargin: 18,
                                  columnSpacing: 28,
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFEAF7F5).withOpacity(0.95),
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Serial No.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Capacity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Type',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Phase',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Allotted To / App',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Purchase From',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Invoice / Date',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows:
                                      filteredInverters.map((i) {
                                        final invoice = inventoryState.invoices
                                            .cast<InventoryInvoice?>()
                                            .firstWhere(
                                              (inv) => inv?.id == i.invoiceId,
                                              orElse: () => null,
                                            );
                                        final allotment =
                                            inverterAllotmentsByItemId[i.id];
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                i.serialNumber,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text('${i.capacityKw}kW')),
                                            DataCell(Text(i.inverterType)),
                                            DataCell(Text(i.inverterPhase)),
                                            DataCell(
                                              _StatusBadge(status: i.status),
                                            ),
                                            DataCell(
                                              _buildAllotmentSummaryCell(
                                                allotment,
                                              ),
                                            ),
                                            DataCell(
                                              Text(invoice?.partyName ?? 'N/A'),
                                            ),
                                            DataCell(
                                              invoice != null
                                                  ? Text(
                                                    '${invoice.invoiceNumber}\n${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      height: 1.4,
                                                    ),
                                                  )
                                                  : const Text('-'),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (i.status == 'available' &&
                                                      canAllotInventory)
                                                    TextButton.icon(
                                                      onPressed:
                                                          () =>
                                                              _showAllotmentDialog(
                                                                context,
                                                                i.id,
                                                                InventoryItemType
                                                                    .inverter,
                                                              ),
                                                      icon: const Icon(
                                                        Icons
                                                            .assignment_ind_rounded,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'Allot',
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                const Color(
                                                                  0xFF0F766E,
                                                                ),
                                                          ),
                                                    ),
                                                  if (canEditInventory)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit_rounded,
                                                        size: 18,
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              _showEditInverterDialog(
                                                                i,
                                                              ),
                                                    ),
                                                  if (canEditInventory)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 18,
                                                        color:
                                                            AppTheme.errorColor,
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              _confirmDeleteInverter(
                                                                i,
                                                              ),
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

  String _formatApplicationRef(String? applicationId) {
    if (applicationId == null || applicationId.trim().isEmpty) return 'Manual';
    final trimmed = applicationId.trim();
    final short = trimmed.length > 8 ? trimmed.substring(0, 8) : trimmed;
    return 'APP-$short';
  }

  Widget _buildAllotmentSummaryCell(InventoryAllotment? allotment) {
    if (allotment == null)
      return const Text('-', style: TextStyle(color: AppTheme.textSecondary));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          allotment.customerName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          _formatApplicationRef(allotment.applicationId),
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
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

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditInverterDialog(InverterItem inverter) async {
    final inventoryState = ref.read(inventoryProvider);
    final linkedInvoice =
        inverter.invoiceId == null
            ? null
            : inventoryState.invoices.cast<InventoryInvoice?>().firstWhere(
              (invoice) => invoice?.id == inverter.invoiceId,
              orElse: () => null,
            );
    final brandController = TextEditingController(text: inverter.brand);
    final capacityController = TextEditingController(
      text: inverter.capacityKw.toString(),
    );
    final partyController = TextEditingController(
      text: linkedInvoice?.partyName ?? '',
    );
    final invoiceNumberController = TextEditingController(
      text: linkedInvoice?.invoiceNumber ?? '',
    );
    final receivedByController = TextEditingController(
      text: linkedInvoice?.receivedBy ?? '',
    );
    final priceController = TextEditingController(
      text: linkedInvoice?.price?.toString() ?? '',
    );
    String selectedType = inverter.inverterType;
    String selectedPhase = inverter.inverterPhase;
    String selectedStatus = inverter.status;
    DateTime selectedInvoiceDate = linkedInvoice?.invoiceDate ?? DateTime.now();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFF7FCFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Edit Inverter'),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: brandController,
                          decoration: const InputDecoration(labelText: 'Brand'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: capacityController,
                          decoration: const InputDecoration(
                            labelText: 'Capacity (kW)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items:
                              const ['On Grid', 'Hybrid', 'Off Grid']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => selectedType = value ?? selectedType,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedPhase,
                          decoration: const InputDecoration(labelText: 'Phase'),
                          items:
                              const ['Single Phase', 'Three Phase']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => selectedPhase = value ?? selectedPhase,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items:
                              const ['available', 'allotted']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  selectedStatus = value ?? selectedStatus,
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
                            decoration: const InputDecoration(
                              labelText: 'Party Name',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: invoiceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Number',
                            ),
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
                                setDialogState(
                                  () => selectedInvoiceDate = picked,
                                );
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Invoice Date',
                              ),
                              child: Text(
                                '${selectedInvoiceDate.day}/${selectedInvoiceDate.month}/${selectedInvoiceDate.year}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: receivedByController,
                            decoration: const InputDecoration(
                              labelText: 'Received By',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                            ),
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
    final updated = inverter.copyWith(
      brand: brandController.text.trim(),
      capacityKw:
          double.tryParse(capacityController.text.trim()) ??
          inverter.capacityKw,
      inverterType: selectedType,
      inverterPhase: selectedPhase,
      status: selectedStatus,
    );
    if (linkedInvoice != null) {
      await ref
          .read(inventoryProvider.notifier)
          .updateInvoice(
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
    await ref.read(inventoryProvider.notifier).updateInverter(updated);
  }

  Future<void> _confirmDeleteInverter(InverterItem inverter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFFFFFAFA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Delete Inverter'),
            content: Text('Delete inverter ${inverter.serialNumber}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await ref.read(inventoryProvider.notifier).deleteInverter(inverter.id);
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
        border: Border.all(
          color:
              isAvailable
                  ? Colors.green.withOpacity(0.12)
                  : Colors.orange.withOpacity(0.12),
        ),
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
  String? _selectedApplicationId;
  DateTime _handoverDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref
              .read(applicationsProvider.notifier)
              .loadApplications(showLoading: false),
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _handoverByController.dispose();
    super.dispose();
  }

  void _applyApplicationDetails(ApplicationModel? application) {
    if (application == null) return;
    _customerController.text = application.fullName;
    _addressController.text = application.address;
    _mobileController.text = application.mobile;
  }

  Future<void> _showBlockingLoader() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Allotting inventory...',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Please wait, do not close the app.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideBlockingLoader() {
    if (!mounted) return;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    _showBlockingLoader();

    try {
      await ref
          .read(inventoryProvider.notifier)
          .allotItem(
            itemId: widget.itemId,
            itemType: widget.itemType,
            customerName: _customerController.text,
            customerAddress: _addressController.text,
            customerMobile: _mobileController.text,
            applicationId: _selectedApplicationId,
            handoverBy: _handoverByController.text,
            handoverDate: _handoverDate,
          );
      _hideBlockingLoader();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _hideBlockingLoader();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationsState = ref.watch(applicationsProvider);
    final applications =
        [...applicationsState.applications]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AlertDialog(
      backgroundColor: const Color(0xFFF7FCFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'New Allotment / Handover',
        style: AppTextStyles.heading3,
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedApplicationId,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name (From Application)',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Manual Entry'),
                    ),
                    ...applications.map(
                      (app) => DropdownMenuItem<String>(
                        value: app.id,
                        child: Text('${app.fullName} (${app.applicationNumber})'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedApplicationId = value);
                    if (value == null) return;
                    ApplicationModel? selected;
                    for (final app in applications) {
                      if (app.id == value) {
                        selected = app;
                        break;
                      }
                    }
                    _applyApplicationDetails(selected);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerController,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
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
                  decoration: const InputDecoration(
                    labelText: 'Handover By (Staff)',
                  ),
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
                    decoration: const InputDecoration(
                      labelText: 'Handover Date',
                    ),
                    child: Text(
                      '${_handoverDate.day}/${_handoverDate.month}/${_handoverDate.year}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Confirm Handover'),
        ),
      ],
    );
  }
}
