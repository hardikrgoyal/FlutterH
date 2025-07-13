// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'miscellaneous_cost_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MiscellaneousCost _$MiscellaneousCostFromJson(Map<String, dynamic> json) =>
    MiscellaneousCost(
      id: (json['id'] as num).toInt(),
      operation: (json['operation'] as num).toInt(),
      operationName: json['operation_name'] as String,
      date: json['date'] as String,
      party: json['party'] as String,
      costType: json['cost_type'] as String,
      costTypeDisplay: json['cost_type_display'] as String?,
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

Map<String, dynamic> _$MiscellaneousCostToJson(MiscellaneousCost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operation': instance.operation,
      'operation_name': instance.operationName,
      'date': instance.date,
      'party': instance.party,
      'cost_type': instance.costType,
      'cost_type_display': instance.costTypeDisplay,
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
