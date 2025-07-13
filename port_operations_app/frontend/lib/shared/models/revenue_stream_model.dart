import 'package:json_annotation/json_annotation.dart';

part 'revenue_stream_model.g.dart';

@JsonSerializable()
class RevenueStream {
  final int id;
  final int operation;
  @JsonKey(name: 'operation_name')
  final String operationName;
  final String date;
  final String party;
  @JsonKey(name: 'service_type')
  final int serviceType;
  @JsonKey(name: 'service_type_name')
  final String? serviceTypeName;
  @JsonKey(name: 'service_type_code')
  final String? serviceTypeCode;
  @JsonKey(name: 'unit_type')
  final int unitType;
  @JsonKey(name: 'unit_type_name')
  final String? unitTypeName;
  @JsonKey(name: 'unit_type_code')
  final String? unitTypeCode;
  final String quantity;
  final String rate;
  final String? amount;
  @JsonKey(name: 'bill_no')
  final String? billNo;
  final String? remarks;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String? createdByName;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  RevenueStream({
    required this.id,
    required this.operation,
    required this.operationName,
    required this.date,
    required this.party,
    required this.serviceType,
    this.serviceTypeName,
    this.serviceTypeCode,
    required this.unitType,
    this.unitTypeName,
    this.unitTypeCode,
    required this.quantity,
    required this.rate,
    this.amount,
    this.billNo,
    this.remarks,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RevenueStream.fromJson(Map<String, dynamic> json) => _$RevenueStreamFromJson(json);
  Map<String, dynamic> toJson() => _$RevenueStreamToJson(this);

  // Helper methods for display
  String get formattedAmount {
    if (amount == null) return '₹0.00';
    final amountValue = double.tryParse(amount!) ?? 0.0;
    return '₹${amountValue.toStringAsFixed(2)}';
  }

  String get formattedQuantity {
    final quantityValue = double.tryParse(quantity) ?? 0.0;
    return quantityValue.toStringAsFixed(2);
  }

  String get formattedRate {
    final rateValue = double.tryParse(rate) ?? 0.0;
    return '₹${rateValue.toStringAsFixed(2)}';
  }

  // Service type utilities
  String get serviceTypeLabel {
    return serviceTypeName ?? 'Unknown Service Type';
  }

  String get serviceTypeCodeValue {
    return serviceTypeCode ?? 'unknown';
  }

  // Unit type utilities
  String get unitTypeLabel {
    return unitTypeName ?? 'Unknown Unit Type';
  }

  String get unitTypeCodeValue {
    return unitTypeCode ?? 'unknown';
  }

  // Color coding for service types
  String get serviceTypeColor {
    switch (serviceTypeCodeValue) {
      case 'stevedoring':
        return '#1976D2'; // Blue
      case 'storage':
        return '#388E3C'; // Green
      case 'transport':
        return '#F57C00'; // Orange
      case 'handling':
        return '#7B1FA2'; // Purple
      case 'documentation':
        return '#455A64'; // Blue Grey
      case 'others':
        return '#6D4C41'; // Brown
      default:
        return '#757575'; // Grey
    }
  }

  // Unit type color coding  
  String get unitTypeColorCode {
    switch (unitTypeCodeValue) {
      case 'mt':
        return '#2E7D32'; // Green
      case 'cbm':
        return '#1565C0'; // Blue
      case 'per_unit':
        return '#E65100'; // Orange
      case 'lumpsum':
        return '#6A1B9A'; // Purple
      case 'daily':
        return '#BF360C'; // Red
      case 'monthly':
        return '#4E342E'; // Brown
      default:
        return '#424242'; // Grey
    }
  }
} 