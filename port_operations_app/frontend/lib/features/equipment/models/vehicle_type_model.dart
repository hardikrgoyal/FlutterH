import 'package:json_annotation/json_annotation.dart';

part 'vehicle_type_model.g.dart';

@JsonSerializable()
class VehicleType {
  final int id;
  final String name;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String createdByName;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const VehicleType({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) =>
      _$VehicleTypeFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleTypeToJson(this);

  @override
  String toString() => name;
} 