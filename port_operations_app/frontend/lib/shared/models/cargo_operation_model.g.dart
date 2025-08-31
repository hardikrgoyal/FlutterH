// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cargo_operation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CargoOperation _$CargoOperationFromJson(Map<String, dynamic> json) =>
    CargoOperation(
      id: (json['id'] as num).toInt(),
      operationName: json['operation_name'] as String,
      date: json['date'] as String,
      cargoType: json['cargo_type'] as String,
      weight: json['weight'] as String,
      partyName: json['party_name'] as String,
      remarks: json['remarks'] as String?,
      createdBy: (json['created_by'] as num).toInt(),
      createdByName: json['created_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CargoOperationToJson(CargoOperation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operation_name': instance.operationName,
      'date': instance.date,
      'cargo_type': instance.cargoType,
      'weight': instance.weight,
      'party_name': instance.partyName,
      'remarks': instance.remarks,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
