import 'package:json_annotation/json_annotation.dart';

part 'unit_type_master_model.g.dart';

@JsonSerializable()
class UnitTypeMaster {
  final int id;
  final String name;
  final String code;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String? createdByName;
  @JsonKey(name: 'created_at')
  final String createdAt;

  UnitTypeMaster({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  factory UnitTypeMaster.fromJson(Map<String, dynamic> json) => _$UnitTypeMasterFromJson(json);
  Map<String, dynamic> toJson() => _$UnitTypeMasterToJson(this);

  // Helper method for display
  String get displayName => name;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitTypeMaster &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 