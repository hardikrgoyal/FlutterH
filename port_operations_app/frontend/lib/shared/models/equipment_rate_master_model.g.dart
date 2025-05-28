// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_rate_master_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EquipmentRateMaster _$EquipmentRateMasterFromJson(Map<String, dynamic> json) =>
    EquipmentRateMaster(
      id: (json['id'] as num).toInt(),
      party: (json['party'] as num).toInt(),
      partyName: json['party_name'] as String,
      vehicleType: (json['vehicle_type'] as num).toInt(),
      vehicleTypeName: json['vehicle_type_name'] as String,
      workType: (json['work_type'] as num).toInt(),
      workTypeName: json['work_type_name'] as String,
      contractType: json['contract_type'] as String,
      contractTypeDisplay: json['contract_type_display'] as String,
      rate: (json['rate'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      isActive: json['is_active'] as bool,
      createdBy: (json['created_by'] as num).toInt(),
      createdByName: json['created_by_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EquipmentRateMasterToJson(
  EquipmentRateMaster instance,
) => <String, dynamic>{
  'id': instance.id,
  'party': instance.party,
  'party_name': instance.partyName,
  'vehicle_type': instance.vehicleType,
  'vehicle_type_name': instance.vehicleTypeName,
  'work_type': instance.workType,
  'work_type_name': instance.workTypeName,
  'contract_type': instance.contractType,
  'contract_type_display': instance.contractTypeDisplay,
  'rate': instance.rate,
  'effective_from': instance.effectiveFrom.toIso8601String(),
  'is_active': instance.isActive,
  'created_by': instance.createdBy,
  'created_by_name': instance.createdByName,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
