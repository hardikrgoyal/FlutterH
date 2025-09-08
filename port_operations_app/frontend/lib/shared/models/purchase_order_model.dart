class PurchaseOrder {
  final int? id;
  final String poId;
  final int vendor;
  final String? vendorName;
  final int? vehicle;
  final String? vehicleNumber;
  final String? vehicleOther;
  final bool forStock;
  final String category;
  final String? remarkText;
  final String? remarkAudio;
  final String status;
  final int? linkedWo;
  final String? linkedWoId;
  final List<String>? linkedWoIds;
  final String? billNo;
  final String? duplicateWarning;
  final int? itemsCount;
  final double? totalAmount;
  final int? createdBy;
  final String? createdByName;
  final String? createdAt;
  final String? updatedAt;

  PurchaseOrder({
    this.id,
    required this.poId,
    required this.vendor,
    this.vendorName,
    this.vehicle,
    this.vehicleNumber,
    this.vehicleOther,
    required this.forStock,
    required this.category,
    this.remarkText,
    this.remarkAudio,
    required this.status,
    this.linkedWo,
    this.linkedWoId,
    this.linkedWoIds,
    this.billNo,
    this.duplicateWarning,
    this.itemsCount,
    this.totalAmount,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'],
      poId: json['po_id'] ?? '',
      vendor: json['vendor'],
      vendorName: json['vendor_name'],
      vehicle: json['vehicle'],
      vehicleNumber: json['vehicle_number'],
      vehicleOther: json['vehicle_other'],
      forStock: json['for_stock'] ?? false,
      category: json['category'] ?? '',
      remarkText: json['remark_text'],
      remarkAudio: json['remark_audio'],
      status: json['status'] ?? 'open',
      linkedWo: json['linked_wo'],
      linkedWoId: json['linked_wo_id'],
      linkedWoIds: (json['linked_wo_ids'] as List?)?.map((e) => e.toString()).toList(),
      billNo: json['bill_no'],
      duplicateWarning: json['duplicate_warning'],
      itemsCount: json['items_count'] ?? 0,
      totalAmount: json['total_amount']?.toDouble(),
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
      'for_stock': forStock,
      'category': category,
      'remark_text': remarkText,
      'remark_audio': remarkAudio,
      'status': status,
      'linked_wo': linkedWo,
      'bill_no': billNo,
    };
  }

  // Helper methods
  String get displayTarget {
    if (forStock) return 'For Stock';
    return vehicleNumber ?? vehicleOther ?? 'Unknown';
  }
  
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
  bool get hasDuplicateWarning => duplicateWarning != null && duplicateWarning!.isNotEmpty;

  @override
  String toString() => '$poId - $displayTarget';
} 