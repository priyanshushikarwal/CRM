import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/config/app_mode.dart';
import '../../core/theme/app_theme.dart';
import '../../models/application_model.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_providers.dart';
import '../../providers/app_providers.dart';
import 'widgets/brand_details_dialog.dart';
import 'widgets/inverter_details_dialog.dart';
import 'widgets/meter_details_dialog.dart';


class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _filtersExpanded = false;
  String? _panelBrandFilter;
  String? _panelTypeFilter;
  String? _panelStatusFilter;
  String? _inverterBrandFilter;
  String? _inverterTypeFilter;
  String? _inverterStatusFilter;
  String? _meterBrandFilter;
  String? _meterCategoryFilter;
  String? _meterPhaseFilter;
  String? _meterStatusFilter;

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

  String _normalizeBrand(String brand) => brand.trim().toLowerCase();

  String _displayBrandName(Iterable<String> brands) {
    for (final brand in brands) {
      final trimmed = brand.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  List<String> _brandFilterItems(Iterable<String> brands) {
    final displayByNormalized = <String, String>{};
    for (final brand in brands) {
      final normalized = _normalizeBrand(brand);
      final trimmed = brand.trim();
      if (normalized.isEmpty) continue;
      displayByNormalized.putIfAbsent(normalized, () => trimmed);
    }

    final items = displayByNormalized.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return items.map((entry) => entry.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 720;
    final useEmbeddedAppBar = true;
    final inventoryState = ref.watch(inventoryProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;
    final canAccessInventory = currentUser?.canAccessInventory ?? false;
    final canAddInventoryStock = currentUser?.canAddInventoryStock ?? false;
    final canAllotInventory = currentUser?.canAllotInventory ?? false;

    if (currentUserAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!canAccessInventory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 64,
              color: AppTheme.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text('Access Denied', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'You do not have permission to access inventory.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: useEmbeddedAppBar
          ? AppBar(
              backgroundColor: AppTheme.backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: isCompact ? 20 : 24,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompact ? 'InventoryCreator' : 'Factory Inventory',
                    style: (isCompact ? AppTextStyles.heading4 : AppTextStyles.heading2)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    isCompact
                        ? 'Live warehouse inventory'
                        : 'Panels, inverters, meters, and stock movement',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              actions: [
                if (!isCompact)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: IconButton(
                        onPressed: inventoryState.isLoading ? null : _refreshInventory,
                        tooltip: 'Refresh Inventory',
                        icon:
                            inventoryState.isLoading
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                : const Icon(Icons.sync_rounded),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(right: isCompact ? 16 : 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: inventoryState.isLoading ? null : _refreshInventory,
                            child: Center(
                              child:
                                  inventoryState.isLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                      : const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                      ),
                            ),
                          ),
                        ),
                      ),
                      if (isCompact && AppModeConfig.isInventoryOnly) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: PopupMenuButton<int>(
                            tooltip: 'Sections',
                            icon: const Icon(Icons.more_horiz_rounded),
                            onSelected: (index) {
                              _tabController.animateTo(index);
                              setState(() {});
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<int>(
                                value: 0,
                                child: Text('Dashboard'),
                              ),
                              PopupMenuItem<int>(
                                value: 1,
                                child: Text('Solar Panels'),
                              ),
                              PopupMenuItem<int>(
                                value: 2,
                                child: Text('Inverters'),
                              ),
                              PopupMenuItem<int>(
                                value: 3,
                                child: Text('Meters'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              bottom: isCompact
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(64),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 760),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                              labelColor: Colors.white,
                              unselectedLabelColor: AppTheme.textSecondary,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Dashboard'),
                                Tab(text: 'Solar Panels'),
                                Tab(text: 'Inverters'),
                                Tab(text: 'Meters'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            )
          : null,
      body: _buildBodyContent(
        inventoryState,
        ref,
        canAllotInventory,
      ),
      floatingActionButton:
          canAddInventoryStock
              ? FloatingActionButton.extended(
                      onPressed: () => _showAddInventoryDialog(context),
                      backgroundColor: AppTheme.primaryColor,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text(
                        'Add Stock',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
              : null,
    );
  }

  Widget _buildBodyContent(
    InventoryState inventoryState,
    WidgetRef ref,
    bool canAllotInventory,
  ) {
    if (inventoryState.isLoading && inventoryState.panels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (inventoryState.error != null) {
      return _buildErrorState(inventoryState.error!, ref);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildDashboard(inventoryState),
        _buildPanelInventory(inventoryState),
        _buildInverterInventory(inventoryState),
        _buildMeterInventory(inventoryState, canAllotInventory),
      ],
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
            onPressed: _refreshInventory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshInventory() async {
    try {
      await ref.read(inventoryProvider.notifier).loadAll();
      if (!mounted) return;
      final error = ref.read(inventoryProvider).error;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refresh failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildDashboard(InventoryState state) {
    final totalStock = state.panels.length + state.inverters.length + state.meters.length;
    final availablePanels = state.panels.where((item) => item.status == 'available').length;
    final availableInverters = state.inverters.where((item) => item.status == 'available').length;
    final availableMeters = state.meters.where((item) => item.status == 'available').length;
    final isCompact = MediaQuery.of(context).size.width < 720;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isCompact ? 16 : 24, 16, isCompact ? 16 : 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDDE4FF), Color(0xFFF5F7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Overview',
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Real-time snapshot of industrial assets and scan-ready inventory.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalStock',
                            style: AppTextStyles.heading1.copyWith(
                              fontSize: isCompact ? 42 : 48,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          Text(
                            'Total Stock Units',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.primaryColor,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildMiniBadge('$availablePanels panels available'),
                    _buildMiniBadge('$availableInverters inverters available'),
                    _buildMiniBadge('$availableMeters meters available'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final compactCards = constraints.maxWidth < 620;
              final children = [
                _buildStatCard('Total Panels', state.panels.length.toString(), Icons.solar_power_rounded, const Color(0xFF8BA8FF)),
                _buildStatCard('Total Inverters', state.inverters.length.toString(), Icons.settings_input_component_rounded, const Color(0xFFB8C0FF)),
                _buildStatCard('Total Meters', state.meters.length.toString(), Icons.speed_rounded, const Color(0xFFE2C6FF)),
              ];
              if (compactCards) {
                return Column(
                  children: [
                    for (int i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i != children.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    Expanded(child: children[i]),
                    if (i != children.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Solar Panel Stock', 'Detailed inventory by manufacturer'),
          const SizedBox(height: 16),
          _buildBrandSummary(state),
          const SizedBox(height: 32),
          _buildSectionHeader('Inverter Stock', 'Capacity and model mix by brand'),
          const SizedBox(height: 16),
          _buildInverterSummary(state),
          const SizedBox(height: 32),
          _buildSectionHeader('Meter Stock', 'Meter category and phase availability'),
          const SizedBox(height: 16),
          _buildMeterSummary(state, false, false),
          const SizedBox(height: 32),
          _buildSectionHeader('Recent Allotments', 'Latest handovers and reserved stock'),
          const SizedBox(height: 16),
          _buildRecentAllotmentsTable(state),
        ],
      ),
    );
  }

  Widget _buildBrandSummary(InventoryState state) {
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredPanels = state.panels.where((p) {
      final matchesSearch =
          searchQuery.isEmpty ||
          p.serialNumber.toLowerCase().contains(searchQuery) ||
          p.brand.toLowerCase().contains(searchQuery) ||
          p.panelType.toLowerCase().contains(searchQuery) ||
          p.wattCapacity.toString().contains(searchQuery);
      final matchesBrand =
          _panelBrandFilter == null ||
          _normalizeBrand(p.brand) == _normalizeBrand(_panelBrandFilter!);
      final matchesType =
          _panelTypeFilter == null || p.panelType == _panelTypeFilter;
      final matchesStatus =
          _panelStatusFilter == null || p.status == _panelStatusFilter;
      return matchesSearch && matchesBrand && matchesType && matchesStatus;
    }).toList();

    final Map<String, List<PanelItem>> groupedByBrand = {};
    for (var p in filteredPanels) {
      final normalizedBrand = _normalizeBrand(p.brand);
      groupedByBrand.putIfAbsent(normalizedBrand, () => []);
      groupedByBrand[normalizedBrand]!.add(p);
    }

    if (groupedByBrand.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(child: Text('No panels in stock.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: groupedByBrand.entries.map((brandEntry) {
        final panels = brandEntry.value;
        final brand = _displayBrandName(panels.map((panel) => panel.brand));
        
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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF8FAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE7EBF5)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeWattCounts.isEmpty ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        (typeWattCounts.isEmpty ? 'Out of stock' : 'Healthy stock').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: typeWattCounts.isEmpty ? AppTheme.errorColor : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.textLight),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  brand.toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  panels.isNotEmpty ? '${panels.first.panelType} inventory lineup' : 'Panel inventory',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _inventoryMetricBox(
                        value: panels.isEmpty ? '0' : '${panels.first.wattCapacity}',
                        label: 'Watt output avg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _inventoryMetricBox(
                        value: '${typeWattCounts.values.fold<int>(0, (sum, count) => sum + count)}',
                        label: 'Units available',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (typeWattCounts.isNotEmpty)
                  ...typeWattCounts.entries.take(3).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _inventoryBreakdownRow(
                          e.key,
                          '${e.value} panels',
                          const Color(0xFFECFDF5),
                          const Color(0xFF059669),
                        ),
                      ))
                else
                  const Text('No available stock', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 12)),
                const SizedBox(height: 10),
                const Text('Click to view details', style: TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.textPrimary, size: 22),
          ),
        ],
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

    final isCompact = MediaQuery.of(context).size.width < 720;

    if (isCompact) {
      return Column(
        children: state.allotments.take(10).map((allotment) {
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

          final refText = allotment.applicationId != null
              ? 'APP-${allotment.applicationId!.length > 5 ? allotment.applicationId!.substring(0, 5) : allotment.applicationId}'
              : 'Manual';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        allotment.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        allotment.itemType.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildAllotmentMetaRow('Ref', refText),
                const SizedBox(height: 6),
                _buildAllotmentMetaRow('Serial', serial),
                const SizedBox(height: 6),
                _buildAllotmentMetaRow(
                  'Date',
                  '${allotment.handoverDate.day}/${allotment.handoverDate.month}/${allotment.handoverDate.year}',
                ),
              ],
            ),
          );
        }).toList(),
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

  Widget _buildAllotmentMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
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
    );
  }

  Widget _buildPanelInventory(InventoryState state) {
    final brands = _brandFilterItems(state.panels.map((p) => p.brand));
    final types =
        state.panels.map((p) => p.panelType).toSet().toList()..sort();

    return Column(
      children: [
        _buildSearchBar(
          hintText: 'Search by serial number, brand, watt, or type...',
        ),
        _buildFilterBar(
          filters: [
            _FilterConfig(
              hint: 'Brand',
              value: _panelBrandFilter,
              items: brands,
              onChanged:
                  (value) => setState(() => _panelBrandFilter = value),
            ),
            _FilterConfig(
              hint: 'Type',
              value: _panelTypeFilter,
              items: types,
              onChanged: (value) => setState(() => _panelTypeFilter = value),
            ),
            _FilterConfig(
              hint: 'Status',
              value: _panelStatusFilter,
              items: const ['available', 'allotted'],
              onChanged:
                  (value) => setState(() => _panelStatusFilter = value),
            ),
          ],
          onClear: () {
            setState(() {
              _searchController.clear();
              _panelBrandFilter = null;
              _panelTypeFilter = null;
              _panelStatusFilter = null;
            });
          },
        ),
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
    final brands = _brandFilterItems(state.inverters.map((i) => i.brand));
    final types =
        state.inverters.map((i) => i.inverterType).toSet().toList()..sort();

    return Column(
      children: [
        _buildSearchBar(
          hintText: 'Search by serial number, brand, capacity, or type...',
        ),
        _buildFilterBar(
          filters: [
            _FilterConfig(
              hint: 'Brand',
              value: _inverterBrandFilter,
              items: brands,
              onChanged:
                  (value) => setState(() => _inverterBrandFilter = value),
            ),
            _FilterConfig(
              hint: 'Type',
              value: _inverterTypeFilter,
              items: types,
              onChanged:
                  (value) => setState(() => _inverterTypeFilter = value),
            ),
            _FilterConfig(
              hint: 'Status',
              value: _inverterStatusFilter,
              items: const ['available', 'allotted'],
              onChanged:
                  (value) => setState(() => _inverterStatusFilter = value),
            ),
          ],
          onClear: () {
            setState(() {
              _searchController.clear();
              _inverterBrandFilter = null;
              _inverterTypeFilter = null;
              _inverterStatusFilter = null;
            });
          },
        ),
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
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredInverters = state.inverters.where((i) {
      final matchesSearch =
          searchQuery.isEmpty ||
          i.serialNumber.toLowerCase().contains(searchQuery) ||
          i.brand.toLowerCase().contains(searchQuery) ||
          i.inverterType.toLowerCase().contains(searchQuery) ||
          i.capacityKw.toString().contains(searchQuery);
      final matchesBrand =
          _inverterBrandFilter == null ||
          _normalizeBrand(i.brand) == _normalizeBrand(_inverterBrandFilter!);
      final matchesType =
          _inverterTypeFilter == null || i.inverterType == _inverterTypeFilter;
      final matchesStatus =
          _inverterStatusFilter == null || i.status == _inverterStatusFilter;
      return matchesSearch && matchesBrand && matchesType && matchesStatus;
    }).toList();

    final Map<String, List<InverterItem>> groupedByBrand = {};
    for (var i in filteredInverters) {
      final normalizedBrand = _normalizeBrand(i.brand);
      groupedByBrand.putIfAbsent(normalizedBrand, () => []);
      groupedByBrand[normalizedBrand]!.add(i);
    }

    if (groupedByBrand.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(child: Text('No inverters in stock.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: groupedByBrand.entries.map((brandEntry) {
        final inverters = brandEntry.value;
        final brand = _displayBrandName(
          inverters.map((inverter) => inverter.brand),
        );
        
        final Map<String, int> typeCapCounts = {};
        for (var i in inverters) {
          if (i.status == 'available') {
            final key =
                '${i.inverterType} / ${i.inverterPhase} (${i.capacityKw} kW)';
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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF8FAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE7EBF5)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'PREMIUM RATED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.textLight),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  brand.toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 18),
                if (typeCapCounts.isNotEmpty)
                  ...typeCapCounts.entries.take(4).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _inventoryBreakdownRow(
                          e.key,
                          '${e.value} in stock',
                          const Color(0xFFF5F3FF),
                          AppTheme.primaryColor,
                        ),
                      ))
                else
                  const Text('No available stock', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic, fontSize: 12)),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => InverterDetailsDialog(brandName: brand, inverters: inverters),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    side: const BorderSide(color: Color(0xFFE4E7EC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Stock Available'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMeterInventory(
    InventoryState state,
    bool canAllotInventory,
  ) {
    final canEditInventory = ref.watch(currentUserProvider).value?.canEdit ?? false;
    final brands = _brandFilterItems(state.meters.map((m) => m.brand));
    final categories =
        state.meters.map((m) => m.meterCategory).toSet().toList()..sort();
    final phases =
        state.meters.map((m) => m.meterPhase).toSet().toList()..sort();

    return Column(
      children: [
        _buildSearchBar(
          hintText: 'Search by serial number, brand, meter type, or phase...',
        ),
        _buildFilterBar(
          filters: [
            _FilterConfig(
              hint: 'Brand',
              value: _meterBrandFilter,
              items: brands,
              onChanged: (value) => setState(() => _meterBrandFilter = value),
            ),
            _FilterConfig(
              hint: 'Category',
              value: _meterCategoryFilter,
              items: categories,
              onChanged:
                  (value) => setState(() => _meterCategoryFilter = value),
            ),
            _FilterConfig(
              hint: 'Phase',
              value: _meterPhaseFilter,
              items: phases,
              onChanged: (value) => setState(() => _meterPhaseFilter = value),
            ),
            _FilterConfig(
              hint: 'Status',
              value: _meterStatusFilter,
              items: const ['available', 'allotted'],
              onChanged: (value) => setState(() => _meterStatusFilter = value),
            ),
          ],
          onClear: () {
            setState(() {
              _searchController.clear();
              _meterBrandFilter = null;
              _meterCategoryFilter = null;
              _meterPhaseFilter = null;
              _meterStatusFilter = null;
            });
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STOCK SUMMARY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMeterSummary(state, canAllotInventory, canEditInventory),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeterSummary(
    InventoryState state,
    bool canAllotInventory,
    bool canEditInventory,
  ) {
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredMeters = state.meters.where((m) {
      final matchesSearch =
          searchQuery.isEmpty ||
          m.serialNumber.toLowerCase().contains(searchQuery) ||
          m.brand.toLowerCase().contains(searchQuery) ||
          m.meterCategory.toLowerCase().contains(searchQuery) ||
          m.meterType.toLowerCase().contains(searchQuery) ||
          m.meterPhase.toLowerCase().contains(searchQuery);
      final matchesBrand =
          _meterBrandFilter == null ||
          _normalizeBrand(m.brand) == _normalizeBrand(_meterBrandFilter!);
      final matchesCategory =
          _meterCategoryFilter == null ||
          m.meterCategory == _meterCategoryFilter;
      final matchesPhase =
          _meterPhaseFilter == null || m.meterPhase == _meterPhaseFilter;
      final matchesStatus =
          _meterStatusFilter == null || m.status == _meterStatusFilter;
      return matchesSearch &&
          matchesBrand &&
          matchesCategory &&
          matchesPhase &&
          matchesStatus;
    }).toList();

    final Map<String, List<MeterItem>> groupedByBrand = {};
    for (final meter in filteredMeters) {
      final normalizedBrand = _normalizeBrand(meter.brand);
      groupedByBrand.putIfAbsent(normalizedBrand, () => []);
      groupedByBrand[normalizedBrand]!.add(meter);
    }

    if (groupedByBrand.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(
          child: Text(
            'No meters in stock.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: groupedByBrand.entries.map((brandEntry) {
        final meters = brandEntry.value;
        final brand = _displayBrandName(meters.map((meter) => meter.brand));
        final availableMeters =
            meters.where((meter) => meter.status == 'available').toList();

        final Map<String, int> meterCounts = {};
        for (final meter in availableMeters) {
          final key =
              '${meter.meterCategory} / ${meter.meterType} / ${meter.meterPhase}';
          meterCounts[key] = (meterCounts[key] ?? 0) + 1;
        }

        return InkWell(
          onTap: () => showDialog(
            context: context,
            builder:
                (context) =>
                    MeterDetailsDialog(brandName: brand, meters: meters),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      brand.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '${meters.length} total',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                ...meterCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Text(
                          ' = ',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Meters',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (meterCounts.isNotEmpty) ...[
                  const Divider(height: 16),
                  const Center(
                    child: Text(
                      'STOCK AVAILABLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ] else
                  const Text(
                    'No available stock',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 16),
                ...meters.take(5).map((meter) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meter.serialNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${meter.meterCategory} / ${meter.meterType} / ${meter.meterPhase}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _StatusBadge(status: meter.status),
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Click to view details',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 10,
                      color: AppTheme.textLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

  Widget _buildSearchBar({
    String hintText = 'Search by serial number or brand...',
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
            ),
          ),
          onChanged: (v) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildFilterBar({
    required List<_FilterConfig> filters,
    required VoidCallback onClear,
  }) {
    final isCompact = MediaQuery.of(context).size.width < 720;
    final hasActiveFilters = filters.any((filter) => filter.value != null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasActiveFilters
                            ? AppTheme.primaryColor.withOpacity(0.25)
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: hasActiveFilters
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasActiveFilters ? 'Filters applied' : 'Filters',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: hasActiveFilters
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (hasActiveFilters)
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${filters.where((filter) => filter.value != null).length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        Icon(
                          _filtersExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _filtersExpanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...filters.map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildFilterDropdown(
                              hint: filter.hint,
                              value: filter.value,
                              items: filter.items,
                              onChanged: filter.onChanged,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              onClear();
                              setState(() => _filtersExpanded = false);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Clear'),
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
              spacing: 10,
              runSpacing: 10,
              children: [
                ...filters.map(
                  (filter) => SizedBox(
                    width: 160,
                    child: _buildFilterDropdown(
                      hint: filter.hint,
                      value: filter.value,
                      items: filter.items,
                      onChanged: filter.onChanged,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          isExpanded: true,
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 13)),
      ],
    );
  }

  Widget _buildMiniBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _inventoryMetricBox({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _inventoryBreakdownRow(
    String title,
    String value,
    Color background,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllotmentDialog(BuildContext context, String itemId, InventoryItemType type) {
    showDialog(
      context: context,
      builder: (context) => _AllotmentDialog(itemId: itemId, itemType: type),
    );
  }

  Future<void> _showEditMeterDialog(MeterItem meter) async {
    final brandController = TextEditingController(text: meter.brand);
    String selectedCategory = meter.meterCategory;
    String selectedType =
        meter.meterType == 'LTCT'
            ? 'LT CT'
            : meter.meterType == 'HTCT'
                ? 'HT CT'
                : meter.meterType;
    String selectedPhase = meter.meterPhase;
    String selectedStatus = meter.status;

    final updated = await showDialog<MeterItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Meter'),
        content: Column(
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
              onChanged: (value) => selectedCategory = value ?? selectedCategory,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                meter.copyWith(
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
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == null) return;
    await ref.read(inventoryProvider.notifier).updateMeter(updated);
  }

  Future<void> _confirmDeleteMeter(MeterItem meter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meter'),
        content: Text('Delete meter ${meter.serialNumber}?'),
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
      await ref.read(inventoryProvider.notifier).deleteMeter(meter.id);
    }
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

class _FilterConfig {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterConfig({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });
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
  String _inverterPhaseSelection = 'Single Phase';
  String _meterFullTypeSelection = 'Normal Net Meter';
  String _meterPhaseSelection = 'Single Phase';

  @override
  void initState() {
    super.initState();
    _receivedByController.text = ref.read(currentUserProvider).value?.fullName ?? '';
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _partyController.dispose();
    _brandController.dispose();
    _receivedByController.dispose();
    _serialController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  String _normalizeSerial(String serial) => serial.trim().toUpperCase();

  bool get _supportsBarcodeScan {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  bool _containsSerial(List<String> serials, String serial) {
    final normalizedSerial = _normalizeSerial(serial);
    return serials.any((item) => _normalizeSerial(item) == normalizedSerial);
  }

  void _addPanelEntry(String type) {
    final sn = _serialController.text.trim();
    final cap = int.tryParse(_capacityController.text) ?? 540;
    if (sn.isNotEmpty) {
      if (_panelEntries.any((e) => _normalizeSerial(e['serial'] as String) == _normalizeSerial(sn))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicate serial number in list')));
        return;
      }
      setState(() {
        _panelEntries.add({'serial': sn, 'capacity': cap, 'type': type});
        _serialController.clear();
      });
    }
  }

  void _showDuplicateSerialMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate serial number in list')),
    );
  }

  void _addSimpleSerial(List<String> target, String serial) {
    final sn = serial.trim();
    if (sn.isEmpty) return;
    if (_containsSerial(target, sn)) {
      _showDuplicateSerialMessage();
      return;
    }
    setState(() {
      target.add(sn);
      _serialController.clear();
    });
  }

  Future<void> _scanAndHandleSerial({
    required void Function(String serial) onScanned,
  }) async {
    if (!_supportsBarcodeScan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode scanning is supported on Android, iPhone, macOS, and Web only.')),
      );
      return;
    }

    final scannedValue = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _BarcodeScannerDialog(),
    );

    if (!mounted || scannedValue == null) return;

    final normalized = scannedValue.trim();
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No serial number found in scanned code')),
      );
      return;
    }

    onScanned(normalized);
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
          inverterPhase: _inverterPhaseSelection,
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
                  ? 'LTCT' 
                  : 'HTCT',
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
          DropdownButtonFormField<String>(
            value: _inverterPhaseSelection,
            items: ['Single Phase', 'Three Phase']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _inverterPhaseSelection = v!),
            decoration: const InputDecoration(labelText: 'Inverter Phase'),
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
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
              tooltip: 'Scan barcode',
              onPressed: () => _scanAndHandleSerial(
                onScanned: (serial) {
                  if (_panelEntries.any((e) => _normalizeSerial(e['serial'] as String) == _normalizeSerial(serial))) {
                    _showDuplicateSerialMessage();
                    return;
                  }
                  setState(() {
                    _panelEntries.add({
                      'serial': serial,
                      'capacity': int.tryParse(_capacityController.text) ?? 540,
                      'type': type,
                    });
                    _serialController.clear();
                  });
                },
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
                onSubmitted: (_) => _addSimpleSerial(target, _serialController.text),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
              tooltip: 'Scan barcode',
              onPressed: () => _scanAndHandleSerial(
                onScanned: (serial) => _addSimpleSerial(target, serial),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add), 
              onPressed: () => _addSimpleSerial(target, _serialController.text),
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

class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Barcode'),
      content: SizedBox(
        width: 340,
        height: 340,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                onDetect: _onDetect,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black54,
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'Barcode ko frame ke andar layein. Scan hote hi serial number add ho jayega.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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
      await ref.read(inventoryProvider.notifier).allotItem(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
      title: const Text('New Allotment / Handover', style: AppTextStyles.heading3),
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
