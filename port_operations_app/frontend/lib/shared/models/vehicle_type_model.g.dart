// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_type_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleType _$VehicleTypeFromJson(Map<String, dynamic> json) => VehicleType(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  isActive: json['is_active'] as bool,
  createdBy: (json['created_by'] as num).toInt(),
  createdByName: json['created_by_name'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$VehicleTypeToJson(VehicleType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'created_at': instance.createdAt,
    };
