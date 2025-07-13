// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransportDetail _$TransportDetailFromJson(Map<String, dynamic> json) =>
    TransportDetail(
      id: (json['id'] as num).toInt(),
      operation: (json['operation'] as num).toInt(),
      operationName: json['operation_name'] as String,
      date: json['date'] as String,
      vehicle: json['vehicle'] as String,
      vehicleNumber: json['vehicle_number'] as String,
      contractType: json['contract_type'] as String,
      contractTypeDisplay: json['contract_type_display'] as String?,
      quantity: json['quantity'] as String,
      partyName: json['party_name'] as String,
      billNo: json['bill_no'] as String?,
      rate: json['rate'] as String,
      cost: json['cost'] as String?,
      remarks: json['remarks'] as String?,
      createdBy: (json['created_by'] as num).toInt(),
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$TransportDetailToJson(TransportDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operation': instance.operation,
      'operation_name': instance.operationName,
      'date': instance.date,
      'vehicle': instance.vehicle,
      'vehicle_number': instance.vehicleNumber,
      'contract_type': instance.contractType,
      'contract_type_display': instance.contractTypeDisplay,
      'quantity': instance.quantity,
      'party_name': instance.partyName,
      'bill_no': instance.billNo,
      'rate': instance.rate,
      'cost': instance.cost,
      'remarks': instance.remarks,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
