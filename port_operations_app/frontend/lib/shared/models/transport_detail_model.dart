import 'package:json_annotation/json_annotation.dart';

part 'transport_detail_model.g.dart';

@JsonSerializable()
class TransportDetail {
  final int id;
  final int operation;
  @JsonKey(name: 'operation_name')
  final String operationName;
  final String date;
  final String vehicle;
  @JsonKey(name: 'vehicle_number')
  final String vehicleNumber;
  @JsonKey(name: 'contract_type')
  final String contractType;
  @JsonKey(name: 'contract_type_display')
  final String? contractTypeDisplay;
  final String quantity;
  @JsonKey(name: 'party_name')
  final String partyName;
  @JsonKey(name: 'bill_no')
  final String? billNo;
  final String rate;
  final String? cost;
  final String? remarks;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String? createdByName;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  TransportDetail({
    required this.id,
    required this.operation,
    required this.operationName,
    required this.date,
    required this.vehicle,
    required this.vehicleNumber,
    required this.contractType,
    this.contractTypeDisplay,
    required this.quantity,
    required this.partyName,
    this.billNo,
    required this.rate,
    this.cost,
    this.remarks,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportDetail.fromJson(Map<String, dynamic> json) => _$TransportDetailFromJson(json);
  Map<String, dynamic> toJson() => _$TransportDetailToJson(this);

  // Helper getters
  String get displayTitle => '$vehicle - $vehicleNumber';
  String get formattedCost => cost != null ? '₹${cost}' : '₹0.00';
  
  // Contract type helpers
  bool get isPerTrip => contractType == 'per_trip';
  bool get isPerMT => contractType == 'per_mt';
  bool get isDaily => contractType == 'daily';
  bool get isLumpsum => contractType == 'lumpsum';
} 