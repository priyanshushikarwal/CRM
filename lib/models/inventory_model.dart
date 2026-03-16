import 'package:flutter/foundation.dart';

enum InventoryItemType { panel, inverter, meter, battery, other }

@immutable
class InventoryInvoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String partyName;
  final double? price;
  final String? receivedBy;
  final InventoryItemType itemType;
  final DateTime createdAt;

  const InventoryInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.partyName,
    this.price,
    this.receivedBy,
    required this.itemType,
    required this.createdAt,
  });

  factory InventoryInvoice.fromJson(Map<String, dynamic> json) {
    return InventoryInvoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      partyName: json['party_name'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      receivedBy: json['received_by'] as String?,
      itemType: InventoryItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['item_type'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'party_name': partyName,
      'price': price,
      'received_by': receivedBy,
      'item_type': itemType.toString().split('.').last,
    };
  }
}

@immutable
class PanelItem {
  final String id;
  final String? invoiceId;
  final String serialNumber;
  final String brand;
  final int wattCapacity;
  final String panelType; // DCR or NDCR
  final String status; // available or allotted
  final DateTime createdAt;

  const PanelItem({
    required this.id,
    this.invoiceId,
    required this.serialNumber,
    required this.brand,
    required this.wattCapacity,
    required this.panelType,
    required this.status,
    required this.createdAt,
  });

  factory PanelItem.fromJson(Map<String, dynamic> json) {
    return PanelItem(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String?,
      serialNumber: json['serial_number'] as String,
      brand: json['brand'] as String,
      wattCapacity: json['watt_capacity'] as int,
      panelType: json['panel_type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'serial_number': serialNumber,
      'brand': brand,
      'watt_capacity': wattCapacity,
      'panel_type': panelType,
      'status': status,
    };
  }
}

@immutable
class InverterItem {
  final String id;
  final String? invoiceId;
  final String serialNumber;
  final String brand;
  final double capacityKw;
  final String inverterType; // On Grid, Hybrid, Off Grid
  final String status;
  final DateTime createdAt;

  const InverterItem({
    required this.id,
    this.invoiceId,
    required this.serialNumber,
    required this.brand,
    required this.capacityKw,
    required this.inverterType,
    required this.status,
    required this.createdAt,
  });

  factory InverterItem.fromJson(Map<String, dynamic> json) {
    return InverterItem(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String?,
      serialNumber: json['serial_number'] as String,
      brand: json['brand'] as String,
      capacityKw: (json['capacity_kw'] as num).toDouble(),
      inverterType: json['inverter_type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'serial_number': serialNumber,
      'brand': brand,
      'capacity_kw': capacityKw,
      'inverter_type': inverterType,
      'status': status,
    };
  }
}

@immutable
class MeterItem {
  final String id;
  final String? invoiceId;
  final String serialNumber;
  final String brand;
  final String meterCategory; // Net Meter, Solar Meter
  final String meterType; // Normal, LTCT, HTCT
  final String meterPhase; // Single Phase, Three Phase
  final String status;
  final DateTime createdAt;

  const MeterItem({
    required this.id,
    this.invoiceId,
    required this.serialNumber,
    required this.brand,
    required this.meterCategory,
    required this.meterType,
    required this.meterPhase,
    required this.status,
    required this.createdAt,
  });

  factory MeterItem.fromJson(Map<String, dynamic> json) {
    return MeterItem(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String?,
      serialNumber: json['serial_number'] as String,
      brand: json['brand'] as String,
      meterCategory: json['meter_category'] as String,
      meterType: json['meter_type'] as String,
      meterPhase: json['meter_phase'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'serial_number': serialNumber,
      'brand': brand,
      'meter_category': meterCategory,
      'meter_type': meterType,
      'meter_phase': meterPhase,
      'status': status,
    };
  }
}

@immutable
class InventoryAllotment {
  final String id;
  final String itemId;
  final InventoryItemType itemType;
  final String customerName;
  final String? customerAddress;
  final String? customerMobile;
  final String? applicationId;
  final String? handoverBy;
  final DateTime handoverDate;
  final DateTime createdAt;

  const InventoryAllotment({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.customerName,
    this.customerAddress,
    this.customerMobile,
    this.applicationId,
    this.handoverBy,
    required this.handoverDate,
    required this.createdAt,
  });

  factory InventoryAllotment.fromJson(Map<String, dynamic> json) {
    return InventoryAllotment(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      itemType: InventoryItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['item_type'],
      ),
      customerName: json['customer_name'] as String,
      customerAddress: json['customer_address'] as String?,
      customerMobile: json['customer_mobile'] as String?,
      applicationId: json['application_id'] as String?,
      handoverBy: json['handover_by'] as String?,
      handoverDate: DateTime.parse(json['handover_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_type': itemType.toString().split('.').last,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'customer_mobile': customerMobile,
      'application_id': applicationId,
      'handover_by': handoverBy,
      'handover_date': handoverDate.toIso8601String(),
    };
  }
}
