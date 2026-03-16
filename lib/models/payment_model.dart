import 'package:flutter/foundation.dart';

enum PaymentMode { cash, phonePe, bankTransfer }

enum PaymentType { advance, partial, final_payment }

@immutable
class PaymentModel {
  final String id;
  final String applicationId;
  final double amount;
  final PaymentMode paymentMode;
  final PaymentType paymentType;
  final String? transactionNumber;
  final DateTime paymentDate;
  final String? remarks;
  final String? collectedBy;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.applicationId,
    required this.amount,
    required this.paymentMode,
    required this.paymentType,
    this.transactionNumber,
    required this.paymentDate,
    this.remarks,
    this.collectedBy,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      applicationId: json['application_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == (json['payment_mode'] as String),
        orElse: () => PaymentMode.cash,
      ),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == (json['payment_type'] as String),
        orElse: () => PaymentType.partial,
      ),
      transactionNumber: json['transaction_number'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      remarks: json['remarks'] as String?,
      collectedBy: json['collected_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'amount': amount,
      'payment_mode': paymentMode.name,
      'payment_type': paymentType.name,
      'transaction_number': transactionNumber,
      'payment_date': paymentDate.toIso8601String(),
      'remarks': remarks,
      'collected_by': collectedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? applicationId,
    double? amount,
    PaymentMode? paymentMode,
    PaymentType? paymentType,
    String? transactionNumber,
    DateTime? paymentDate,
    String? remarks,
    String? collectedBy,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentType: paymentType ?? this.paymentType,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      remarks: remarks ?? this.remarks,
      collectedBy: collectedBy ?? this.collectedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
