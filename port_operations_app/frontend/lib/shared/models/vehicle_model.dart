class Vehicle {
  final int id;
  final String vehicleNumber;
  final int vehicleType;
  final String vehicleTypeName;
  final String ownership;
  final String ownershipDisplay;
  final String status;
  final String statusDisplay;
  final String? ownerName;
  final String? ownerContact;
  final String? capacity;
  final String? makeModel;
  final int? yearOfManufacture;
  final String? chassisNumber;
  final String? engineNumber;
  final String? remarks;
  final bool isActive;
  final int activeDocumentsCount;
  final int expiredDocumentsCount;
  final int expiringSoonCount;
  final int createdBy;
  final String createdByName;
  final String createdAt;
  final String updatedAt;

  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleTypeName,
    required this.ownership,
    required this.ownershipDisplay,
    required this.status,
    required this.statusDisplay,
    this.ownerName,
    this.ownerContact,
    this.capacity,
    this.makeModel,
    this.yearOfManufacture,
    this.chassisNumber,
    this.engineNumber,
    this.remarks,
    required this.isActive,
    required this.activeDocumentsCount,
    required this.expiredDocumentsCount,
    required this.expiringSoonCount,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleType: json['vehicle_type'],
      vehicleTypeName: json['vehicle_type_name'] ?? '',
      ownership: json['ownership'] ?? '',
      ownershipDisplay: json['ownership_display'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerContact: json['owner_contact'] ?? '',
      capacity: json['capacity'] ?? '',
      makeModel: json['make_model'] ?? '',
      yearOfManufacture: json['year_of_manufacture'],
      chassisNumber: json['chassis_number'] ?? '',
      engineNumber: json['engine_number'] ?? '',
      remarks: json['remarks'] ?? '',
      isActive: json['is_active'] ?? true,
      activeDocumentsCount: json['active_documents_count'] ?? 0,
      expiredDocumentsCount: json['expired_documents_count'] ?? 0,
      expiringSoonCount: json['expiring_soon_count'] ?? 0,
      createdBy: json['created_by'],
      createdByName: json['created_by_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'ownership': ownership,
      'status': status,
      'owner_name': ownerName,
      'owner_contact': ownerContact,
      'capacity': capacity,
      'make_model': makeModel,
      'year_of_manufacture': yearOfManufacture,
      'chassis_number': chassisNumber,
      'engine_number': engineNumber,
      'remarks': remarks,
      'is_active': isActive,
    };
  }
}

class VehicleDocument {
  final int id;
  final int vehicle;
  final String vehicleNumber;
  final String vehicleTypeName;
  final String documentType;
  final String documentTypeDisplay;
  final String documentNumber;
  final String? documentFile;
  final String? issueDate;
  final String expiryDate;
  final String status;
  final String statusDisplay;
  final int? renewalReference;
  final String? renewalReferenceDocumentNumber;
  final String? notes;
  final int daysUntilExpiry;
  final bool isExpiringSoon;
  final bool isExpired;
  final int addedBy;
  final String addedByName;
  final String addedOn;
  final int? updatedBy;
  final String? updatedByName;
  final String updatedAt;
  final int? renewedBy;
  final String? renewedByName;
  final String? renewedOn;

  const VehicleDocument({
    required this.id,
    required this.vehicle,
    required this.vehicleNumber,
    required this.vehicleTypeName,
    required this.documentType,
    required this.documentTypeDisplay,
    required this.documentNumber,
    this.documentFile,
    this.issueDate,
    required this.expiryDate,
    required this.status,
    required this.statusDisplay,
    this.renewalReference,
    this.renewalReferenceDocumentNumber,
    this.notes,
    required this.daysUntilExpiry,
    required this.isExpiringSoon,
    required this.isExpired,
    required this.addedBy,
    required this.addedByName,
    required this.addedOn,
    this.updatedBy,
    this.updatedByName,
    required this.updatedAt,
    this.renewedBy,
    this.renewedByName,
    this.renewedOn,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'],
      vehicle: json['vehicle'],
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleTypeName: json['vehicle_type_name'] ?? '',
      documentType: json['document_type'],
      documentTypeDisplay: json['document_type_display'],
      documentNumber: json['document_number'],
      documentFile: json['document_file'],
      issueDate: json['issue_date'],
      expiryDate: json['expiry_date'],
      status: json['status'],
      statusDisplay: json['status_display'],
      renewalReference: json['renewal_reference'],
      renewalReferenceDocumentNumber: json['renewal_reference_document_number'],
      notes: json['notes'],
      daysUntilExpiry: json['days_until_expiry'] ?? 0,
      isExpiringSoon: json['is_expiring_soon'] ?? false,
      isExpired: json['is_expired'] ?? false,
      addedBy: json['added_by'],
      addedByName: json['added_by_name'] ?? '',
      addedOn: json['added_on'] ?? '',
      updatedBy: json['updated_by'],
      updatedByName: json['updated_by_name'],
      updatedAt: json['updated_at'] ?? '',
      renewedBy: json['renewed_by'],
      renewedByName: json['renewed_by_name'],
      renewedOn: json['renewed_on'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle': vehicle,
      'document_type': documentType,
      'document_number': documentNumber,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'notes': notes,
    };
  }
}

class DocumentType {
  final String value;
  final String label;

  const DocumentType({
    required this.value,
    required this.label,
  });

  factory DocumentType.fromJson(Map<String, dynamic> json) {
    return DocumentType(
      value: json['value'],
      label: json['label'],
    );
  }
}

class VehicleDocumentGroup {
  final String type;
  final String typeDisplay;
  final VehicleDocument? current;
  final List<VehicleDocument> history;

  const VehicleDocumentGroup({
    required this.type,
    required this.typeDisplay,
    this.current,
    required this.history,
  });

  factory VehicleDocumentGroup.fromJson(Map<String, dynamic> json) {
    return VehicleDocumentGroup(
      type: json['type'],
      typeDisplay: json['type_display'],
      current: json['current'] != null ? VehicleDocument.fromJson(json['current']) : null,
      history: (json['history'] as List<dynamic>)
          .map((doc) => VehicleDocument.fromJson(doc))
          .toList(),
    );
  }
} 