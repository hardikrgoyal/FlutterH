import 'package:json_annotation/json_annotation.dart';

part 'work_type_model.g.dart';

@JsonSerializable()
class WorkType {
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

  const WorkType({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  factory WorkType.fromJson(Map<String, dynamic> json) =>
      _$WorkTypeFromJson(json);

  Map<String, dynamic> toJson() => _$WorkTypeToJson(this);

  @override
  String toString() => name;
} 