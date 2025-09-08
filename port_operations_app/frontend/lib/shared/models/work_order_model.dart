class WorkOrder {
  final int? id;
  final String woId;
  final int vendor;
  final String? vendorName;
  final int? vehicle;
  final String? vehicleNumber;
  final String? vehicleOther;
  final String category;
  final String? remarkText;
  final String? remarkAudio;
  final String status;
  final int? linkedPo;
  final String? linkedPoId;
  final List<String>? linkedPoIds;
  final String? billNo;
  final int? createdBy;
  final String? createdByName;
  final String? createdAt;
  final String? updatedAt;

  WorkOrder({
    this.id,
    required this.woId,
    required this.vendor,
    this.vendorName,
    this.vehicle,
    this.vehicleNumber,
    this.vehicleOther,
    required this.category,
    this.remarkText,
    this.remarkAudio,
    required this.status,
    this.linkedPo,
    this.linkedPoId,
    this.linkedPoIds,
    this.billNo,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      woId: json['wo_id'] ?? '',
      vendor: json['vendor'],
      vendorName: json['vendor_name'],
      vehicle: json['vehicle'],
      vehicleNumber: json['vehicle_number'],
      vehicleOther: json['vehicle_other'],
      category: json['category'] ?? '',
      remarkText: json['remark_text'],
      remarkAudio: json['remark_audio'],
      status: json['status'] ?? 'open',
      linkedPo: json['linked_po'],
      linkedPoId: json['linked_po_id'],
      linkedPoIds: (json['linked_po_ids'] as List?)?.map((e) => e.toString()).toList(),
      billNo: json['bill_no'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendor,
      'vehicle': vehicle,
      'vehicle_other': vehicleOther,
      'category': category,
      'remark_text': remarkText,
      'remark_audio': remarkAudio,
      'status': status,
      'linked_po': linkedPo,
      'bill_no': billNo,
    };
  }

  // Helper methods
  String get displayVehicle => vehicleNumber ?? vehicleOther ?? 'Unknown';
  String get statusDisplay => status == 'open' ? 'Open' : 'Closed';
  String get categoryDisplay {
    switch (category) {
      case 'engine':
        return 'Engine';
      case 'hydraulic':
        return 'Hydraulic';
      case 'bushing':
        return 'Bushing';
      case 'electrical':
        return 'Electrical';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  @override
  String toString() => '$woId - $displayVehicle';
} 