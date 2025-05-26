import 'package:json_annotation/json_annotation.dart';

part 'labour_cost_model.g.dart';

@JsonSerializable()
class LabourCost {
  final int? id;
  final int operation;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime date;
  final int contractor;
  @JsonKey(name: 'labour_type')
  final String labourType;
  @JsonKey(name: 'work_type')
  final String workType;
  final String? shift;
  @JsonKey(name: 'labour_count_tonnage', fromJson: _doubleFromJson)
  final double labourCountTonnage;
  @JsonKey(fromJson: _doubleFromJsonNullable)
  final double? rate;
  @JsonKey(fromJson: _doubleFromJsonNullable)
  final double? amount;
  final String? remarks;
  
  // Invoice tracking fields
  @JsonKey(name: 'invoice_number')
  final String? invoiceNumber;
  @JsonKey(name: 'invoice_received')
  final bool? invoiceReceived;
  @JsonKey(name: 'invoice_date', fromJson: _dateFromJsonNullable, toJson: _dateToJsonNullable)
  final DateTime? invoiceDate;
  
  // Read-only fields from API
  @JsonKey(name: 'operation_name')
  final String? operationName;
  @JsonKey(name: 'contractor_name')
  final String? contractorName;
  @JsonKey(name: 'contractor_id')
  final int? contractorId;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  @JsonKey(name: 'created_by_name')
  final String? createdByName;
  @JsonKey(name: 'created_at', fromJson: _dateFromJsonNullable)
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateFromJsonNullable)
  final DateTime? updatedAt;

  LabourCost({
    this.id,
    required this.operation,
    required this.date,
    required this.contractor,
    required this.labourType,
    required this.workType,
    this.shift,
    required this.labourCountTonnage,
    this.rate,
    this.amount,
    this.remarks,
    this.invoiceNumber,
    this.invoiceReceived,
    this.invoiceDate,
    this.operationName,
    this.contractorName,
    this.contractorId,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  // Custom serialization methods
  static String _dateToJson(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String? _dateToJsonNullable(DateTime? date) {
    if (date == null) return null;
    return _dateToJson(date);
  }

  static DateTime _dateFromJson(dynamic json) {
    if (json is String) {
      return DateTime.parse(json);
    }
    return json as DateTime;
  }

  static DateTime? _dateFromJsonNullable(dynamic json) {
    if (json == null) return null;
    if (json is String) {
      return DateTime.parse(json);
    }
    return json as DateTime;
  }

  static DateTime? _dateTimeFromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) {
      return DateTime.parse(json);
    }
    return json as DateTime;
  }

  static int _intFromJson(dynamic json) {
    if (json is String) {
      return int.parse(json);
    }
    if (json is double) {
      return json.toInt();
    }
    return json as int;
  }

  static int? _intFromJsonNullable(dynamic json) {
    if (json == null) return null;
    if (json is String) {
      return int.tryParse(json);
    }
    if (json is double) {
      return json.toInt();
    }
    return json as int;
  }

  static double _doubleFromJson(dynamic json) {
    if (json is String) {
      return double.parse(json);
    }
    if (json is int) {
      return json.toDouble();
    }
    return json as double;
  }

  static double? _doubleFromJsonNullable(dynamic json) {
    if (json == null) return null;
    if (json is String) {
      return double.tryParse(json);
    }
    if (json is int) {
      return json.toDouble();
    }
    return json as double;
  }

  static bool? _boolFromJsonNullable(dynamic json) {
    if (json == null) return null;
    if (json is String) {
      return json.toLowerCase() == 'true';
    }
    return json as bool;
  }

  factory LabourCost.fromJson(Map<String, dynamic> json) => _$LabourCostFromJson(json);
  Map<String, dynamic> toJson() => _$LabourCostToJson(this);

  LabourCost copyWith({
    int? id,
    int? operation,
    DateTime? date,
    int? contractor,
    String? labourType,
    String? workType,
    String? shift,
    double? labourCountTonnage,
    double? rate,
    double? amount,
    String? remarks,
    String? invoiceNumber,
    bool? invoiceReceived,
    DateTime? invoiceDate,
    String? operationName,
    String? contractorName,
    int? contractorId,
    int? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabourCost(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      date: date ?? this.date,
      contractor: contractor ?? this.contractor,
      labourType: labourType ?? this.labourType,
      workType: workType ?? this.workType,
      shift: shift ?? this.shift,
      labourCountTonnage: labourCountTonnage ?? this.labourCountTonnage,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      remarks: remarks ?? this.remarks,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceReceived: invoiceReceived ?? this.invoiceReceived,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      operationName: operationName ?? this.operationName,
      contractorName: contractorName ?? this.contractorName,
      contractorId: contractorId ?? this.contractorId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for display
  String get labourTypeDisplay {
    switch (labourType) {
      case 'casual':
        return 'Casual';
      case 'skilled':
        return 'Skilled';
      case 'operator':
        return 'Operator';
      case 'supervisor':
        return 'Supervisor';
      case 'others':
        return 'Others';
      default:
        return labourType;
    }
  }

  String get workTypeDisplay {
    switch (workType) {
      case 'loading':
        return 'Loading';
      case 'unloading':
        return 'Unloading';
      case 'shifting':
        return 'Shifting';
      case 'lashing':
        return 'Lashing';
      case 'others':
        return 'Others';
      default:
        return workType;
    }
  }

  String get invoiceStatusDisplay {
    if (invoiceReceived == true) {
      return 'Received';
    } else {
      return 'Pending';
    }
  }

  bool get hasInvoiceInfo => invoiceNumber != null && invoiceNumber!.isNotEmpty;

  double get calculatedAmount => labourCountTonnage * (rate ?? 0);

  // Static constants for choices
  static const List<Map<String, String>> labourTypeChoices = [
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'tonnes', 'label': 'Tonnes'},
    {'value': 'fixed', 'label': 'Fixed'},
  ];

  static const List<Map<String, String>> workTypeChoices = [
    {'value': 'loading', 'label': 'Loading'},
    {'value': 'unloading', 'label': 'Unloading'},
    {'value': 'shifting', 'label': 'Shifting'},
    {'value': 'sorting', 'label': 'Sorting'},
    {'value': 'other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> shiftChoices = [
    {'value': '1st_shift', 'label': '1st Shift'},
    {'value': '2nd_shift', 'label': '2nd Shift'},
    {'value': '3rd_shift', 'label': '3rd Shift'},
  ];

  static const List<Map<String, dynamic>> invoiceStatusChoices = [
    {'value': null, 'label': 'All Invoices'},
    {'value': true, 'label': 'Invoice Received'},
    {'value': false, 'label': 'Invoice Pending'},
  ];
} 