class Stock {
  final int id;
  final String itemName;
  final double quantityInHand;
  final int sourcePo;
  final String? sourcePoId;
  final int? sourcePoItem;
  final String? sourcePoItemName;
  final String? vendorName;
  final String? lastIssueDate;
  final String unit;
  final String createdAt;
  final String updatedAt;

  Stock({
    required this.id,
    required this.itemName,
    required this.quantityInHand,
    required this.sourcePo,
    this.sourcePoId,
    this.sourcePoItem,
    this.sourcePoItemName,
    this.vendorName,
    this.lastIssueDate,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      itemName: json['item_name'] ?? '',
      quantityInHand: json['quantity_in_hand']?.toDouble() ?? 0.0,
      sourcePo: json['source_po'],
      sourcePoId: json['source_po_id'],
      sourcePoItem: json['source_po_item'],
      sourcePoItemName: json['source_po_item_name'],
      vendorName: json['vendor_name'],
      lastIssueDate: json['last_issue_date'],
      unit: json['unit'] ?? 'nos',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'quantity_in_hand': quantityInHand,
      'source_po': sourcePo,
      'unit': unit,
    };
  }

  // Helper methods
  bool get isLowStock => quantityInHand < 5;
  String get quantityDisplay => '$quantityInHand $unit';
  
  @override
  String toString() => '$itemName - $quantityDisplay';
} 