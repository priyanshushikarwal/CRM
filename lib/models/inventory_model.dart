import 'package:flutter/foundation.dart';

@immutable
class SolarInventoryItem {
  final String id;
  final String
  companyName; // Solar panel company name (e.g., Adani Solar, Tata Power Solar)
  final String panelModel; // Panel model name
  final double capacityKw; // Capacity in kW (e.g., 1.0, 2.0, 3.0, 5.0)
  final int totalQuantity; // Total panels in stock
  final int usedQuantity; // Panels assigned to applications
  final bool isDcr; // Domestic Content Requirement true/false
  final String? description; // Optional notes
  final DateTime createdAt;
  final DateTime updatedAt;

  const SolarInventoryItem({
    required this.id,
    required this.companyName,
    required this.panelModel,
    required this.capacityKw,
    required this.totalQuantity,
    this.usedQuantity = 0,
    this.isDcr = true,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  int get availableQuantity => totalQuantity - usedQuantity;

  bool get isAvailable => availableQuantity > 0;

  String get displayName => '$companyName - $panelModel (${capacityKw}kW)';

  factory SolarInventoryItem.fromJson(Map<String, dynamic> json) {
    return SolarInventoryItem(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      panelModel: json['panel_model'] as String,
      capacityKw: (json['capacity_kw'] as num).toDouble(),
      totalQuantity: json['total_quantity'] as int,
      usedQuantity: json['used_quantity'] as int? ?? 0,
      isDcr: json['is_dcr'] as bool? ?? true,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'panel_model': panelModel,
      'capacity_kw': capacityKw,
      'total_quantity': totalQuantity,
      'used_quantity': usedQuantity,
      'is_dcr': isDcr,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SolarInventoryItem copyWith({
    String? id,
    String? companyName,
    String? panelModel,
    double? capacityKw,
    int? totalQuantity,
    int? usedQuantity,
    bool? isDcr,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SolarInventoryItem(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      panelModel: panelModel ?? this.panelModel,
      capacityKw: capacityKw ?? this.capacityKw,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      usedQuantity: usedQuantity ?? this.usedQuantity,
      isDcr: isDcr ?? this.isDcr,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model to track which solar panel is assigned to which application
@immutable
class SolarAssignment {
  final String id;
  final String inventoryItemId;
  final String applicationId;
  final String applicationNumber;
  final String consumerName;
  final int quantityAssigned;
  final DateTime assignedAt;
  final String? notes;

  const SolarAssignment({
    required this.id,
    required this.inventoryItemId,
    required this.applicationId,
    required this.applicationNumber,
    required this.consumerName,
    required this.quantityAssigned,
    required this.assignedAt,
    this.notes,
  });

  factory SolarAssignment.fromJson(Map<String, dynamic> json) {
    return SolarAssignment(
      id: json['id'] as String,
      inventoryItemId: json['inventory_item_id'] as String,
      applicationId: json['application_id'] as String,
      applicationNumber: json['application_number'] as String,
      consumerName: json['consumer_name'] as String,
      quantityAssigned: json['quantity_assigned'] as int,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_item_id': inventoryItemId,
      'application_id': applicationId,
      'application_number': applicationNumber,
      'consumer_name': consumerName,
      'quantity_assigned': quantityAssigned,
      'assigned_at': assignedAt.toIso8601String(),
      'notes': notes,
    };
  }
}
