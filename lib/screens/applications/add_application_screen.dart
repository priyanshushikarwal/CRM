import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/application_model.dart';
import '../../services/application_service.dart';
import '../../providers/app_providers.dart';

class AddApplicationScreen extends ConsumerStatefulWidget {
  final String? applicationId;

  const AddApplicationScreen({super.key, this.applicationId});

  @override
  ConsumerState<AddApplicationScreen> createState() => _AddApplicationScreenState();
}

class _AddApplicationScreenState extends ConsumerState<AddApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  
  String _generatedId = '';

  final _fullNameController = TextEditingController();
  final _nameAsPerBillController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _consumerAccountNumberController = TextEditingController();
  final _proposedCapacityController = TextEditingController();
  final _finalAmountController = TextEditingController();

  String _selectedCategory = 'Domestic';
  DateTime _applicationDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.applicationId != null;

    if (_isEditing) {
      _loadApplicationData();
    } else {
      _generatedId = ApplicationService.generateApplicationNumber();
    }
  }

  Future<void> _loadApplicationData() async {
    setState(() => _isLoading = true);

    try {
      final app = await ApplicationService.fetchApplication(widget.applicationId!);
      if (app != null) {
        _generatedId = app.applicationNumber;
        _applicationDate = app.applicationSubmissionDate;
        
        _fullNameController.text = app.fullName;
        _nameAsPerBillController.text = app.nameAsPerBill ?? '';
        _mobileController.text = app.mobile;
        _addressController.text = app.address;
        _consumerAccountNumberController.text = app.consumerAccountNumber;
        _proposedCapacityController.text = app.proposedCapacity.toString();
        _finalAmountController.text = app.finalAmount?.toString() ?? '';
        
        if (['Domestic', 'Commercial'].contains(app.categoryName)) {
           _selectedCategory = app.categoryName;
        } else {
           _selectedCategory = 'Domestic';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading application: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nameAsPerBillController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _consumerAccountNumberController.dispose();
    _proposedCapacityController.dispose();
    _finalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildCustomerDetails(),
                          const SizedBox(height: 24),
                          _buildNavigationButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/applications'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Application' : 'New Solar Application',
                  style: AppTextStyles.heading3,
                ),
                Text(
                  'Customer Application Management',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Customer Details',
                style: AppTextStyles.heading4.copyWith(color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _generatedId,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Consumer Unique ID',
                    prefixIcon: Icon(Icons.tag_outlined),
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _applicationDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _applicationDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_applicationDate),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (Actual Name) *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => 
                      value == null || value.isEmpty ? 'Required field' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _nameAsPerBillController,
                  decoration: const InputDecoration(
                    labelText: 'Name (As Per Electricity Bill) *',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  validator: (value) => 
                      value == null || value.isEmpty ? 'Required field' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: '+91 ',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.length != 10) {
                      return 'Enter valid 10-digit mobile';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _consumerAccountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Electricity Bill Number (K No) *',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (value) => 
                      value == null || value.isEmpty ? 'Required field' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address *',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            maxLines: 2,
            validator: (value) => 
                value == null || value.isEmpty ? 'Required field' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _proposedCapacityController,
                  decoration: const InputDecoration(
                    labelText: 'Solar Plant Capacity (kW) *',
                    prefixIcon: Icon(Icons.solar_power_outlined),
                    suffixText: 'kW',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => 
                      value == null || value.isEmpty ? 'Required field' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Solar Category *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ['Domestic', 'Commercial'].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _finalAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Solar Plant Final Amount (Rs.) *',
                    prefixIcon: Icon(Icons.currency_rupee_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => 
                      value == null || value.isEmpty ? 'Required field' : null,
                ),
              ),
              const Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => context.go('/applications'),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_isEditing ? 'Save Changes' : 'Create Application'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final uuid = const Uuid();
      final currentUser = ref.read(currentUserProvider).value;

      final application = ApplicationModel(
        id: widget.applicationId ?? uuid.v4(),
        applicationNumber: _generatedId,
        state: 'Rajasthan', // Default values for required fields
        discomName: 'Default Discom',
        fullName: _fullNameController.text,
        nameAsPerBill: _nameAsPerBillController.text,
        gender: 'Not Specified',
        address: _addressController.text,
        pincode: '000000',
        consumerAccountNumber: _consumerAccountNumberController.text,
        mobile: _mobileController.text,
        district: 'Default',
        applicationSubmissionDate: _applicationDate,
        circleName: 'Default',
        divisionName: 'Default',
        subdivisionName: 'Default',
        sanctionedLoad: 0.0,
        proposedCapacity: double.tryParse(_proposedCapacityController.text) ?? 0,
        finalAmount: double.tryParse(_finalAmountController.text),
        categoryName: _selectedCategory,
        netEligibleCapacity: 0.0,
        vendorName: AppConstants.companyName,
        approvalStatus: ApprovalStatus.pending,
        submittedBy: currentUser?.id,
        createdAt: now,
        updatedAt: now,
      );

      if (_isEditing) {
        await ApplicationService.updateApplication(application);
      } else {
        await ApplicationService.createApplication(application);
      }

      ref.read(applicationsProvider.notifier).loadApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Application updated!' : 'Application created!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/applications');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
