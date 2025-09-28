import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/po_vendor_model.dart';
import '../../auth/auth_service.dart';

class POVendorService {
  final ApiService _apiService;

  POVendorService(this._apiService);

  /// Get list of all PO vendors
  Future<List<POVendor>> getPOVendors() async {
    try {
      final response = await _apiService.get('/operations/po-vendors/');

      // Handle Django REST framework pagination
      final data = response.data;
      List<dynamic> vendorsData;
      
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response - extract the results array
        vendorsData = List<dynamic>.from(data['results']);
      } else if (data is List) {
        // Direct list response
        vendorsData = data;
      } else {
        throw Exception('Unexpected response format');
      }
      
      return vendorsData.map((json) => POVendor.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch PO vendors: ${e.toString()}');
    }
  }

  /// Create a new PO vendor
  Future<POVendor> createPOVendor(Map<String, dynamic> vendorData) async {
    try {
      final response = await _apiService.post(
        '/operations/po-vendors/',
        data: vendorData,
      );

      return POVendor.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create PO vendor: ${e.toString()}');
    }
  }

  /// Update an existing PO vendor
  Future<POVendor> updatePOVendor(int vendorId, Map<String, dynamic> vendorData) async {
    try {
      final response = await _apiService.put(
        '/operations/po-vendors/$vendorId/',
        data: vendorData,
      );

      return POVendor.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update PO vendor: ${e.toString()}');
    }
  }

  /// Delete a PO vendor
  Future<void> deletePOVendor(int vendorId) async {
    try {
      await _apiService.delete('/operations/po-vendors/$vendorId/');
    } catch (e) {
      throw Exception('Failed to delete PO vendor: ${e.toString()}');
    }
  }
}

// Provider for POVendorService
final poVendorServiceProvider = Provider<POVendorService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return POVendorService(apiService);
});

// Providers for PO vendor operations
final poVendorsProvider = FutureProvider<List<POVendor>>((ref) async {
  final vendorService = ref.read(poVendorServiceProvider);
  return vendorService.getPOVendors();
});
