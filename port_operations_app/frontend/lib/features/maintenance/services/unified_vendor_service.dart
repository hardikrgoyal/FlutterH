import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';

// Unified vendor model that can represent both PO and WO vendors
class UnifiedVendor {
  final int id;
  final String name;
  final String? contactPerson;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final bool isActive;
  final int createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final String vendorType; // 'po' or 'wo'

  UnifiedVendor({
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
    required this.vendorType,
  });

  factory UnifiedVendor.fromJson(Map<String, dynamic> json, String type) {
    return UnifiedVendor(
      id: json['id'],
      name: json['name'],
      contactPerson: json['contact_person'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      address: json['address'],
      isActive: json['is_active'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      vendorType: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact_person': contactPerson,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'is_active': isActive,
    };
  }

  UnifiedVendor copyWith({
    int? id,
    String? name,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? address,
    bool? isActive,
    int? createdBy,
    String? createdByName,
    DateTime? createdAt,
    String? vendorType,
  }) {
    return UnifiedVendor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      vendorType: vendorType ?? this.vendorType,
    );
  }
}

// Audit log model for vendors
class VendorAuditLog {
  final int id;
  final String vendorType;
  final int vendorId;
  final String vendorName;
  final String action;
  final int? performedBy; // Changed to nullable
  final String? performedByName;
  final String? performedByEmail;
  final Map<String, dynamic>? changes;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  VendorAuditLog({
    required this.id,
    required this.vendorType,
    required this.vendorId,
    required this.vendorName,
    required this.action,
    this.performedBy, // Changed to optional
    this.performedByName,
    this.performedByEmail,
    this.changes,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory VendorAuditLog.fromJson(Map<String, dynamic> json) {
    return VendorAuditLog(
      id: json['id'],
      vendorType: json['vendor_type'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
      action: json['action'],
      performedBy: json['performed_by'],
      performedByName: json['performed_by_name'],
      performedByEmail: json['performed_by_email'],
      changes: json['changes'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get actionDisplay {
    switch (action) {
      case 'created':
        return 'Created';
      case 'updated':
        return 'Updated';
      case 'deleted':
        return 'Deleted';
      case 'activated':
        return 'Activated';
      case 'deactivated':
        return 'Deactivated';
      default:
        return action.toUpperCase();
    }
  }
}

// State management
class UnifiedVendorState {
  final Map<String, List<UnifiedVendor>> vendorsByType;
  final Map<String, List<VendorAuditLog>> auditLogsByVendor;
  final bool isLoading;
  final String? error;

  const UnifiedVendorState({
    this.vendorsByType = const {},
    this.auditLogsByVendor = const {},
    this.isLoading = false,
    this.error,
  });

  UnifiedVendorState copyWith({
    Map<String, List<UnifiedVendor>>? vendorsByType,
    Map<String, List<VendorAuditLog>>? auditLogsByVendor,
    bool? isLoading,
    String? error,
  }) {
    return UnifiedVendorState(
      vendorsByType: vendorsByType ?? this.vendorsByType,
      auditLogsByVendor: auditLogsByVendor ?? this.auditLogsByVendor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<UnifiedVendor> getVendorsForType(String type) {
    return vendorsByType[type] ?? [];
  }

  List<VendorAuditLog> getAuditLogsForVendor(String vendorKey) {
    return auditLogsByVendor[vendorKey] ?? [];
  }
}

// Service notifier
class UnifiedVendorNotifier extends StateNotifier<UnifiedVendorState> {
  final ApiService _apiService;

  UnifiedVendorNotifier(this._apiService) : super(const UnifiedVendorState());

  // Load vendors for a specific type (po or wo)
  Future<void> loadVendors(String type) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final endpoint = type == 'po' ? 'po-vendors' : 'wo-vendors';
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/$endpoint/');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        
        final vendors = results.map((json) => UnifiedVendor.fromJson(json, type)).toList();
        
        final updatedVendorsByType = Map<String, List<UnifiedVendor>>.from(state.vendorsByType);
        updatedVendorsByType[type] = vendors;

        state = state.copyWith(
          vendorsByType: updatedVendorsByType,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Failed to load ${type.toUpperCase()} vendors',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load ${type.toUpperCase()} vendors: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  // Create new vendor
  Future<bool> createVendor(String type, UnifiedVendor vendor) async {
    try {
      final endpoint = type == 'po' ? 'po-vendors' : 'wo-vendors';
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/$endpoint/',
        data: vendor.toJson(),
      );

      if (response.statusCode == 201) {
        // Reload vendors for this type
        await loadVendors(type);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create vendor: ${e.toString()}');
    }
    return false;
  }

  // Update vendor
  Future<bool> updateVendor(String type, int id, UnifiedVendor vendor) async {
    try {
      final endpoint = type == 'po' ? 'po-vendors' : 'wo-vendors';
      final response = await _apiService.put(
        '${AppConstants.operationsBaseUrl}/$endpoint/$id/',
        data: vendor.toJson(),
      );

      if (response.statusCode == 200) {
        // Reload vendors for this type
        await loadVendors(type);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update vendor: ${e.toString()}');
    }
    return false;
  }

  // Delete vendor
  Future<bool> deleteVendor(String type, int id) async {
    try {
      final endpoint = type == 'po' ? 'po-vendors' : 'wo-vendors';
      final response = await _apiService.delete('${AppConstants.operationsBaseUrl}/$endpoint/$id/');

      if (response.statusCode == 204) {
        // Reload vendors for this type
        await loadVendors(type);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete vendor: ${e.toString()}');
    }
    return false;
  }

  // Load audit logs for a vendor
  Future<void> loadAuditLogs(String type, int vendorId) async {
    try {
      final vendorTypeParam = type.toUpperCase(); // 'PO' or 'WO'
      final response = await _apiService.get(
        '${AppConstants.operationsBaseUrl}/vendor-audit-logs/by_vendor/?vendor_type=$vendorTypeParam&vendor_id=$vendorId'
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        
        final auditLogs = results.map((json) => VendorAuditLog.fromJson(json)).toList();
        
        final updatedAuditLogs = Map<String, List<VendorAuditLog>>.from(state.auditLogsByVendor);
        updatedAuditLogs['${type}_$vendorId'] = auditLogs;

        state = state.copyWith(auditLogsByVendor: updatedAuditLogs);
      }
    } catch (e) {
      // Silently fail for audit logs - not critical
      print('Failed to load audit logs: $e');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Load all vendor types
  Future<void> loadAllVendors() async {
    await Future.wait([
      loadVendors('po'),
      loadVendors('wo'),
    ]);
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final unifiedVendorProvider = StateNotifierProvider<UnifiedVendorNotifier, UnifiedVendorState>((ref) {
  return UnifiedVendorNotifier(ref.watch(apiServiceProvider));
}); 