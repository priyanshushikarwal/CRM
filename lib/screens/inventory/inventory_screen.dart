import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_providers.dart';
import '../../services/inventory_service.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          _buildHeader(context, inventoryState),
          // Content
          Expanded(
            child:
                inventoryState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : inventoryState.error != null
                    ? _buildErrorState(inventoryState.error!)
                    : inventoryState.filteredItems.isEmpty
                    ? _buildEmptyState()
                    : _buildInventoryList(inventoryState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInventoryDialog(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Solar Panel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InventoryState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solar Panel Inventory',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Manage your solar panel stock and assignments',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick stats
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickStat(
                    'Total',
                    '${state.totalPanels}',
                    Icons.inventory_2_rounded,
                    AppTheme.primaryColor,
                  ),
                  _buildQuickStat(
                    'Available',
                    '${state.availablePanels}',
                    Icons.check_circle_outline_rounded,
                    AppTheme.successColor,
                  ),
                  _buildQuickStat(
                    'Used',
                    '${state.usedPanels}',
                    Icons.assignment_turned_in_rounded,
                    AppTheme.warningColor,
                  ),
                  _buildQuickStat(
                    'DCR',
                    '${state.totalDcrPanels}',
                    Icons.solar_power_rounded,
                    Colors.blue,
                  ),
                  _buildQuickStat(
                    'Non-DCR',
                    '${state.totalNonDcrPanels}',
                    Icons.solar_power_outlined,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(inventoryProvider.notifier).setSearchQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search by company, model, or capacity...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(inventoryProvider.notifier)
                              .setSearchQuery('');
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.heading4.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(InventoryState state) {
    final items = state.filteredItems;

    // Group items by company Name
    final Map<String, List<SolarInventoryItem>> groupedItems = {};
    for (var item in items) {
      if (!groupedItems.containsKey(item.companyName)) {
        groupedItems[item.companyName] = [];
      }
      groupedItems[item.companyName]!.add(item);
    }
    final companies = groupedItems.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9, // More vertical space for models list
          ),
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final companyName = companies[index];
            return _buildCompanyCard(companyName, groupedItems[companyName]!);
          },
        );
      },
    );
  }

  Widget _buildCompanyCard(String companyName, List<SolarInventoryItem> items) {
    int totalPanels = 0;
    int availablePanels = 0;
    int usedPanels = 0;
    int dcrTotal = 0;
    int nonDcrTotal = 0;

    for (var item in items) {
      totalPanels += item.totalQuantity;
      availablePanels += item.availableQuantity;
      usedPanels += item.usedQuantity;
      if (item.isDcr) {
        dcrTotal += item.availableQuantity;
      } else {
        nonDcrTotal += item.availableQuantity;
      }
    }

    final availabilityPercent =
        totalPanels > 0 ? availablePanels / totalPanels : 0.0;

    Color statusColor;
    String statusLabel;
    if (availabilityPercent > 0.5) {
      statusColor = AppTheme.successColor;
      statusLabel = 'In Stock';
    } else if (availabilityPercent > 0) {
      statusColor = AppTheme.warningColor;
      statusLabel = 'Low Stock';
    } else {
      statusColor = AppTheme.errorColor;
      statusLabel = 'Out of Stock';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.08),
                  AppTheme.primaryLight.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons
                        .business_rounded, // Changed to business icon for company
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DCR: $dcrTotal',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Non-DCR: $nonDcrTotal',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Models List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                return _buildModelListItem(items[index]);
              },
            ),
          ),
          // Bottom Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildStockInfo(
                    'Total',
                    '$totalPanels',
                    Icons.inventory_2_outlined,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStockInfo(
                    'Avail',
                    '$availablePanels',
                    Icons.check_circle_outline,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildStockInfo(
                    'Used',
                    '$usedPanels',
                    Icons.assignment_turned_in_outlined,
                    AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: LinearProgressIndicator(
              value: totalPanels > 0 ? usedPanels / totalPanels : 0,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelListItem(SolarInventoryItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.panelModel,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              item.isDcr
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isDcr ? 'DCR' : 'Non-DCR',
                          style: TextStyle(
                            fontSize: 9,
                            color: item.isDcr ? Colors.blue : Colors.purple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.capacityKw} kW • In stock: ${item.availableQuantity}/${item.totalQuantity}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showAssignmentsDialog(item),
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  tooltip: 'Assignments',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: AppTheme.textSecondary,
                ),
                IconButton(
                  onPressed: () => _showEditInventoryDialog(item),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  tooltip: 'Edit',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: AppTheme.primaryColor,
                ),
                IconButton(
                  onPressed: () => _confirmDelete(item),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: 'Delete',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: AppTheme.errorColor,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.solar_power_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Solar Panels in Inventory',
            style: AppTextStyles.heading3.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add solar panels to track stock and assignments',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddInventoryDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Solar Panel'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text('Error loading inventory', style: AppTextStyles.heading4),
          const SizedBox(height: 8),
          Text(error, style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                () => ref.read(inventoryProvider.notifier).loadInventory(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ===================== DIALOGS =====================

  void _showAddInventoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => _AddEditInventoryDialog(
            onSaveMultiple: (
              company,
              capacity,
              qty,
              dcrModels,
              nonDcrModels,
              desc,
            ) async {
              await ref
                  .read(inventoryProvider.notifier)
                  .addMultipleItems(
                    companyName: company,
                    capacityKw: capacity,
                    quantity: qty,
                    dcrModels: dcrModels,
                    nonDcrModels: nonDcrModels,
                    description: desc,
                  );
            },
          ),
    );
  }

  void _showEditInventoryDialog(SolarInventoryItem item) {
    showDialog(
      context: context,
      builder:
          (context) => _AddEditInventoryDialog(
            existingItem: item,
            onSaveSingle: (company, model, capacity, qty, isDcr, desc) async {
              final updated = item.copyWith(
                companyName: company,
                panelModel: model,
                capacityKw: capacity,
                totalQuantity: qty,
                isDcr: isDcr,
                description: desc,
              );
              await ref.read(inventoryProvider.notifier).updateItem(updated);
            },
          ),
    );
  }

  void _showAssignmentsDialog(SolarInventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => _AssignmentsDialog(item: item),
    );
  }

  Future<void> _confirmDelete(SolarInventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Inventory Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this solar panel?',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.companyName} - ${item.panelModel}\n${item.usedQuantity} panels currently assigned',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
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

    if (confirm == true) {
      try {
        await ref.read(inventoryProvider.notifier).deleteItem(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inventory item deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}

// ===================== ADD/EDIT DIALOG =====================

class _AddEditInventoryDialog extends StatefulWidget {
  final SolarInventoryItem? existingItem;
  final Future<void> Function(
    String company,
    String model,
    double capacity,
    int quantity,
    bool isDcr,
    String? description,
  )?
  onSaveSingle;
  final Future<void> Function(
    String company,
    double capacity,
    int quantity,
    List<String> dcrModels,
    List<String> nonDcrModels,
    String? description,
  )?
  onSaveMultiple;

  const _AddEditInventoryDialog({
    this.existingItem,
    this.onSaveSingle,
    this.onSaveMultiple,
  });

  @override
  State<_AddEditInventoryDialog> createState() =>
      _AddEditInventoryDialogState();
}

class _AddEditInventoryDialogState extends State<_AddEditInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _capacityController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Single edit mode controllers
  final _modelController = TextEditingController();
  bool _isDcrEdit = true;

  // Add multiple mode state
  final _dcrInputController = TextEditingController();
  final _nonDcrInputController = TextEditingController();
  final List<String> _dcrModels = [];
  final List<String> _nonDcrModels = [];

  bool _isLoading = false;

  // Preset company names for quick selection
  static const List<String> _commonCompanies = [
    'Adani Solar',
    'Tata Power Solar',
    'Waaree Energies',
    'Vikram Solar',
    'Goldi Solar',
    'Renewsys',
    'Premier Energies',
    'Jupiter Solar',
    'Loom Solar',
    'Jakson Solar',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _companyController.text = widget.existingItem!.companyName;
      _modelController.text = widget.existingItem!.panelModel;
      _capacityController.text = widget.existingItem!.capacityKw.toString();
      _quantityController.text = widget.existingItem!.totalQuantity.toString();
      _descriptionController.text = widget.existingItem!.description ?? '';
      _isDcrEdit = widget.existingItem!.isDcr;
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _dcrInputController.dispose();
    _nonDcrInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: 650,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.solar_power_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Solar Panel' : 'Add Solar Panel',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          isEdit
                              ? 'Update inventory details'
                              : 'Add multiple DCR and Non-DCR panels',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company name field
                      Text(
                        'Solar Panel Company *',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _companyController,
                        decoration: _inputDecoration(
                          'e.g., Adani Solar, Waaree',
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Company name required'
                                    : null,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            _commonCompanies.take(6).map((company) {
                              return ActionChip(
                                label: Text(
                                  company,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                onPressed: () {
                                  if (company != 'Other')
                                    _companyController.text = company;
                                },
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.08),
                                side: BorderSide(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Capacity and Quantity in a row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Capacity (kW) *',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _capacityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  decoration: _inputDecoration('e.g., 3.0'),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Capacity required';
                                    if (double.tryParse(v) == null ||
                                        double.parse(v) <= 0)
                                      return 'Invalid capacity';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity per Model *',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _inputDecoration('No. of panels'),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Quantity required';
                                    if (int.tryParse(v) == null ||
                                        int.parse(v) < 0)
                                      return 'Invalid quantity';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (isEdit) ...[
                        // Single model view for edit
                        Text(
                          'Panel Model / Series *',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _modelController,
                          decoration: _inputDecoration('e.g., ADANI-540M'),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Model required'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _isDcrEdit,
                              onChanged:
                                  (val) =>
                                      setState(() => _isDcrEdit = val ?? true),
                              activeColor: AppTheme.primaryColor,
                            ),
                            Text(
                              'Is this a DCR Panel?',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'DCR Panel Models (Type and press Enter)',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dcrInputController,
                          decoration: _inputDecoration(
                            'e.g., Model A, Model B...',
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.blue,
                              ),
                              onPressed:
                                  () => _addModel(
                                    _dcrInputController,
                                    _dcrModels,
                                  ),
                            ),
                          ),
                          onFieldSubmitted:
                              (_) => _addModel(_dcrInputController, _dcrModels),
                        ),
                        if (_dcrModels.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _dcrModels
                                    .map(
                                      (m) => Chip(
                                        label: Text(
                                          m,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        deleteIconColor: Colors.red,
                                        onDeleted:
                                            () => setState(
                                              () => _dcrModels.remove(m),
                                            ),
                                        backgroundColor: Colors.blue
                                            .withOpacity(0.1),
                                        side: BorderSide(
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                        const SizedBox(height: 20),

                        Text(
                          'Non-DCR Panel Models (Type and press Enter)',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nonDcrInputController,
                          decoration: _inputDecoration(
                            'e.g., Model X, Model Y...',
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.purple,
                              ),
                              onPressed:
                                  () => _addModel(
                                    _nonDcrInputController,
                                    _nonDcrModels,
                                  ),
                            ),
                          ),
                          onFieldSubmitted:
                              (_) => _addModel(
                                _nonDcrInputController,
                                _nonDcrModels,
                              ),
                        ),
                        if (_nonDcrModels.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _nonDcrModels
                                    .map(
                                      (m) => Chip(
                                        label: Text(
                                          m,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        deleteIconColor: Colors.red,
                                        onDeleted:
                                            () => setState(
                                              () => _nonDcrModels.remove(m),
                                            ),
                                        backgroundColor: Colors.purple
                                            .withOpacity(0.1),
                                        side: BorderSide(
                                          color: Colors.purple.withOpacity(0.3),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),
                      // Description
                      Text(
                        'Notes / Description (Optional)',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          'e.g., Mono PERC technology...',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSave,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Icon(
                              isEdit ? Icons.save_rounded : Icons.add_rounded,
                            ),
                    label: Text(isEdit ? 'Save Changes' : 'Add to Inventory'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addModel(TextEditingController controller, List<String> list) {
    final text = controller.text.trim();
    if (text.isNotEmpty && !list.contains(text)) {
      setState(() => list.add(text));
    }
    controller.clear();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Custom validation for add mode
    if (widget.existingItem == null &&
        _dcrModels.isEmpty &&
        _nonDcrModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one DCR or Non-DCR model'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final desc =
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim();

      if (widget.existingItem != null && widget.onSaveSingle != null) {
        await widget.onSaveSingle!(
          _companyController.text.trim(),
          _modelController.text.trim(),
          double.parse(_capacityController.text.trim()),
          int.parse(_quantityController.text.trim()),
          _isDcrEdit,
          desc,
        );
      } else if (widget.onSaveMultiple != null) {
        await widget.onSaveMultiple!(
          _companyController.text.trim(),
          double.parse(_capacityController.text.trim()),
          int.parse(_quantityController.text.trim()),
          _dcrModels,
          _nonDcrModels,
          desc,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem != null
                  ? 'Inventory updated successfully!'
                  : 'Inventory added successfully!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// ===================== ASSIGNMENTS DIALOG =====================

class _AssignmentsDialog extends StatelessWidget {
  final SolarInventoryItem item;

  const _AssignmentsDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel Assignments',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${item.companyName} - ${item.panelModel} (${item.capacityKw}kW)',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Summary row
            Row(
              children: [
                _summaryChip(
                  'Total: ${item.totalQuantity}',
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                _summaryChip(
                  'Used: ${item.usedQuantity}',
                  AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                _summaryChip(
                  'Available: ${item.availableQuantity}',
                  AppTheme.successColor,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            Text(
              'Assigned to Applications',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Assignments list
            Expanded(child: _AssignmentsList(inventoryItemId: item.id)),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AssignmentsList extends ConsumerWidget {
  final String inventoryItemId;

  const _AssignmentsList({required this.inventoryItemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(
      itemAssignmentsProvider(inventoryItemId),
    );

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Text(
              'Error loading assignments: $e',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
      data: (assignments) {
        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: AppTheme.textLight.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No applications assigned yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: assignments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                assignment.applicationNumber,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                assignment.consumerName,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Qty: ${assignment.quantityAssigned}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(assignment.assignedAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ===================== SOLAR PANEL PICKER WIDGET =====================
// Used in vendor selection / application form

class SolarPanelPickerWidget extends ConsumerStatefulWidget {
  final String? initialInventoryItemId;
  final String applicationId;
  final String applicationNumber;
  final String consumerName;
  final void Function(SolarInventoryItem? item)? onChanged;

  const SolarPanelPickerWidget({
    super.key,
    this.initialInventoryItemId,
    required this.applicationId,
    required this.applicationNumber,
    required this.consumerName,
    this.onChanged,
  });

  @override
  ConsumerState<SolarPanelPickerWidget> createState() =>
      _SolarPanelPickerWidgetState();
}

class _SolarPanelPickerWidgetState
    extends ConsumerState<SolarPanelPickerWidget> {
  SolarInventoryItem? _selectedItem;

  @override
  Widget build(BuildContext context) {
    final availableInventoryAsync = ref.watch(availableInventoryProvider);
    final appAssignmentsAsync = ref.watch(
      applicationInventoryProvider(widget.applicationId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Currently assigned panels for this application
        appAssignmentsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (assignments) {
            if (assignments.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Solar Panels',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...assignments.map(
                  (a) => _AssignedPanelCard(
                    assignment: a,
                    applicationId: widget.applicationId,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
              ],
            );
          },
        ),

        // Assign new panel section
        Text(
          'Assign Solar Panel from Inventory',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        availableInventoryAsync.when(
          loading: () => const LinearProgressIndicator(),
          error:
              (e, _) => Text(
                'Error loading inventory: $e',
                style: const TextStyle(color: AppTheme.errorColor),
              ),
          data: (items) {
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No panels available in inventory. Add panels from the Inventory section.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                DropdownButtonFormField<SolarInventoryItem>(
                  value: _selectedItem,
                  decoration: InputDecoration(
                    hintText: 'Select solar panel from inventory',
                    prefixIcon: const Icon(Icons.solar_power_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items:
                      items.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.companyName} - ${item.panelModel}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${item.capacityKw}kW | Available: ${item.availableQuantity}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.availableQuantity} left',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (item) {
                    setState(() => _selectedItem = item);
                    widget.onChanged?.call(item);
                  },
                ),
                if (_selectedItem != null) ...[
                  const SizedBox(height: 12),
                  // Show selected panel details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.solar_power_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedItem!.displayName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'Available: ${_selectedItem!.availableQuantity} panels | Total Stock: ${_selectedItem!.totalQuantity}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAssignDialog(context),
                          icon: const Icon(Icons.assignment_add, size: 16),
                          label: const Text('Assign'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAssignDialog(BuildContext context) {
    if (_selectedItem == null) return;

    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Assign Panel to Application',
              style: AppTextStyles.heading4,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedItem!.displayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Available: ${_selectedItem!.availableQuantity} panels',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quantity to Assign',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Number of panels',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Notes (Optional)',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    hintText: 'Any additional notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(quantityController.text.trim());
                  if (qty == null || qty <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Enter a valid quantity')),
                    );
                    return;
                  }
                  if (qty > _selectedItem!.availableQuantity) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Only ${_selectedItem!.availableQuantity} panels available',
                        ),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  try {
                    await InventoryService.assignToApplication(
                      inventoryItemId: _selectedItem!.id,
                      applicationId: widget.applicationId,
                      applicationNumber: widget.applicationNumber,
                      consumerName: widget.consumerName,
                      quantity: qty,
                      notes:
                          notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                    );
                    // Refresh providers
                    ref.invalidate(availableInventoryProvider);
                    ref.invalidate(
                      applicationInventoryProvider(widget.applicationId),
                    );
                    ref.invalidate(itemAssignmentsProvider(_selectedItem!.id));
                    setState(() => _selectedItem = null);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$qty panel(s) assigned successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Assign'),
              ),
            ],
          ),
    );
  }
}

class _AssignedPanelCard extends ConsumerWidget {
  final SolarAssignment assignment;
  final String applicationId;

  const _AssignedPanelCard({
    required this.assignment,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppTheme.successColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qty: ${assignment.quantityAssigned} panel(s) assigned',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
                if (assignment.notes != null && assignment.notes!.isNotEmpty)
                  Text(
                    assignment.notes!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline_rounded,
              size: 18,
              color: AppTheme.errorColor,
            ),
            tooltip: 'Remove assignment',
            onPressed: () async {
              try {
                await InventoryService.removeAssignment(
                  assignment.id,
                  assignment.inventoryItemId,
                  assignment.quantityAssigned,
                );
                ref.invalidate(availableInventoryProvider);
                ref.invalidate(applicationInventoryProvider(applicationId));
                ref.invalidate(
                  itemAssignmentsProvider(assignment.inventoryItemId),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Assignment removed'),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
