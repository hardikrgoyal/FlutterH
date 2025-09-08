import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/vendor_model.dart';
import '../../auth/auth_service.dart';

class VendorService {
  final ApiService _apiService;

  VendorService(this._apiService);

  /// Get list of all vendors
  Future<List<Vendor>> getVendors() async {
    try {
      final response = await _apiService.get('/operations/vendors/');

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
      
      return vendorsData.map((json) => Vendor.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendors: ${e.toString()}');
    }
  }

  /// Create a new vendor
  Future<Vendor> createVendor(Map<String, dynamic> vendorData) async {
    try {
      final response = await _apiService.post(
        '/operations/vendors/',
        data: vendorData,
      );

      return Vendor.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create vendor: ${e.toString()}');
    }
  }

  /// Update an existing vendor
  Future<Vendor> updateVendor(int vendorId, Map<String, dynamic> vendorData) async {
    try {
      final response = await _apiService.put(
        '/operations/vendors/$vendorId/',
        data: vendorData,
      );

      return Vendor.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update vendor: ${e.toString()}');
    }
  }

  /// Delete a vendor
  Future<void> deleteVendor(int vendorId) async {
    try {
      await _apiService.delete('/operations/vendors/$vendorId/');
    } catch (e) {
      throw Exception('Failed to delete vendor: ${e.toString()}');
    }
  }
}

// Provider for VendorService
final vendorServiceProvider = Provider<VendorService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return VendorService(apiService);
});

// Providers for vendor operations
final vendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final vendorService = ref.read(vendorServiceProvider);
  return vendorService.getVendors();
}); 