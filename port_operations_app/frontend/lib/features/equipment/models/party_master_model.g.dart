// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_master_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartyMaster _$PartyMasterFromJson(Map<String, dynamic> json) => PartyMaster(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  contactPerson: json['contact_person'] as String?,
  phoneNumber: json['phone_number'] as String?,
  isActive: json['is_active'] as bool,
  createdBy: (json['created_by'] as num).toInt(),
  createdByName: json['created_by_name'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$PartyMasterToJson(PartyMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'contact_person': instance.contactPerson,
      'phone_number': instance.phoneNumber,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_by_name': instance.createdByName,
      'created_at': instance.createdAt,
    };
