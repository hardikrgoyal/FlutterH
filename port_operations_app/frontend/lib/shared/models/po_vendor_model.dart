class POVendor {
  final int id;
  final String name;
  final String? contactPerson;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final bool isActive;
  final int createdBy;
  final String? createdByName;
  final String createdAt;

  POVendor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phoneNumber,
    this.email,
    this.address,
    required this.isActive,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  factory POVendor.fromJson(Map<String, dynamic> json) {
    return POVendor(
      id: json['id'],
      name: json['name'] ?? '',
      contactPerson: json['contact_person'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'is_active': isActive,
      'created_by': createdBy,
    };
  }

  // Helper method for display
  String get displayName => name;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is POVendor &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
