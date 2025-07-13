import 'package:json_annotation/json_annotation.dart';

part 'miscellaneous_cost_model.g.dart';

@JsonSerializable()
class MiscellaneousCost {
  final int id;
  final int operation;
  @JsonKey(name: 'operation_name')
  final String operationName;
  final String date;
  final String party;
  @JsonKey(name: 'cost_type')
  final String costType;
  @JsonKey(name: 'cost_type_display')
  final String? costTypeDisplay;
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

  MiscellaneousCost({
    required this.id,
    required this.operation,
    required this.operationName,
    required this.date,
    required this.party,
    required this.costType,
    this.costTypeDisplay,
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

  factory MiscellaneousCost.fromJson(Map<String, dynamic> json) => _$MiscellaneousCostFromJson(json);
  Map<String, dynamic> toJson() => _$MiscellaneousCostToJson(this);

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

  // Cost type utilities
  static const Map<String, String> costTypeLabels = {
    'material': 'Material',
    'service': 'Service',
    'equipment_rental': 'Equipment Rental',
    'permits': 'Permits',
    'documentation': 'Documentation',
    'others': 'Others',
  };

  static const List<String> costTypes = [
    'material',
    'service', 
    'equipment_rental',
    'permits',
    'documentation',
    'others',
  ];

  String get costTypeLabel {
    return costTypeLabels[costType] ?? costType;
  }

  // Color coding for cost types
  String get costTypeColor {
    switch (costType) {
      case 'material':
        return '#2196F3'; // Blue
      case 'service':
        return '#4CAF50'; // Green
      case 'equipment_rental':
        return '#FF9800'; // Orange
      case 'permits':
        return '#9C27B0'; // Purple
      case 'documentation':
        return '#607D8B'; // Blue Grey
      case 'others':
        return '#795548'; // Brown
      default:
        return '#757575'; // Grey
    }
  }
} 