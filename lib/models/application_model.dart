import 'package:flutter/foundation.dart';

enum ApplicationStatus {
  applicationReceived,
  documentsVerified,
  siteSurveyPending,
  siteSurveyCompleted,
  solarDemandPending,
  solarDemandDeposit,
  meterTested,
  installationScheduled,
  installationCompleted,
  subsidyProcess,
  completeWorkDone,
}

enum StageStatus { pending, inProgress, completed, rejected }

enum ApprovalStatus {
  draft, // Employee is still working on it
  pending, // Submitted for admin review
  approved, // Admin approved
  rejected, // Admin rejected
  changesRequested, // Admin requested changes
}

@immutable
class ApplicationModel {
  final String id;
  final String applicationNumber;
  final String? userId;

  final String state;
  final String discomName;
  final String fullName;
  final String gender;
  final String address;
  final String pincode;
  final String consumerAccountNumber;
  final String mobile;
  final String? email;
  final String district;
  final String? plantThrough;
  final String? connectionType;
  final double? electricityBillLoad;
  final DateTime applicationSubmissionDate;
  final String? scStStatus;
  final String circleName;
  final String divisionName;
  final String subdivisionName;
  final String schemeName;
  final String? bankName;
  final String? ifscCode;
  final String? accountHolderName;
  final String? accountNumber;
  final String? bankRemarks;
  final bool giveUpSubsidy;

  final double sanctionedLoad;
  final double proposedCapacity;
  final double? latitude;
  final double? longitude;
  final String categoryName;
  final double existingInstalledCapacity;
  final double netEligibleCapacity;
  final String vendorName;

  final String? nameAsPerBill;
  final double? finalAmount;

  final String loanStatus;
  final String? loanApplicationNumber;
  final DateTime? sanctionDate;
  final double? sanctionAmount;
  final double? processingFees;

  final DateTime? feasibilityDate;
  final String feasibilityStatus;
  final String? feasibilityPerson;
  final double? approvedCapacity;
  final String? remarks;

  final double? subsidyAmount;

  final ApplicationStatus currentStatus;
  final List<StatusHistoryItem> statusHistory;

  final ApprovalStatus approvalStatus;
  final String? submittedBy; // User ID of employee who submitted
  final String? approvedBy; // User ID of admin who approved/rejected
  final DateTime? approvalDate;
  final String? approvalRemarks; // Comments from admin

  final DateTime createdAt;
  final DateTime updatedAt;

