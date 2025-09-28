import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/wo_vendor_model.dart';
import '../../auth/auth_service.dart';

class WOVendorService {
  final ApiService _apiService;

  WOVendorService(this._apiService);

  /// Get list of all WO vendors
  Future<List<WOVendor>> getWOVendors() async {
    try {
      final response = await _apiService.get('/operations/wo-vendors/');

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
      
      return vendorsData.map((json) => WOVendor.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch WO vendors: ${e.toString()}');
    }
  }

  /// Create a new WO vendor
  Future<WOVendor> createWOVendor(Map<String, dynamic> vendorData) async {
    try {
      final response = await _apiService.post(
        '/operations/wo-vendors/',
        data: vendorData,
      );

      return WOVendor.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create WO vendor: ${e.toString()}');
    }
  }

  /// Update an existing WO vendor
  Future<WOVendor> updateWOVendor(int vendorId, Map<String, dynamic> vendorData) async {
    try {
      final response = await _apiService.put(
        '/operations/wo-vendors/$vendorId/',
        data: vendorData,
      );

      return WOVendor.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update WO vendor: ${e.toString()}');
    }
  }

  /// Delete a WO vendor
  Future<void> deleteWOVendor(int vendorId) async {
    try {
      await _apiService.delete('/operations/wo-vendors/$vendorId/');
    } catch (e) {
      throw Exception('Failed to delete WO vendor: ${e.toString()}');
    }
  }
}

// Provider for WOVendorService
final woVendorServiceProvider = Provider<WOVendorService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return WOVendorService(apiService);
});

// Providers for WO vendor operations
final woVendorsProvider = FutureProvider<List<WOVendor>>((ref) async {
  final vendorService = ref.read(woVendorServiceProvider);
  return vendorService.getWOVendors();
});
