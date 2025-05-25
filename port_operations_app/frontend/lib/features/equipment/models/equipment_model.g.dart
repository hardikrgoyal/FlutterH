// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
  id: (json['id'] as num).toInt(),
  operation: (json['operation'] as num).toInt(),
  operationName: json['operation_name'] as String,
  date: json['date'] as String,
  vehicleType: (json['vehicle_type'] as num).toInt(),
  vehicleTypeName: json['vehicle_type_name'] as String,
  vehicleNumber: json['vehicle_number'] as String,
  workType: (json['work_type'] as num).toInt(),
  workTypeName: json['work_type_name'] as String,
  party: (json['party'] as num).toInt(),
  partyName: json['party_name'] as String,
  contractType: json['contract_type'] as String,
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String?,
  durationHours: json['duration_hours'] as String?,
  comments: json['comments'] as String?,
  status: json['status'] as String,
  createdBy: (json['created_by'] as num).toInt(),
  createdByName: json['created_by_name'] as String,
  endedBy: (json['ended_by'] as num?)?.toInt(),
  endedByName: json['ended_by_name'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
  'id': instance.id,
  'operation': instance.operation,
  'operation_name': instance.operationName,
  'date': instance.date,
  'vehicle_type': instance.vehicleType,
  'vehicle_type_name': instance.vehicleTypeName,
  'vehicle_number': instance.vehicleNumber,
  'work_type': instance.workType,
  'work_type_name': instance.workTypeName,
  'party': instance.party,
  'party_name': instance.partyName,
  'contract_type': instance.contractType,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'duration_hours': instance.durationHours,
  'comments': instance.comments,
  'status': instance.status,
  'created_by': instance.createdBy,
  'created_by_name': instance.createdByName,
  'ended_by': instance.endedBy,
  'ended_by_name': instance.endedByName,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
