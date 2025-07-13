import 'package:json_annotation/json_annotation.dart';

part 'equipment_model.g.dart';

@JsonSerializable()
class Equipment {
  final int id;
  final int operation;
  @JsonKey(name: 'operation_name')
  final String operationName;
  final String date;
  @JsonKey(name: 'vehicle_type')
  final int vehicleType;
  @JsonKey(name: 'vehicle_type_name')
  final String vehicleTypeName;
  @JsonKey(name: 'vehicle_number')
  final String vehicleNumber;
  @JsonKey(name: 'work_type')
  final int workType;
  @JsonKey(name: 'work_type_name')
  final String workTypeName;
  final int party;
  @JsonKey(name: 'party_name')
  final String partyName;
  @JsonKey(name: 'contract_type')
  final String contractType;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'end_time')
  final String? endTime;
  @JsonKey(name: 'duration_hours')
  final String? durationHours;
  final String? quantity;
  final String? rate;
  final String? amount;
  @JsonKey(name: 'total_amount')
  final String? totalAmount;
  @JsonKey(name: 'invoice_number')
  final String? invoiceNumber;
  @JsonKey(name: 'invoice_received')
  final bool? invoiceReceived;
  @JsonKey(name: 'invoice_date')
  final String? invoiceDate;
  final String? comments;
  final String status;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'created_by_name')
  final String createdByName;
  @JsonKey(name: 'ended_by')
  final int? endedBy;
  @JsonKey(name: 'ended_by_name')
  final String? endedByName;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const Equipment({
    required this.id,
    required this.operation,
    required this.operationName,
    required this.date,
    required this.vehicleType,
    required this.vehicleTypeName,
    required this.vehicleNumber,
    required this.workType,
    required this.workTypeName,
    required this.party,
    required this.partyName,
    required this.contractType,
    required this.startTime,
    this.endTime,
    this.durationHours,
    this.quantity,
    this.rate,
    this.amount,
    this.totalAmount,
    this.invoiceNumber,
    this.invoiceReceived,
    this.invoiceDate,
    this.comments,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    this.endedBy,
    this.endedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) =>
      _$EquipmentFromJson(json);

  Map<String, dynamic> toJson() => _$EquipmentToJson(this);

  // Helper methods
  String get displayTitle => '$vehicleTypeName - $vehicleNumber';
  
  String get formattedStartTime {
    try {
      final dateTime = DateTime.parse(startTime);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return startTime;
    }
  }
  
  String get formattedEndTime {
    if (endTime == null) return 'Running';
    try {
      final dateTime = DateTime.parse(endTime!);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return endTime!;
    }
  }
  
  String get formattedDuration {
    if (durationHours == null) return 'Running';
    try {
      final hours = double.parse(durationHours!);
      final wholeHours = hours.floor();
      final minutes = ((hours - wholeHours) * 60).round();
      return '${wholeHours}h ${minutes}m';
    } catch (e) {
      return durationHours!;
    }
  }

  String get formattedInvoiceDate {
    if (invoiceDate == null) return '-';
    try {
      final dateTime = DateTime.parse(invoiceDate!);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return invoiceDate!;
    }
  }

  String get invoiceStatus {
    if (invoiceReceived == null) return 'Pending';
    return invoiceReceived! ? 'Received' : 'Not Applicable';
  }

  // Calculate current running hours
  double get currentRunningHours {
    try {
      final startDateTime = DateTime.parse(startTime);
      final now = DateTime.now();
      final duration = now.difference(startDateTime);
      return duration.inMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Calculate current shifts run (using CEILING formula)
  double get currentShiftsRun {
    final hours = currentRunningHours;
    // CEILING(hours/8, 0.5) formula
    final shifts = hours / 8.0;
    return (shifts * 2).ceil() / 2.0;
  }

  // Calculate time to end current shift
  String get timeToEndShift {
    final hours = currentRunningHours;
    final currentShifts = currentShiftsRun;
    final hoursForCurrentShifts = currentShifts * 8;
    final remainingHours = hoursForCurrentShifts - hours;
    
    if (remainingHours <= 0) {
      return '0h 0m';
    }
    
    final wholeHours = remainingHours.floor();
    final minutes = ((remainingHours - wholeHours) * 60).round();
    return '${wholeHours}h ${minutes}m';
  }
  
  bool get isRunning => status == 'running';
  bool get isCompleted => status == 'completed';
} 