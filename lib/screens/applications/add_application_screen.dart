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
import '../inventory/inventory_screen.dart';

class AddApplicationScreen extends ConsumerStatefulWidget {
  final String? applicationId;

  const AddApplicationScreen({super.key, this.applicationId});

  @override
  ConsumerState<AddApplicationScreen> createState() =>
      _AddApplicationScreenState();
}

class _AddApplicationScreenState extends ConsumerState<AddApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _currentStep;
  bool _isLoading = false;
  bool _isEditing = false;

  // Controllers - Application Details
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _consumerAccountNumberController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _districtController = TextEditingController();
  final _circleNameController = TextEditingController();
  final _divisionNameController = TextEditingController();
  final _subdivisionNameController = TextEditingController();

  // Controllers - Bank Details
  final _bankNameController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankRemarksController = TextEditingController();

  // Controllers - Solar Details
  final _sanctionedLoadController = TextEditingController();
  final _proposedCapacityController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _existingCapacityController = TextEditingController();
  final _netEligibleCapacityController = TextEditingController();
  final _vendorNameController = TextEditingController();

  // Controllers - Loan Details
  final _loanApplicationNumberController = TextEditingController();
  final _sanctionAmountController = TextEditingController();
  final _processingFeesController = TextEditingController();

  // Controllers - Feasibility Details
  final _feasibilityPersonController = TextEditingController();
  final _approvedCapacityController = TextEditingController();
  final _remarksController = TextEditingController();
  final _subsidyAmountController = TextEditingController();

  // Dropdown values
  String? _selectedState;
  String? _selectedDiscom;
  String _selectedGender = 'Male';
  String _selectedCategory = 'Residential';
  String _selectedLoanStatus = 'Not Applied';
  String _selectedFeasibilityStatus = 'Pending';
  bool _giveUpSubsidy = false;

  // Dates
  DateTime _applicationDate = DateTime.now();
  DateTime? _sanctionDate;
  DateTime? _feasibilityDate;

  @override
  void initState() {
    super.initState();
    _currentStep = 0;
    _isEditing = widget.applicationId != null;

    if (_isEditing) {
      _loadApplicationData();
    } else {
      // Set default values
      _selectedState = 'Rajasthan';
      _vendorNameController.text = AppConstants.companyName;
    }
  }

  Future<void> _loadApplicationData() async {
    setState(() => _isLoading = true);

    try {
      final app = await ApplicationService.fetchApplication(
        widget.applicationId!,
      );
      if (app != null) {
        // Populate all fields
        _fullNameController.text = app.fullName;
        _addressController.text = app.address;
        _pincodeController.text = app.pincode;
        _consumerAccountNumberController.text = app.consumerAccountNumber;
        _mobileController.text = app.mobile;
        _emailController.text = app.email ?? '';
        _districtController.text = app.district;
        _circleNameController.text = app.circleName;
        _divisionNameController.text = app.divisionName;
        _subdivisionNameController.text = app.subdivisionName;

        _bankNameController.text = app.bankName ?? '';
        _ifscCodeController.text = app.ifscCode ?? '';
        _accountHolderNameController.text = app.accountHolderName ?? '';
        _accountNumberController.text = app.accountNumber ?? '';
        _bankRemarksController.text = app.bankRemarks ?? '';

        _sanctionedLoadController.text = app.sanctionedLoad.toString();
        _proposedCapacityController.text = app.proposedCapacity.toString();
        _latitudeController.text = app.latitude?.toString() ?? '';
        _longitudeController.text = app.longitude?.toString() ?? '';
        _existingCapacityController.text =
            app.existingInstalledCapacity.toString();
        _netEligibleCapacityController.text =
            app.netEligibleCapacity.toString();
        _vendorNameController.text = app.vendorName;

        _loanApplicationNumberController.text = app.loanApplicationNumber ?? '';
        _sanctionAmountController.text = app.sanctionAmount?.toString() ?? '';
        _processingFeesController.text = app.processingFees?.toString() ?? '';

        _feasibilityPersonController.text = app.feasibilityPerson ?? '';
        _approvedCapacityController.text =
            app.approvedCapacity?.toString() ?? '';
        _remarksController.text = app.remarks ?? '';
        _subsidyAmountController.text = app.subsidyAmount?.toString() ?? '';

        _selectedState = app.state;
        _selectedDiscom = app.discomName;
        _selectedGender = app.gender;
        _selectedCategory = app.categoryName;
        _selectedLoanStatus = app.loanStatus;
        _selectedFeasibilityStatus = app.feasibilityStatus;
        _giveUpSubsidy = app.giveUpSubsidy;

        _applicationDate = app.applicationSubmissionDate;
        _sanctionDate = app.sanctionDate;
        _feasibilityDate = app.feasibilityDate;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading application: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _fullNameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _consumerAccountNumberController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _circleNameController.dispose();
    _divisionNameController.dispose();
    _subdivisionNameController.dispose();
    _bankNameController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _bankRemarksController.dispose();
    _sanctionedLoadController.dispose();
    _proposedCapacityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _existingCapacityController.dispose();
    _netEligibleCapacityController.dispose();
    _vendorNameController.dispose();
    _loanApplicationNumberController.dispose();
    _sanctionAmountController.dispose();
    _processingFeesController.dispose();
    _feasibilityPersonController.dispose();
    _approvedCapacityController.dispose();
    _remarksController.dispose();
    _subsidyAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body:
          _isLoading
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
                            _buildStepIndicator(),
                            const SizedBox(height: 24),
                            _buildCurrentStepContent(),
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
                  _isEditing ? 'Edit Application' : 'Add New Application',
                  style: AppTextStyles.heading3,
                ),
                Text(
                  'Fill in all the required details',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Step ${_currentStep + 1} of 5',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      'Application',
      'Bank Details',
      'Solar Details',
      'Loan Details',
      'Feasibility',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children:
            steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  isCompleted
                                      ? AppTheme.successColor
                                      : isActive
                                      ? AppTheme.primaryColor
                                      : AppTheme.borderColor,
                              shape: BoxShape.circle,
                            ),
                            child:
                                isCompleted
                                    ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                    : Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color:
                                              isActive
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step,
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  isActive || isCompleted
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color:
                              isCompleted
                                  ? AppTheme.successColor
                                  : AppTheme.borderColor,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildApplicationDetailsStep();
      case 1:
        return _buildBankDetailsStep();
      case 2:
        return _buildSolarDetailsStep();
      case 3:
        return _buildLoanDetailsStep();
      case 4:
        return _buildFeasibilityDetailsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildApplicationDetailsStep() {
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
          _buildSectionHeader('Application Details', Icons.description_rounded),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items:
                      AppConstants.indianStates.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedState = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a state';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter district';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name of Discom *',
                    prefixIcon: const Icon(Icons.business_outlined),
                    hintText: 'e.g., Ajmer Vidyut Vitran Nigam Ltd.',
                  ),
                  initialValue: _selectedDiscom,
                  onChanged: (value) => _selectedDiscom = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Discom name';
                    }
                    return null;
                  },
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
                    labelText: 'Full Name of Premises Owner *',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items:
                      AppConstants.genderOptions.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGender = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address for Installation *',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode *',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Please enter valid 6-digit pincode';
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
                    labelText: 'Consumer Account Number (CA No.) *',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter CA number';
                    }
                    return null;
                  },
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
                      return 'Please enter valid 10-digit mobile';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _circleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Circle Name *',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter circle name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _divisionNameController,
                  decoration: const InputDecoration(
                    labelText: 'Division Name *',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter division name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _subdivisionNameController,
                  decoration: const InputDecoration(
                    labelText: 'Subdivision Name *',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter subdivision name';
                    }
                    return null;
                  },
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
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _applicationDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Application Submission Date *',
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
        ],
      ),
    );
  }

  Widget _buildBankDetailsStep() {
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
          _buildSectionHeader(
            'Bank & Scheme Details',
            Icons.account_balance_rounded,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scheme Name', style: AppTextStyles.caption),
                      Text(
                        'PM Surya Ghar: Muft Bijli Yojana',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                    hintText: 'e.g., State Bank of India',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _ifscCodeController,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    prefixIcon: Icon(Icons.code_outlined),
                    hintText: 'e.g., SBIN0001234',
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
                  controller: _accountHolderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bankRemarksController,
            decoration: const InputDecoration(
              labelText: 'Bank Remarks',
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: _giveUpSubsidy,
            onChanged: (value) {
              setState(() => _giveUpSubsidy = value);
            },
            title: Text('Give Up Subsidy', style: AppTextStyles.bodyMedium),
            subtitle: Text(
              'Select if the consumer does not want to claim subsidy',
              style: AppTextStyles.caption,
            ),
            tileColor: AppTheme.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarDetailsStep() {
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
          _buildSectionHeader(
            'Solar Rooftop Details',
            Icons.solar_power_rounded,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sanctionedLoadController,
                  decoration: const InputDecoration(
                    labelText: 'Sanctioned Load (kW) *',
                    prefixIcon: Icon(Icons.electrical_services_outlined),
                    suffixText: 'kW',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter sanctioned load';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _proposedCapacityController,
                  decoration: const InputDecoration(
                    labelText: 'Proposed Capacity (kWp) *',
                    prefixIcon: Icon(Icons.solar_power_outlined),
                    suffixText: 'kWp',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter proposed capacity';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    prefixIcon: Icon(Icons.my_location_outlined),
                    hintText: 'e.g., 27.560533',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final lat = double.tryParse(value);
                      if (lat == null) {
                        return 'Enter a valid number';
                      }
                      if (lat < -90 || lat > 90) {
                        return 'Latitude must be between -90 and 90';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    prefixIcon: Icon(Icons.my_location_outlined),
                    hintText: 'e.g., 75.714012',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final lng = double.tryParse(value);
                      if (lng == null) {
                        return 'Enter a valid number';
                      }
                      if (lng < -180 || lng > 180) {
                        return 'Longitude must be between -180 and 180';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items:
                      AppConstants.categoryTypes.map((category) {
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
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _existingCapacityController,
                  decoration: const InputDecoration(
                    labelText: 'Existing Installed Capacity (kWp)',
                    prefixIcon: Icon(Icons.history_outlined),
                    suffixText: 'kWp',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _netEligibleCapacityController,
                  decoration: const InputDecoration(
                    labelText: 'Net Eligible Capacity (kWp) *',
                    prefixIcon: Icon(Icons.check_circle_outline),
                    suffixText: 'kWp',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter net eligible capacity';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _vendorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name of Vendor *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vendor name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ── Solar Panel from Inventory ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.solar_power_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solar Panel from Inventory',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Select & assign a solar panel to this application',
                          style: AppTextStyles.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isEditing && widget.applicationId != null)
                  SolarPanelPickerWidget(
                    applicationId: widget.applicationId!,
                    applicationNumber:
                        ref
                            .read(selectedApplicationProvider)
                            ?.applicationNumber ??
                        '',
                    consumerName:
                        _fullNameController.text.isNotEmpty
                            ? _fullNameController.text
                            : 'Consumer',
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.warningColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Solar panel assignment is available after saving the application. Save first, then edit to assign panels from inventory.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailsStep() {
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
          _buildSectionHeader('Loan Details', Icons.payments_rounded),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLoanStatus,
                  decoration: const InputDecoration(
                    labelText: 'Current Status of Loan',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  items:
                      AppConstants.loanStatusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedLoanStatus = value!);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _loanApplicationNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Application Number',
                    prefixIcon: Icon(Icons.numbers_outlined),
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
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _sanctionDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Sanction Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _sanctionDate != null
                          ? DateFormat('dd/MM/yyyy').format(_sanctionDate!)
                          : 'Not Available',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sanctionAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Sanction Amount (Rs.)',
                    prefixIcon: Icon(Icons.currency_rupee_outlined),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
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
                    labelText: 'Processing Fees (Rs.)',
                    prefixIcon: Icon(Icons.receipt_outlined),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeasibilityDetailsStep() {
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
          _buildSectionHeader(
            'Feasibility & Subsidy Details',
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _feasibilityDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _feasibilityDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Feasibility Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _feasibilityDate != null
                          ? DateFormat('dd/MM/yyyy').format(_feasibilityDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFeasibilityStatus,
                  decoration: const InputDecoration(
                    labelText: 'Feasibility Status',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  items:
                      AppConstants.feasibilityStatusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedFeasibilityStatus = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _feasibilityPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Feasibility Person',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _approvedCapacityController,
                  decoration: const InputDecoration(
                    labelText: 'Approved Capacity (kWp)',
                    prefixIcon: Icon(Icons.check_circle_outline),
                    suffixText: 'kWp',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _subsidyAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Subsidy Amount (Rs.)',
                    prefixIcon: Icon(Icons.currency_rupee_outlined),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: AppTextStyles.heading4.copyWith(color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _currentStep--);
            },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Previous'),
          )
        else
          const SizedBox(),
        Row(
          children: [
            TextButton(
              onPressed: () => context.go('/applications'),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            if (_currentStep < 4)
              ElevatedButton.icon(
                onPressed: () {
                  if (_validateCurrentStep()) {
                    setState(() => _currentStep++);
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next'),
              )
            else ...[
              // Save as Draft button
              OutlinedButton.icon(
                onPressed:
                    _isLoading ? null : () => _handleSubmit(asDraft: true),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save as Draft'),
              ),
              const SizedBox(width: 12),
              // Submit for Approval button
              ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : () => _handleSubmit(asDraft: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send_rounded),
                label: Text(
                  _isEditing ? 'Update & Submit' : 'Submit for Approval',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  bool _validateCurrentStep() {
    // Basic validation for required fields
    switch (_currentStep) {
      case 0:
        if (_selectedState == null ||
            _fullNameController.text.isEmpty ||
            _addressController.text.isEmpty ||
            _pincodeController.text.length != 6 ||
            _consumerAccountNumberController.text.isEmpty ||
            _mobileController.text.length != 10 ||
            _districtController.text.isEmpty ||
            _circleNameController.text.isEmpty ||
            _divisionNameController.text.isEmpty ||
            _subdivisionNameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all required fields'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return false;
        }
        break;
      case 2:
        if (_sanctionedLoadController.text.isEmpty ||
            _proposedCapacityController.text.isEmpty ||
            _netEligibleCapacityController.text.isEmpty ||
            _vendorNameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all required solar details'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _handleSubmit({bool asDraft = false}) async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final uuid = const Uuid();
      final currentUser = ref.read(currentUserProvider).value;

      final application = ApplicationModel(
        id: widget.applicationId ?? uuid.v4(),
        applicationNumber:
            widget.applicationId != null
                ? '' // Will be preserved from existing
                : ApplicationService.generateApplicationNumber(
                  state: _selectedState!,
                  scheme: 'RJAJY',
                ),
        state: _selectedState!,
        discomName: _selectedDiscom ?? '',
        fullName: _fullNameController.text,
        gender: _selectedGender,
        address: _addressController.text,
        pincode: _pincodeController.text,
        consumerAccountNumber: _consumerAccountNumberController.text,
        mobile: _mobileController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        district: _districtController.text,
        applicationSubmissionDate: _applicationDate,
        circleName: _circleNameController.text,
        divisionName: _divisionNameController.text,
        subdivisionName: _subdivisionNameController.text,
        bankName:
            _bankNameController.text.isNotEmpty
                ? _bankNameController.text
                : null,
        ifscCode:
            _ifscCodeController.text.isNotEmpty
                ? _ifscCodeController.text
                : null,
        accountHolderName:
            _accountHolderNameController.text.isNotEmpty
                ? _accountHolderNameController.text
                : null,
        accountNumber:
            _accountNumberController.text.isNotEmpty
                ? _accountNumberController.text
                : null,
        bankRemarks:
            _bankRemarksController.text.isNotEmpty
                ? _bankRemarksController.text
                : null,
        giveUpSubsidy: _giveUpSubsidy,
        sanctionedLoad: double.tryParse(_sanctionedLoadController.text) ?? 0,
        proposedCapacity:
            double.tryParse(_proposedCapacityController.text) ?? 0,
        latitude: double.tryParse(_latitudeController.text),
        longitude: double.tryParse(_longitudeController.text),
        categoryName: _selectedCategory,
        existingInstalledCapacity:
            double.tryParse(_existingCapacityController.text) ?? 0,
        netEligibleCapacity:
            double.tryParse(_netEligibleCapacityController.text) ?? 0,
        vendorName: _vendorNameController.text,
        loanStatus: _selectedLoanStatus,
        loanApplicationNumber:
            _loanApplicationNumberController.text.isNotEmpty
                ? _loanApplicationNumberController.text
                : null,
        sanctionDate: _sanctionDate,
        sanctionAmount: double.tryParse(_sanctionAmountController.text),
        processingFees: double.tryParse(_processingFeesController.text),
        feasibilityDate: _feasibilityDate,
        feasibilityStatus: _selectedFeasibilityStatus,
        feasibilityPerson:
            _feasibilityPersonController.text.isNotEmpty
                ? _feasibilityPersonController.text
                : null,
        approvedCapacity: double.tryParse(_approvedCapacityController.text),
        remarks:
            _remarksController.text.isNotEmpty ? _remarksController.text : null,
        subsidyAmount: double.tryParse(_subsidyAmountController.text),
        // Approval workflow fields
        approvalStatus: asDraft ? ApprovalStatus.draft : ApprovalStatus.pending,
        submittedBy: asDraft ? null : currentUser?.id,
        createdAt: now,
        updatedAt: now,
      );

      if (_isEditing) {
        await ApplicationService.updateApplication(application);
      } else {
        await ApplicationService.createApplication(application);
      }

      // Refresh applications list
      ref.read(applicationsProvider.notifier).loadApplications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft
                  ? 'Application saved as draft!'
                  : 'Application submitted for approval!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/applications');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
