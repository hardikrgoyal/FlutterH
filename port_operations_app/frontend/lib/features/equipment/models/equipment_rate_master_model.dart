import 'package:json_annotation/json_annotation.dart';

part 'equipment_rate_master_model.g.dart';

@JsonSerializable()
class EquipmentRateMaster {
  final int id;
  final int party;
  @JsonKey(name: 'party_name')
  final String partyName;
  @JsonKey(name: 'vehicle_type')
  final int vehicleType;
  @JsonKey(name: 'vehicle_type_name')
  final String vehicleTypeName;
  @JsonKey(name: 'work_type')
  final int workType;
  @JsonKey(name: 'work_type_name')
  final String workTypeName;
  @JsonKey(name: 'contract_type')
  final String contractType;
  @JsonKey(name: 'contract_type_display')
  final String contractTypeDisplay;
  final String unit;
  @JsonKey(name: 'unit_display')
  final String unitDisplay;
  final String rate;
  @JsonKey(name: 'effective_from')
  final String effectiveFrom;
  @JsonKey(name: 'valid_until')
  final String? validUntil;
  final String? notes;
  @JsonKey(name: 'validity_status')
  final String validityStatus;
  @JsonKey(name: 'is_currently_valid')
  final bool isCurrentlyValid;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String createdByName;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const EquipmentRateMaster({
    required this.id,
    required this.party,
    required this.partyName,
    required this.vehicleType,
    required this.vehicleTypeName,
    required this.workType,
    required this.workTypeName,
    required this.contractType,
    required this.contractTypeDisplay,
    required this.unit,
    required this.unitDisplay,
    required this.rate,
    required this.effectiveFrom,
    this.validUntil,
    this.notes,
    required this.validityStatus,
    required this.isCurrentlyValid,
    required this.isActive,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EquipmentRateMaster.fromJson(Map<String, dynamic> json) =>
      _$EquipmentRateMasterFromJson(json);

  Map<String, dynamic> toJson() => _$EquipmentRateMasterToJson(this);

  // Helper methods
  String get displayTitle => '$partyName - $vehicleTypeName - $workTypeName - $contractTypeDisplay';
  
  String get formattedRate => '₹$rate per $unitDisplay';
  
  String get formattedEffectiveFrom {
    try {
      final dateTime = DateTime.parse(effectiveFrom);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return effectiveFrom;
    }
  }
  
  String get formattedValidUntil {
    if (validUntil == null) return 'No expiry';
    try {
      final dateTime = DateTime.parse(validUntil!);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return validUntil!;
    }
  }
  
  String get formattedCreatedAt {
    try {
      final dateTime = DateTime.parse(createdAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return createdAt;
    }
  }
} 