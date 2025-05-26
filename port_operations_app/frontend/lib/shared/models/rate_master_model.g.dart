// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rate_master_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RateMaster _$RateMasterFromJson(Map<String, dynamic> json) => RateMaster(
  id: (json['id'] as num?)?.toInt(),
  contractor: (json['contractor'] as num).toInt(),
  contractorName: json['contractor_name'] as String?,
  labourType: json['labour_type'] as String,
  labourTypeDisplay: json['labour_type_display'] as String?,
  rate: _doubleFromJson(json['rate']),
  isActive: json['is_active'] as bool? ?? true,
  createdBy: (json['created_by'] as num?)?.toInt(),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$RateMasterToJson(RateMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contractor': instance.contractor,
      'contractor_name': instance.contractorName,
      'labour_type': instance.labourType,
      'labour_type_display': instance.labourTypeDisplay,
      'rate': instance.rate,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