  const ApplicationModel({
    required this.id,
    required this.applicationNumber,
    this.userId,
    required this.state,
    required this.discomName,
    required this.fullName,
    required this.gender,
    required this.address,
    required this.pincode,
    required this.consumerAccountNumber,
    required this.mobile,
    this.email,
    required this.district,
    this.plantThrough,
    this.connectionType,
    this.electricityBillLoad,
    required this.applicationSubmissionDate,
    this.scStStatus,
    required this.circleName,
    required this.divisionName,
    required this.subdivisionName,
    this.schemeName = 'PM Surya Ghar: Muft Bijli Yojana',
    this.bankName,
    this.ifscCode,
    this.accountHolderName,
    this.accountNumber,
    this.bankRemarks,
    this.giveUpSubsidy = false,
    required this.sanctionedLoad,
    required this.proposedCapacity,
    this.latitude,
    this.longitude,
    required this.categoryName,
    this.existingInstalledCapacity = 0,
    required this.netEligibleCapacity,
    required this.vendorName,
    this.nameAsPerBill,
    this.finalAmount,
    this.loanStatus = 'Not Applied',
    this.loanApplicationNumber,
    this.sanctionDate,
    this.sanctionAmount,
    this.processingFees,
    this.feasibilityDate,
    this.feasibilityStatus = 'Pending',
    this.feasibilityPerson,
    this.approvedCapacity,
    this.remarks,
    this.subsidyAmount,
    this.currentStatus = ApplicationStatus.applicationReceived,
    this.statusHistory = const [],
    this.approvalStatus = ApprovalStatus.draft,
    this.submittedBy,
    this.approvedBy,
    this.approvalDate,
    this.approvalRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] as String,
      applicationNumber: json['application_number'] as String,
      userId: json['user_id'] as String?,
      state: json['state'] as String,
      discomName: json['discom_name'] as String,
      fullName: json['full_name'] as String,
      gender: json['gender'] as String,
      address: json['address'] as String,
      pincode: json['pincode'] as String,
      consumerAccountNumber: json['consumer_account_number'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String?,
      district: json['district'] as String,
      plantThrough: json['plant_through'] as String?,
      connectionType: json['connection_type'] as String?,
      electricityBillLoad: (json['electricity_bill_load'] as num?)?.toDouble(),
      applicationSubmissionDate: DateTime.parse(
        json['application_submission_date'] as String,
      ),
      scStStatus: json['sc_st_status'] as String?,
      circleName: json['circle_name'] as String,
      divisionName: json['division_name'] as String,
      subdivisionName: json['subdivision_name'] as String,
      schemeName:
          json['scheme_name'] as String? ?? 'PM Surya Ghar: Muft Bijli Yojana',
      bankName: json['bank_name'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      accountHolderName: json['account_holder_name'] as String?,
      accountNumber: json['account_number'] as String?,
      bankRemarks: json['bank_remarks'] as String?,
      giveUpSubsidy: json['give_up_subsidy'] as bool? ?? false,
      sanctionedLoad: (json['sanctioned_load'] as num).toDouble(),
      proposedCapacity: (json['proposed_capacity'] as num).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      categoryName: json['category_name'] as String,
      existingInstalledCapacity:
          (json['existing_installed_capacity'] as num?)?.toDouble() ?? 0,
      netEligibleCapacity: (json['net_eligible_capacity'] as num).toDouble(),
      vendorName: json['vendor_name'] as String,
      nameAsPerBill: json['name_as_per_bill'] as String?,
      finalAmount: (json['final_amount'] as num?)?.toDouble(),
      loanStatus: json['loan_status'] as String? ?? 'Not Applied',
      loanApplicationNumber: json['loan_application_number'] as String?,
      sanctionDate:
          json['sanction_date'] != null
              ? DateTime.parse(json['sanction_date'] as String)
              : null,
      sanctionAmount: (json['sanction_amount'] as num?)?.toDouble(),
      processingFees: (json['processing_fees'] as num?)?.toDouble(),
      feasibilityDate:
          json['feasibility_date'] != null
              ? DateTime.parse(json['feasibility_date'] as String)
              : null,
      feasibilityStatus: json['feasibility_status'] as String? ?? 'Pending',
      feasibilityPerson: json['feasibility_person'] as String?,
      approvedCapacity: (json['approved_capacity'] as num?)?.toDouble(),
      remarks: json['remarks'] as String?,
      subsidyAmount: (json['subsidy_amount'] as num?)?.toDouble(),
      currentStatus: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['current_status'],
        orElse: () => ApplicationStatus.applicationReceived,
      ),
      statusHistory:
          (json['status_history'] as List<dynamic>?)
              ?.map(
                (e) => StatusHistoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['approval_status'],
        orElse: () => ApprovalStatus.draft,
      ),
      submittedBy: json['submitted_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvalDate:
          json['approval_date'] != null
              ? DateTime.parse(json['approval_date'] as String)
              : null,
      approvalRemarks: json['approval_remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_number': applicationNumber,
      'user_id': userId,
      'state': state,
      'discom_name': discomName,
      'full_name': fullName,
      'gender': gender,
      'address': address,
      'pincode': pincode,
      'consumer_account_number': consumerAccountNumber,
      'mobile': mobile,
      'email': email,
      'district': district,
      'plant_through': plantThrough,
      'connection_type': connectionType,
      'electricity_bill_load': electricityBillLoad,
      'application_submission_date':
          applicationSubmissionDate.toIso8601String(),
      'sc_st_status': scStStatus,
      'circle_name': circleName,
      'division_name': divisionName,
      'subdivision_name': subdivisionName,
      'scheme_name': schemeName,
      'bank_name': bankName,
      'ifsc_code': ifscCode,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'bank_remarks': bankRemarks,
      'give_up_subsidy': giveUpSubsidy,
      'sanctioned_load': sanctionedLoad,
      'proposed_capacity': proposedCapacity,
      'latitude': latitude,
      'longitude': longitude,
      'category_name': categoryName,
      'existing_installed_capacity': existingInstalledCapacity,
      'net_eligible_capacity': netEligibleCapacity,
      'vendor_name': vendorName,
      'name_as_per_bill': nameAsPerBill,
      'final_amount': finalAmount,
      'loan_status': loanStatus,
      'loan_application_number': loanApplicationNumber,
      'sanction_date': sanctionDate?.toIso8601String(),
      'sanction_amount': sanctionAmount,
      'processing_fees': processingFees,
      'feasibility_date': feasibilityDate?.toIso8601String(),
      'feasibility_status': feasibilityStatus,
      'feasibility_person': feasibilityPerson,
      'approved_capacity': approvedCapacity,
      'remarks': remarks,
      'subsidy_amount': subsidyAmount,
      'current_status': currentStatus.name,
      'status_history': statusHistory.map((h) => h.toJson()).toList(),
      'approval_status': approvalStatus.name,
      'submitted_by': submittedBy,
      'approved_by': approvedBy,
      'approval_date': approvalDate?.toIso8601String(),
      'approval_remarks': approvalRemarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? applicationNumber,
    String? userId,
    String? state,
    String? discomName,
    String? fullName,
    String? gender,
    String? address,
    String? pincode,
    String? consumerAccountNumber,
    String? mobile,
    String? email,
    String? district,
    String? plantThrough,
    String? connectionType,
    double? electricityBillLoad,
    DateTime? applicationSubmissionDate,
    String? scStStatus,
    String? circleName,
    String? divisionName,
    String? subdivisionName,
    String? schemeName,
    String? bankName,
    String? ifscCode,
    String? accountHolderName,
    String? accountNumber,
    String? bankRemarks,
    bool? giveUpSubsidy,
    double? sanctionedLoad,
    double? proposedCapacity,
    double? latitude,
    double? longitude,
    String? categoryName,
    double? existingInstalledCapacity,
    double? netEligibleCapacity,
    String? vendorName,
    String? nameAsPerBill,
    double? finalAmount,
    String? loanStatus,
    String? loanApplicationNumber,
    DateTime? sanctionDate,
    double? sanctionAmount,
    double? processingFees,
    DateTime? feasibilityDate,
    String? feasibilityStatus,
    String? feasibilityPerson,
    double? approvedCapacity,
    String? remarks,
    double? subsidyAmount,
    ApplicationStatus? currentStatus,
    List<StatusHistoryItem>? statusHistory,
    ApprovalStatus? approvalStatus,
    String? submittedBy,
    String? approvedBy,
    DateTime? approvalDate,
    String? approvalRemarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      applicationNumber: applicationNumber ?? this.applicationNumber,
      userId: userId ?? this.userId,
      state: state ?? this.state,
      discomName: discomName ?? this.discomName,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      consumerAccountNumber:
          consumerAccountNumber ?? this.consumerAccountNumber,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      district: district ?? this.district,
      plantThrough: plantThrough ?? this.plantThrough,
      connectionType: connectionType ?? this.connectionType,
      electricityBillLoad: electricityBillLoad ?? this.electricityBillLoad,
      applicationSubmissionDate:
          applicationSubmissionDate ?? this.applicationSubmissionDate,
      scStStatus: scStStatus ?? this.scStStatus,
      circleName: circleName ?? this.circleName,
      divisionName: divisionName ?? this.divisionName,
      subdivisionName: subdivisionName ?? this.subdivisionName,
      schemeName: schemeName ?? this.schemeName,
      bankName: bankName ?? this.bankName,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankRemarks: bankRemarks ?? this.bankRemarks,
      giveUpSubsidy: giveUpSubsidy ?? this.giveUpSubsidy,
      sanctionedLoad: sanctionedLoad ?? this.sanctionedLoad,
      proposedCapacity: proposedCapacity ?? this.proposedCapacity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categoryName: categoryName ?? this.categoryName,
      existingInstalledCapacity:
          existingInstalledCapacity ?? this.existingInstalledCapacity,
      netEligibleCapacity: netEligibleCapacity ?? this.netEligibleCapacity,
      vendorName: vendorName ?? this.vendorName,
      nameAsPerBill: nameAsPerBill ?? this.nameAsPerBill,
      finalAmount: finalAmount ?? this.finalAmount,
      loanStatus: loanStatus ?? this.loanStatus,
      loanApplicationNumber:
          loanApplicationNumber ?? this.loanApplicationNumber,
      sanctionDate: sanctionDate ?? this.sanctionDate,
      sanctionAmount: sanctionAmount ?? this.sanctionAmount,
      processingFees: processingFees ?? this.processingFees,
      feasibilityDate: feasibilityDate ?? this.feasibilityDate,
      feasibilityStatus: feasibilityStatus ?? this.feasibilityStatus,
      feasibilityPerson: feasibilityPerson ?? this.feasibilityPerson,
      approvedCapacity: approvedCapacity ?? this.approvedCapacity,
      remarks: remarks ?? this.remarks,
      subsidyAmount: subsidyAmount ?? this.subsidyAmount,
      currentStatus: currentStatus ?? this.currentStatus,
      statusHistory: statusHistory ?? this.statusHistory,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      submittedBy: submittedBy ?? this.submittedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvalDate: approvalDate ?? this.approvalDate,
      approvalRemarks: approvalRemarks ?? this.approvalRemarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusDisplayName {
    switch (currentStatus) {
      case ApplicationStatus.applicationReceived:
        return 'Application Received';
      case ApplicationStatus.documentsVerified:
        return 'Documents Verified';
      case ApplicationStatus.siteSurveyPending:
        return 'Site Survey Pending';
      case ApplicationStatus.siteSurveyCompleted:
        return 'Site Survey Completed';
      case ApplicationStatus.solarDemandPending:
        return 'Solar Demand Pending';
      case ApplicationStatus.solarDemandDeposit:
        return 'Solar Demand Deposit';
      case ApplicationStatus.meterTested:
        return 'Meter Tested';
      case ApplicationStatus.installationScheduled:
        return 'Installation Scheduled';
      case ApplicationStatus.installationCompleted:
        return 'Installation Completed';
      case ApplicationStatus.subsidyProcess:
        return 'Subsidy Process';
      case ApplicationStatus.completeWorkDone:
        return 'Complete Work Done';
    }
  }

  int get statusIndex => currentStatus.index;

  double get progressPercentage =>
      (statusIndex + 1) / ApplicationStatus.values.length * 100;

  String get approvalStatusDisplayName {
    switch (approvalStatus) {
      case ApprovalStatus.draft:
        return 'Draft';
      case ApprovalStatus.pending:
        return 'Pending Approval';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
      case ApprovalStatus.changesRequested:
        return 'Changes Requested';
    }
  }

  bool get isPendingApproval => approvalStatus == ApprovalStatus.pending;
  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get needsChanges => approvalStatus == ApprovalStatus.changesRequested;
  bool get isDraft => approvalStatus == ApprovalStatus.draft;
}

@immutable
class StatusHistoryItem {
  final String id;
  final ApplicationStatus status;
  final StageStatus stageStatus;
  final DateTime timestamp;
  final String? remarks;
  final String? updatedBy;

  const StatusHistoryItem({
    required this.id,
    required this.status,
    required this.stageStatus,
    required this.timestamp,
    this.remarks,
    this.updatedBy,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      id: json['id'] as String,
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.applicationReceived,
      ),
      stageStatus: StageStatus.values.firstWhere(
        (e) => e.name == json['stage_status'],
        orElse: () => StageStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      remarks: json['remarks'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'stage_status': stageStatus.name,
      'timestamp': timestamp.toIso8601String(),
      'remarks': remarks,
      'updated_by': updatedBy,
    };
  }
}
