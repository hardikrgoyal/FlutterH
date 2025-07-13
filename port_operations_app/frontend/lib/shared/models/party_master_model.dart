import 'package:json_annotation/json_annotation.dart';

part 'party_master_model.g.dart';

@JsonSerializable()
class PartyMaster {
  final int id;
  final String name;
  @JsonKey(name: 'contact_person')
  final String? contactPerson;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String? createdByName;
  @JsonKey(name: 'created_at')
  final String createdAt;

  PartyMaster({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phoneNumber,
    required this.isActive,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  factory PartyMaster.fromJson(Map<String, dynamic> json) => _$PartyMasterFromJson(json);
  Map<String, dynamic> toJson() => _$PartyMasterToJson(this);
} 