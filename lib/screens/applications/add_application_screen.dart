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
  ApplicationModel? _loadedApplication;

  String _generatedId = '';

  final _fullNameController = TextEditingController();
  final _nameAsPerBillController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _discomController = TextEditingController();
  final _consumerAccountNumberController = TextEditingController();
  final _proposedCapacityController = TextEditingController();
  final _finalAmountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _loanApplicationNumberController = TextEditingController();
  final _sanctionAmountController = TextEditingController();
  final _processingFeesController = TextEditingController();

  String _selectedCategory = 'Domestic';
  String _selectedLoanStatus = 'Not Applied';
  bool _giveUpSubsidy = false;
  DateTime _applicationDate = DateTime.now();
  DateTime? _sanctionDate;

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
        _loadedApplication = app;
        _generatedId = app.applicationNumber;
        _applicationDate = app.applicationSubmissionDate;

        _fullNameController.text = app.fullName;
        _nameAsPerBillController.text = app.nameAsPerBill ?? '';
        _mobileController.text = app.mobile;
        _addressController.text = app.address;
        _locationController.text = app.district;
        _discomController.text = app.discomName;
        _consumerAccountNumberController.text = app.consumerAccountNumber;
        _proposedCapacityController.text = app.proposedCapacity.toString();
        _finalAmountController.text = app.finalAmount?.toString() ?? '';
        _bankNameController.text = app.bankName ?? '';
        _ifscCodeController.text = app.ifscCode ?? '';
        _accountHolderController.text = app.accountHolderName ?? '';
        _accountNumberController.text = app.accountNumber ?? '';
        _loanApplicationNumberController.text = app.loanApplicationNumber ?? '';
        _sanctionAmountController.text = app.sanctionAmount?.toString() ?? '';
        _processingFeesController.text = app.processingFees?.toString() ?? '';
        _selectedLoanStatus = app.loanStatus;
        _giveUpSubsidy = app.giveUpSubsidy;
        _sanctionDate = app.sanctionDate;

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
    _locationController.dispose();
    _discomController.dispose();
    _consumerAccountNumberController.dispose();
    _proposedCapacityController.dispose();
    _finalAmountController.dispose();
    _bankNameController.dispose();
    _ifscCodeController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _loanApplicationNumberController.dispose();
    _sanctionAmountController.dispose();
    _processingFeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final canCreateApplication = currentUser?.canCreateApplication ?? false;
    final canEditApplication = currentUser?.canEdit ?? false;
    final canEditRequestedChanges =
        _isEditing &&
        _loadedApplication != null &&
        (currentUser?.canAccessApplications ?? false) &&
        _loadedApplication!.submittedBy == currentUser?.id &&
        _loadedApplication!.approvalStatus == ApprovalStatus.changesRequested;
    final hasAccess =
        _isEditing
            ? (canEditApplication || canEditRequestedChanges)
            : canCreateApplication;

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 64,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 16),
              Text('Access Denied', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? 'Only admin can edit applications.'
                    : 'You do not have permission to create applications.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                          _buildBankDetails(),
                          const SizedBox(height: 24),
                          _buildLoanDetails(),
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
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location / District *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required field' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _discomController,
                  decoration: const InputDecoration(
                    labelText: 'Discom *',
                    prefixIcon: Icon(Icons.electrical_services_outlined),
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

  Widget _buildBankDetails() {
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
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Bank & Settlement',
                style: AppTextStyles.heading4.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _ifscCodeController,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: _giveUpSubsidy,
            onChanged: (value) => setState(() => _giveUpSubsidy = value),
            contentPadding: EdgeInsets.zero,
            title: Text('Subsidy Opt-out', style: AppTextStyles.bodyMedium),
            subtitle: Text(
              'Enable this if the consumer does not want subsidy.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetails() {
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
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Financial & Loan',
                style: AppTextStyles.heading4.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLoanStatus,
                  decoration: const InputDecoration(
                    labelText: 'Loan Status',
                    prefixIcon: Icon(Icons.rule_folder_outlined),
                  ),
                  items:
                      ['Not Applied', 'Applied', 'Approved', 'Rejected']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLoanStatus = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _loanApplicationNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Application Number',
                    prefixIcon: Icon(Icons.tag_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _sanctionDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() => _sanctionDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Sanction Date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      _sanctionDate == null
                          ? 'Select sanction date'
                          : DateFormat('dd/MM/yyyy').format(_sanctionDate!),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            _sanctionDate == null
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sanctionAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Sanction Amount',
                    prefixIcon: Icon(Icons.currency_rupee_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
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
                  controller: _processingFeesController,
                  decoration: const InputDecoration(
                    labelText: 'Processing Fees',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
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
      final canEditApplication = currentUser?.canEdit ?? false;
      final isAdminCreate = !_isEditing && canEditApplication;
      final isResubmittingRequestedChanges =
          _isEditing &&
          _loadedApplication?.approvalStatus == ApprovalStatus.changesRequested &&
          !canEditApplication;

      final application =
          (_loadedApplication ??
                  ApplicationModel(
                    id: widget.applicationId ?? uuid.v4(),
                    applicationNumber: _generatedId,
                    state: 'Rajasthan',
                    discomName: '',
                    fullName: '',
                    gender: 'Not Specified',
                    address: '',
                    pincode: '000000',
                    consumerAccountNumber: '',
                    mobile: '',
                    district: '',
                    applicationSubmissionDate: _applicationDate,
                    circleName: 'Default',
                    divisionName: 'Default',
                    subdivisionName: 'Default',
                    sanctionedLoad: 0.0,
                    proposedCapacity: 0,
                    categoryName: _selectedCategory,
                    netEligibleCapacity: 0.0,
                    vendorName: AppConstants.companyName,
                    approvalStatus:
                        isAdminCreate
                            ? ApprovalStatus.approved
                            : ApprovalStatus.pending,
                    submittedBy: currentUser?.id,
                    approvedBy: isAdminCreate ? currentUser?.id : null,
                    approvalDate: isAdminCreate ? now : null,
                    createdAt: now,
                    updatedAt: now,
                  ))
              .copyWith(
                applicationNumber: _generatedId,
                fullName: _fullNameController.text.trim(),
                nameAsPerBill: _nameAsPerBillController.text.trim(),
                address: _addressController.text.trim(),
                district: _locationController.text.trim(),
                discomName: _discomController.text.trim(),
                consumerAccountNumber:
                    _consumerAccountNumberController.text.trim(),
                mobile: _mobileController.text.trim(),
                applicationSubmissionDate: _applicationDate,
                proposedCapacity:
                    double.tryParse(_proposedCapacityController.text.trim()) ??
                    0,
                finalAmount:
                    double.tryParse(_finalAmountController.text.trim()),
                categoryName: _selectedCategory,
                bankName: _emptyToNull(_bankNameController.text),
                ifscCode: _emptyToNull(_ifscCodeController.text)?.toUpperCase(),
                accountHolderName: _emptyToNull(_accountHolderController.text),
                accountNumber: _emptyToNull(_accountNumberController.text),
                giveUpSubsidy: _giveUpSubsidy,
                loanStatus: _selectedLoanStatus,
                loanApplicationNumber:
                    _emptyToNull(_loanApplicationNumberController.text),
                sanctionDate: _sanctionDate,
                sanctionAmount:
                    double.tryParse(_sanctionAmountController.text.trim()),
                processingFees:
                    double.tryParse(_processingFeesController.text.trim()),
                approvalStatus:
                    isAdminCreate
                        ? ApprovalStatus.approved
                        : canEditApplication
                            ? (_loadedApplication?.approvalStatus ??
                                ApprovalStatus.pending)
                            : isResubmittingRequestedChanges
                                ? ApprovalStatus.pending
                                : (_loadedApplication?.approvalStatus ??
                                    ApprovalStatus.pending),
                approvedBy:
                    isAdminCreate
                        ? currentUser?.id
                        : isResubmittingRequestedChanges
                            ? null
                            : _loadedApplication?.approvedBy,
                approvalDate:
                    isAdminCreate
                        ? now
                        : isResubmittingRequestedChanges
                            ? null
                            : _loadedApplication?.approvalDate,
                updatedAt: now,
              );

      if (_isEditing) {
        await ApplicationService.updateApplication(application);
      } else {
        await ApplicationService.createApplication(application);
      }

      ref.read(applicationsProvider.notifier).loadApplications();

      if (mounted) {
        if (_isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isResubmittingRequestedChanges
                    ? 'Application re-submitted for admin approval!'
                    : 'Application updated!',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          if (isAdminCreate) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Application created successfully.'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else {
            await _showApprovalPendingDialog();
          }
        }
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

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showApprovalPendingDialog() async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text(
              'Application will be approved by the admin before it appears in the application list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
