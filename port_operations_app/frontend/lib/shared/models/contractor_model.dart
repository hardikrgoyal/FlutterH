import 'package:json_annotation/json_annotation.dart';

part 'contractor_model.g.dart';

@JsonSerializable()
class ContractorMaster {
  final int? id;
  final String name;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  ContractorMaster({
    this.id,
    required this.name,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
  });

  factory ContractorMaster.fromJson(Map<String, dynamic> json) => _$ContractorMasterFromJson(json);
  Map<String, dynamic> toJson() => _$ContractorMasterToJson(this);

  ContractorMaster copyWith({
    int? id,
    String? name,
    bool? isActive,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return ContractorMaster(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContractorMaster && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContractorMaster{id: $id, name: $name}';
  }
} 