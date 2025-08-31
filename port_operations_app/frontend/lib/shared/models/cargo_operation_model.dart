import 'package:json_annotation/json_annotation.dart';

part 'cargo_operation_model.g.dart';

@JsonSerializable()
class CargoOperation {
  final int id;
  @JsonKey(name: 'operation_name')
  final String operationName;
  final String date;
  @JsonKey(name: 'cargo_type')
  final String cargoType;
  final String weight;
  @JsonKey(name: 'party_name')
  final String partyName;
  final String? remarks;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String? createdByName;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  CargoOperation({
    required this.id,
    required this.operationName,
    required this.date,
    required this.cargoType,
    required this.weight,
    required this.partyName,
    this.remarks,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CargoOperation.fromJson(Map<String, dynamic> json) => _$CargoOperationFromJson(json);
  Map<String, dynamic> toJson() => _$CargoOperationToJson(this);

  String get displayTitle {
    return '$displayCargoType Operation - $operationName';
  }

  String get displayCargoType {
    switch (cargoType) {
      case 'paper_bales':
        return 'Paper Bales';
      case 'raw_salt':
        return 'Raw Salt';
      case 'coal':
        return 'Coal';
      case 'silica':
        return 'Silica';
      case 'breakbulk':
        return 'Breakbulk';
      case 'container':
        return 'Container';
      case 'bulk':
        return 'Bulk';
      case 'project':
        return 'Project Cargo';
      case 'others':
        return 'Others';
      default:
        // Convert underscore format to title case
        return cargoType.split('_').map((word) => 
          word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ');
    }
  }

  String get formattedWeight {
    try {
      final weightNum = double.parse(weight);
      return '${weightNum.toStringAsFixed(2)} MT';
    } catch (e) {
      return '$weight MT';
    }
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  CargoOperation copyWith({
    int? id,
    String? operationName,
    String? date,
    String? cargoType,
    String? weight,
    String? partyName,
    String? remarks,
    int? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CargoOperation(
      id: id ?? this.id,
      operationName: operationName ?? this.operationName,
      date: date ?? this.date,
      cargoType: cargoType ?? this.cargoType,
      weight: weight ?? this.weight,
      partyName: partyName ?? this.partyName,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CargoOperation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CargoOperation{id: $id, operationName: $operationName, cargoType: $cargoType}';
  }
} 