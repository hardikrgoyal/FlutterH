// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_type_master_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitTypeMaster _$UnitTypeMasterFromJson(Map<String, dynamic> json) =>
    UnitTypeMaster(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] as bool,
      createdBy: (json['created_by'] as num).toInt(),
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$UnitTypeMasterToJson(UnitTypeMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'created_at': instance.createdAt,
    };
