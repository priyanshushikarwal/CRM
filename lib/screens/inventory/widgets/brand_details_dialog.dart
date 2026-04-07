import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/inventory_model.dart';
import '../../../providers/app_providers.dart';
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
  bool _filtersExpanded = false;
  String? _selectedWatt;
  String? _selectedType; // DCR, NDCR
  String? _selectedStatus; // available, allotted

  String _normalizeBrand(String brand) => brand.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 720;
    final currentUser = ref.watch(currentUserProvider).value;
    final inventoryState = ref.watch(inventoryProvider);
    final canAllotInventory = currentUser?.canAllotInventory ?? false;
    final canEditInventory = currentUser?.canEdit ?? false;
    final currentPanels =
        inventoryState.panels
            .where(
              (p) => _normalizeBrand(p.brand) == _normalizeBrand(widget.brandName),
            )
            .toList();
    final filteredPanels = currentPanels.where((p) {
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

    final totalAvailable = currentPanels.where((p) => p.status == 'available').length;
    final totalAllotted = currentPanels.where((p) => p.status == 'allotted').length;

    final watts = currentPanels.map((p) => p.wattCapacity.toString()).toSet().toList()..sort();
    final types = currentPanels.map((p) => p.panelType).toSet().toList()..sort();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 20,
        vertical: isCompact ? 12 : 28,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 1080,
            height: isCompact ? MediaQuery.of(context).size.height * 0.88 : 680,
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.78),
                  const Color(0xFFF2F7FF).withOpacity(0.72),
                  const Color(0xFFF9FBFF).withOpacity(0.7),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1A1F3B73),
                  blurRadius: 28,
                  offset: const Offset(0, 20),
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
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x334F46E5),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.solar_power_rounded,
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
                              '${widget.brandName} Panel Inventory',
                              style: AppTextStyles.heading3.copyWith(
                                color: const Color(0xFF172033),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${filteredPanels.length} matching serials across this brand',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            isCompact
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _buildMobileStatTile(
                                          count: totalAvailable,
                                          label: 'AVAILABLE',
                                          color: const Color(0xFF22C55E),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildMobileStatTile(
                                          count: totalAllotted,
                                          label: 'ALLOTTED',
                                          color: const Color(0xFFFB923C),
                                        ),
                                      ),
                                    ],
                                  )
                                : Wrap(
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
                  child: isCompact
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
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
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                    onChanged: (v) => setState(() => _searchSerial = v),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                                  ),
                                  child: IconButton(
                                    onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                                    icon: Icon(
                                      _filtersExpanded
                                          ? Icons.filter_alt_off_rounded
                                          : Icons.filter_alt_rounded,
                                    ),
                                    color: const Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 180),
                              crossFadeState: _filtersExpanded
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              firstChild: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  children: [
                                    _buildFilterDropdown(
                                      hint: 'Watt',
                                      value: _selectedWatt,
                                      items: watts,
                                      onChanged: (v) => setState(() => _selectedWatt = v),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildFilterDropdown(
                                      hint: 'Type (DCR/NDCR)',
                                      value: _selectedType,
                                      items: types,
                                      onChanged: (v) => setState(() => _selectedType = v),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildFilterDropdown(
                                      hint: 'Status',
                                      value: _selectedStatus,
                                      items: const ['available', 'allotted'],
                                      onChanged: (v) => setState(() => _selectedStatus = v),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.75),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                                        ),
                                        child: IconButton(
                                          onPressed: () => setState(() {
                                            _searchSerial = '';
                                            _selectedWatt = null;
                                            _selectedType = null;
                                            _selectedStatus = null;
                                            _filtersExpanded = false;
                                          }),
                                          icon: const Icon(Icons.refresh_rounded),
                                          tooltip: 'Clear Filters',
                                          color: const Color(0xFF4F46E5),
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
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 380,
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
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                                onChanged: (v) => setState(() => _searchSerial = v),
                              ),
                            ),
                            _buildFilterDropdown(
                              hint: 'Watt',
                              value: _selectedWatt,
                              items: watts,
                              onChanged: (v) => setState(() => _selectedWatt = v),
                            ),
                            _buildFilterDropdown(
                              hint: 'Type (DCR/NDCR)',
                              value: _selectedType,
                              items: types,
                              onChanged: (v) => setState(() => _selectedType = v),
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
                                  _selectedWatt = null;
                                  _selectedType = null;
                                  _selectedStatus = null;
                                }),
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Clear Filters',
                                color: const Color(0xFF4F46E5),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: isCompact
                          ? ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredPanels.length,
                              itemBuilder: (context, index) {
                                final p = filteredPanels[index];
                                final invoice = inventoryState.invoices.cast<InventoryInvoice?>().firstWhere((inv) => inv?.id == p.invoiceId, orElse: () => null);
                                final isAvailable = p.status == 'available';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.94),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.78)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0x14172333),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SERIAL NUMBER',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: Color(0xFF9AA6B6),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p.serialNumber,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E293B),
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _buildCompactStatusBadge(
                                            p.status.toUpperCase(),
                                            isAvailable
                                                ? const Color(0xFF4ADE80)
                                                : const Color(0xFFFB923C),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildCompactDetail(
                                              'Wattage',
                                              '${p.wattCapacity}W',
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildCompactDetail(
                                              'Type',
                                              p.panelType,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildCompactDetail(
                                              'Purchase Date',
                                              invoice != null
                                                  ? '${invoice.invoiceDate.day} ${_monthShort(invoice.invoiceDate.month)} ${invoice.invoiceDate.year}'
                                                  : '-',
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildCompactDetail(
                                              'Invoice #',
                                              invoice?.invoiceNumber ?? '-',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.description_outlined,
                                            size: 15,
                                            color: Color(0xFF6B7280),
                                          ),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text(
                                              'View Details',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF4B5563),
                                              ),
                                            ),
                                          ),
                                          if (isAvailable && canAllotInventory)
                                            _buildActionIcon(
                                              icon: Icons.assignment_ind_rounded,
                                              color: const Color(0xFF4F46E5),
                                              onTap: () => _showAllotmentDialog(
                                                context,
                                                p.id,
                                                InventoryItemType.panel,
                                              ),
                                            ),
                                          if (canEditInventory) ...[
                                            const SizedBox(width: 8),
                                            _buildActionIcon(
                                              icon: Icons.edit_rounded,
                                              color: const Color(0xFF6B7280),
                                              onTap: () => _showEditPanelDialog(p),
                                            ),
                                          ],
                                          if (canEditInventory) ...[
                                            const SizedBox(width: 8),
                                            _buildActionIcon(
                                              icon: Icons.delete_outline_rounded,
                                              color: AppTheme.errorColor,
                                              onTap: () => _confirmDeletePanel(p),
                                            ),
                                          ],
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
                          dataRowMaxHeight: 72,
                          horizontalMargin: 18,
                          columnSpacing: 28,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFEFF4FB).withOpacity(0.95),
                          ),
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
                            final invoice = inventoryState.invoices.cast<InventoryInvoice?>().firstWhere((inv) => inv?.id == p.invoiceId, orElse: () => null);

                            return DataRow(cells: [
                              DataCell(Text(p.serialNumber, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                              DataCell(Text('${p.wattCapacity}W')),
                              DataCell(Text(p.panelType)),
                              DataCell(_StatusBadge(status: p.status)),
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
                                    if (p.status == 'available' && canAllotInventory)
                                      TextButton.icon(
                                        onPressed: () => _showAllotmentDialog(context, p.id, InventoryItemType.panel),
                                        icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                                        label: const Text('Allot'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    if (canEditInventory)
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, size: 18),
                                        onPressed: () => _showEditPanelDialog(p),
                                      ),
                                    if (canEditInventory)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorColor),
                                        onPressed: () => _confirmDeletePanel(p),
                                      ),
                                  ],
                                ),
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

  Widget _buildMobileStatTile({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: Color(0xFF9AA6B6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  Future<void> _showEditPanelDialog(PanelItem panel) async {
    final inventoryState = ref.read(inventoryProvider);
    final linkedInvoice =
        panel.invoiceId == null
            ? null
            : inventoryState.invoices
                .cast<InventoryInvoice?>()
                .firstWhere(
                  (invoice) => invoice?.id == panel.invoiceId,
                  orElse: () => null,
                );
    final brandController = TextEditingController(text: panel.brand);
    final wattController = TextEditingController(text: panel.wattCapacity.toString());
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
    String selectedType = panel.panelType;
    String selectedStatus = panel.status;
    DateTime selectedInvoiceDate = linkedInvoice?.invoiceDate ?? DateTime.now();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7F9FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Panel'),
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
                TextField(
                  controller: wattController,
                  decoration: const InputDecoration(labelText: 'Watt Capacity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const ['DCR', 'NDCR']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => selectedType = value ?? selectedType,
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Purchase details update all inventory items linked to this invoice.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
    final updated = panel.copyWith(
      brand: brandController.text.trim(),
      wattCapacity: int.tryParse(wattController.text.trim()) ?? panel.wattCapacity,
      panelType: selectedType,
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
    await ref.read(inventoryProvider.notifier).updatePanel(updated);
  }

  Future<void> _confirmDeletePanel(PanelItem panel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Panel'),
        content: Text('Delete panel ${panel.serialNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(inventoryProvider.notifier).deletePanel(panel.id);
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
      backgroundColor: const Color(0xFFF7F9FF),
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
