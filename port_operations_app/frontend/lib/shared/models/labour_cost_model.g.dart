// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'labour_cost_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabourCost _$LabourCostFromJson(Map<String, dynamic> json) => LabourCost(
  id: (json['id'] as num?)?.toInt(),
  operation: (json['operation'] as num).toInt(),
  date: LabourCost._dateFromJson(json['date']),
  contractor: (json['contractor'] as num).toInt(),
  labourType: json['labour_type'] as String,
  workType: json['work_type'] as String,
  shift: json['shift'] as String?,
  labourCountTonnage: LabourCost._doubleFromJson(json['labour_count_tonnage']),
  rate: LabourCost._doubleFromJsonNullable(json['rate']),
  amount: LabourCost._doubleFromJsonNullable(json['amount']),
  remarks: json['remarks'] as String?,
  invoiceNumber: json['invoice_number'] as String?,
  invoiceReceived: json['invoice_received'] as bool?,
  invoiceDate: LabourCost._dateFromJsonNullable(json['invoice_date']),
  operationName: json['operation_name'] as String?,
  contractorName: json['contractor_name'] as String?,
  contractorId: (json['contractor_id'] as num?)?.toInt(),
  createdBy: (json['created_by'] as num?)?.toInt(),
  createdByName: json['created_by_name'] as String?,
  createdAt: LabourCost._dateFromJsonNullable(json['created_at']),
  updatedAt: LabourCost._dateFromJsonNullable(json['updated_at']),
);

Map<String, dynamic> _$LabourCostToJson(LabourCost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operation': instance.operation,
      'date': LabourCost._dateToJson(instance.date),
      'contractor': instance.contractor,
      'labour_type': instance.labourType,
      'work_type': instance.workType,
      'shift': instance.shift,
      'labour_count_tonnage': instance.labourCountTonnage,
      'rate': instance.rate,
      'amount': instance.amount,
      'remarks': instance.remarks,
      'invoice_number': instance.invoiceNumber,
      'invoice_received': instance.invoiceReceived,
      'invoice_date': LabourCost._dateToJsonNullable(instance.invoiceDate),
      'operation_name': instance.operationName,
      'contractor_name': instance.contractorName,
      'contractor_id': instance.contractorId,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
