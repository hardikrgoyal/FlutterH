import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/purchase_order_model.dart';
import '../../auth/auth_service.dart';

class PurchaseOrderService {
  final ApiService _apiService;

  PurchaseOrderService(this._apiService);

  /// Get list of all purchase orders
  Future<List<PurchaseOrder>> getPurchaseOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/operations/purchase-orders/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Handle Django REST framework pagination
      final data = response.data;
      List<dynamic> purchaseOrdersData;
      
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response - extract the results array
        purchaseOrdersData = List<dynamic>.from(data['results']);
      } else if (data is List) {
        // Direct list response
        purchaseOrdersData = data;
      } else {
        throw Exception('Unexpected response format');
      }
      
      return purchaseOrdersData.map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch purchase orders: ${e.toString()}');
    }
  }

  /// Check for duplicate PO before creation
  Future<Map<String, dynamic>> checkDuplicatePO({
    required int vendorId,
    int? vehicleId,
    String? vehicleOther,
    bool forStock = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'vendor_id': vendorId,
        'for_stock': forStock.toString(),
      };
      
      if (vehicleId != null) {
        queryParams['vehicle_id'] = vehicleId;
      } else if (vehicleOther != null) {
        queryParams['vehicle_other'] = vehicleOther;
      }

      final response = await _apiService.get(
        '/operations/purchase-orders/duplicate_check/',
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to check duplicate PO: ${e.toString()}');
    }
  }

  /// Create a new purchase order
  Future<PurchaseOrder> createPurchaseOrder(Map<String, dynamic> purchaseOrderData, {XFile? audioFile}) async {
    try {
      Response response;
      
      if (audioFile != null) {
        // Upload with audio file
        response = await _apiService.uploadFile(
          '/operations/purchase-orders/',
          audioFile,
          fieldName: 'remark_audio',
          additionalData: purchaseOrderData,
        );
      } else {
        // Upload without audio file
        response = await _apiService.post(
          '/operations/purchase-orders/',
          data: purchaseOrderData,
        );
      }

      return PurchaseOrder.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create purchase order: ${e.toString()}');
    }
  }

  /// Update an existing purchase order
  Future<PurchaseOrder> updatePurchaseOrder(int purchaseOrderId, Map<String, dynamic> purchaseOrderData, {XFile? audioFile}) async {
    try {
      Response response;
      
      if (audioFile != null) {
        // Update with audio file
        response = await _apiService.uploadFile(
          '/operations/purchase-orders/$purchaseOrderId/',
          audioFile,
          fieldName: 'remark_audio',
          additionalData: purchaseOrderData,
        );
      } else {
        // Update without audio file
        response = await _apiService.put(
          '/operations/purchase-orders/$purchaseOrderId/',
          data: purchaseOrderData,
        );
      }

      return PurchaseOrder.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update purchase order: ${e.toString()}');
    }
  }

  /// Link a work order to a purchase order (many-to-many)
  Future<void> linkWorkOrder(int purchaseOrderId, int workOrderId) async {
    try {
      await _apiService.post(
        '/operations/purchase-orders/$purchaseOrderId/link_wo/',
        data: {'work_order': workOrderId},
      );
    } catch (e) {
      throw Exception('Failed to link work order: ${e.toString()}');
    }
  }

  /// Unlink a work order from a purchase order (many-to-many)
  Future<void> unlinkWorkOrder(int purchaseOrderId, int workOrderId) async {
    try {
      await _apiService.post(
        '/operations/purchase-orders/$purchaseOrderId/unlink_wo/',
        data: {'work_order': workOrderId},
      );
    } catch (e) {
      throw Exception('Failed to unlink work order: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAudits(int purchaseOrderId) async {
    try {
      final response = await _apiService.get('/operations/purchase-orders/$purchaseOrderId/audits/');
      final data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load audits: ${e.toString()}');
    }
  }

  /// Update bill number
  Future<void> updateBillNumber(int purchaseOrderId, String billNo) async {
    try {
      await _apiService.patch(
        '/operations/purchase-orders/$purchaseOrderId/update_bill_number/',
        data: {'bill_no': billNo},
      );
    } catch (e) {
      throw Exception('Failed to update bill number: ${e.toString()}');
    }
  }

  /// Close purchase order
  Future<void> closePurchaseOrder(int purchaseOrderId) async {
    try {
      await _apiService.patch(
        '/operations/purchase-orders/$purchaseOrderId/close_purchase_order/',
      );
    } catch (e) {
      throw Exception('Failed to close purchase order: ${e.toString()}');
    }
  }

  /// Delete a purchase order
  Future<void> deletePurchaseOrder(int purchaseOrderId) async {
    try {
      await _apiService.delete('/operations/purchase-orders/$purchaseOrderId/');
    } catch (e) {
      throw Exception('Failed to delete purchase order: ${e.toString()}');
    }
  }
}

// Provider for PurchaseOrderService
final purchaseOrderServiceProvider = Provider<PurchaseOrderService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return PurchaseOrderService(apiService);
});

// Providers for purchase order operations
final purchaseOrdersProvider = FutureProvider.family<List<PurchaseOrder>, String?>((ref, status) async {
  final purchaseOrderService = ref.read(purchaseOrderServiceProvider);
  return purchaseOrderService.getPurchaseOrders(status: status);
}); 