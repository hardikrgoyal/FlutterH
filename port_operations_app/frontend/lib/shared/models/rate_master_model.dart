import 'package:json_annotation/json_annotation.dart';

part 'rate_master_model.g.dart';

// Helper function to parse double from JSON (handles both string and number)
double _doubleFromJson(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

@JsonSerializable()
class RateMaster {
  final int? id;
  final int contractor;
  @JsonKey(name: 'contractor_name')
  final String? contractorName;
  @JsonKey(name: 'labour_type')
  final String labourType;
  @JsonKey(name: 'labour_type_display')
  final String? labourTypeDisplay;
  @JsonKey(fromJson: _doubleFromJson)
  final double rate;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  RateMaster({
    this.id,
    required this.contractor,
    this.contractorName,
    required this.labourType,
    this.labourTypeDisplay,
    required this.rate,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RateMaster.fromJson(Map<String, dynamic> json) => _$RateMasterFromJson(json);
  Map<String, dynamic> toJson() => _$RateMasterToJson(this);

  RateMaster copyWith({
    int? id,
    int? contractor,
    String? contractorName,
    String? labourType,
    String? labourTypeDisplay,
    double? rate,
    bool? isActive,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RateMaster(
      id: id ?? this.id,
      contractor: contractor ?? this.contractor,
      contractorName: contractorName ?? this.contractorName,
      labourType: labourType ?? this.labourType,
      labourTypeDisplay: labourTypeDisplay ?? this.labourTypeDisplay,
      rate: rate ?? this.rate,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RateMaster && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RateMaster(id: $id, contractor: $contractor, labourType: $labourType, rate: $rate)';
  }

  static const List<Map<String, String>> labourTypeChoices = [
    {'value': 'casual', 'label': 'Casual'},
    {'value': 'tonnes', 'label': 'Tonnes'},
    {'value': 'fixed', 'label': 'Fixed'},
  ];
} 