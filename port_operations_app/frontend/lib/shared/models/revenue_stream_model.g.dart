// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_stream_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevenueStream _$RevenueStreamFromJson(Map<String, dynamic> json) =>
    RevenueStream(
      id: (json['id'] as num).toInt(),
      operation: (json['operation'] as num).toInt(),
      operationName: json['operation_name'] as String,
      date: json['date'] as String,
      party: json['party'] as String,
      serviceType: (json['service_type'] as num).toInt(),
      serviceTypeName: json['service_type_name'] as String?,
      serviceTypeCode: json['service_type_code'] as String?,
      unitType: (json['unit_type'] as num).toInt(),
      unitTypeName: json['unit_type_name'] as String?,
      unitTypeCode: json['unit_type_code'] as String?,
      quantity: json['quantity'] as String,
      rate: json['rate'] as String,
      amount: json['amount'] as String?,
      billNo: json['bill_no'] as String?,
      remarks: json['remarks'] as String?,
      createdBy: (json['created_by'] as num).toInt(),
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$RevenueStreamToJson(RevenueStream instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operation': instance.operation,
      'operation_name': instance.operationName,
      'date': instance.date,
      'party': instance.party,
      'service_type': instance.serviceType,
      'service_type_name': instance.serviceTypeName,
      'service_type_code': instance.serviceTypeCode,
      'unit_type': instance.unitType,
      'unit_type_name': instance.unitTypeName,
      'unit_type_code': instance.unitTypeCode,
      'quantity': instance.quantity,
      'rate': instance.rate,
      'amount': instance.amount,
      'bill_no': instance.billNo,
      'remarks': instance.remarks,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
