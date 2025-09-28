import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import "../../auth/auth_service.dart";
class VendorAuditLog {
  final int id;
  final String vendorType;
  final int vendorId;
  final String vendorName;
  final String action;
  final int? performedBy;
  final String? performedByName;
  final String? performedByEmail;
  final Map<String, dynamic> changes;
  final String? ipAddress;
  final String? userAgent;
  final String createdAt;

  VendorAuditLog({
    required this.id,
    required this.vendorType,
    required this.vendorId,
    required this.vendorName,
    required this.action,
    this.performedBy,
    this.performedByName,
    this.performedByEmail,
    required this.changes,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory VendorAuditLog.fromJson(Map<String, dynamic> json) {
    return VendorAuditLog(
      id: json['id'] ?? 0,
      vendorType: json['vendor_type'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      vendorName: json['vendor_name'] ?? '',
      action: json['action'] ?? '',
      performedBy: json['performed_by'],
      performedByName: json['performed_by_name'],
      performedByEmail: json['performed_by_email'],
      changes: Map<String, dynamic>.from(json['changes'] ?? {}),
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class VendorAuditService {
  final ApiService _apiService;

  VendorAuditService(this._apiService);

  /// Get audit logs for a specific vendor
  Future<List<VendorAuditLog>> getVendorAuditLogs(String vendorType, int vendorId) async {
    try {
      
      final response = await _apiService.get(
        '/operations/vendor-audit-logs/by_vendor/',
        queryParameters: {
          'vendor_type': vendorType,
          'vendor_id': vendorId,
        },
      );


      final data = response.data;
      if (data is List) {
        final logs = data.map((json) => VendorAuditLog.fromJson(json as Map<String, dynamic>)).toList();
        return logs;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get all audit logs with optional filtering
  Future<List<VendorAuditLog>> getAllAuditLogs({
    String? vendorType,
    int? vendorId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (vendorType != null) queryParams['vendor_type'] = vendorType;
      if (vendorId != null) queryParams['vendor_id'] = vendorId;

      final response = await _apiService.get(
        '/api/operations/vendor-audit-logs/',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => VendorAuditLog.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

// Provider for the service
final vendorAuditServiceProvider = Provider<VendorAuditService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return VendorAuditService(apiService);
});

// Provider for vendor audit logs - using a more stable approach
final vendorAuditLogsProvider = FutureProvider.family<List<VendorAuditLog>, String>((ref, vendorKey) async {
  final service = ref.read(vendorAuditServiceProvider);
  final parts = vendorKey.split('-');
  if (parts.length != 2) return [];
  
  final vendorType = parts[0];
  final vendorId = int.tryParse(parts[1]) ?? 0;
  
  return service.getVendorAuditLogs(vendorType, vendorId);
});
