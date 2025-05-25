// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractorMaster _$ContractorMasterFromJson(Map<String, dynamic> json) =>
    ContractorMaster(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: (json['created_by'] as num?)?.toInt(),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ContractorMasterToJson(ContractorMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
    };
