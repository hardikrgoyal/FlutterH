// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealtimePreview _$RealtimePreviewFromJson(Map<String, dynamic> json) =>
    RealtimePreview(
      durationHours: (json['duration_hours'] as num).toDouble(),
      billingQuantity: (json['billing_quantity'] as num?)?.toDouble(),
      billingUnit: json['billing_unit'] as String?,
      estimatedAmount: (json['estimated_amount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RealtimePreviewToJson(RealtimePreview instance) =>
    <String, dynamic>{
      'duration_hours': instance.durationHours,
      'billing_quantity': instance.billingQuantity,
      'billing_unit': instance.billingUnit,
      'estimated_amount': instance.estimatedAmount,
    };

Equipment _$EquipmentFromJson(Map<String, dynamic> json) => Equipment(
  id: (json['id'] as num).toInt(),
  operation: (json['operation'] as num).toInt(),
  operationName: json['operation_name'] as String,
  date: DateTime.parse(json['date'] as String),
  vehicleType: (json['vehicle_type'] as num).toInt(),
  vehicleTypeName: json['vehicle_type_name'] as String,
  vehicleNumber: json['vehicle_number'] as String,
  workType: (json['work_type'] as num).toInt(),
  workTypeName: json['work_type_name'] as String,
  party: (json['party'] as num).toInt(),
  partyName: json['party_name'] as String,
  contractType: json['contract_type'] as String,
  contractTypeDisplay: json['contract_type_display'] as String,
  startTime: DateTime.parse(json['start_time'] as String),
  endTime:
      json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
  durationHours: (json['duration_hours'] as num?)?.toDouble(),
  comments: json['comments'] as String?,
  status: json['status'] as String,
  statusDisplay: json['status_display'] as String,
  rate: (json['rate'] as num?)?.toDouble(),
  billingQuantity: (json['billing_quantity'] as num?)?.toDouble(),
  totalAmount: (json['total_amount'] as num?)?.toDouble(),
  tonnage: (json['tonnage'] as num?)?.toDouble(),
  invoiceNumber: json['invoice_number'] as String?,
  invoiceReceived: json['invoice_received'] as bool?,
  invoiceDate:
      json['invoice_date'] == null
          ? null
          : DateTime.parse(json['invoice_date'] as String),
  invoiceAmount: (json['invoice_amount'] as num?)?.toDouble(),
  realtimePreview:
      json['realtime_preview'] == null
          ? null
          : RealtimePreview.fromJson(
            json['realtime_preview'] as Map<String, dynamic>,
          ),
  suggestedRate: (json['suggested_rate'] as num?)?.toDouble(),
  createdBy: (json['created_by'] as num).toInt(),
  createdByName: json['created_by_name'] as String,
  endedBy: (json['ended_by'] as num?)?.toInt(),
  endedByName: json['ended_by_name'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$EquipmentToJson(Equipment instance) => <String, dynamic>{
  'id': instance.id,
  'operation': instance.operation,
  'operation_name': instance.operationName,
  'date': instance.date.toIso8601String(),
  'vehicle_type': instance.vehicleType,
  'vehicle_type_name': instance.vehicleTypeName,
  'vehicle_number': instance.vehicleNumber,
  'work_type': instance.workType,
  'work_type_name': instance.workTypeName,
  'party': instance.party,
  'party_name': instance.partyName,
  'contract_type': instance.contractType,
  'contract_type_display': instance.contractTypeDisplay,
  'start_time': instance.startTime.toIso8601String(),
  'end_time': instance.endTime?.toIso8601String(),
  'duration_hours': instance.durationHours,
  'comments': instance.comments,
  'status': instance.status,
  'status_display': instance.statusDisplay,
  'rate': instance.rate,
  'billing_quantity': instance.billingQuantity,
  'total_amount': instance.totalAmount,
  'tonnage': instance.tonnage,
  'invoice_number': instance.invoiceNumber,
  'invoice_received': instance.invoiceReceived,
  'invoice_date': instance.invoiceDate?.toIso8601String(),
  'invoice_amount': instance.invoiceAmount,
  'realtime_preview': instance.realtimePreview,
  'suggested_rate': instance.suggestedRate,
  'created_by': instance.createdBy,
  'created_by_name': instance.createdByName,
  'ended_by': instance.endedBy,
  'ended_by_name': instance.endedByName,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
