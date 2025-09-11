import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/work_order_model.dart';
import '../../auth/auth_service.dart';

class WorkOrderService {
  final ApiService _apiService;

  WorkOrderService(this._apiService);

  /// Get list of all work orders
  Future<List<WorkOrder>> getWorkOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        '/operations/work-orders/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Handle Django REST framework pagination
      final data = response.data;
      List<dynamic> workOrdersData;
      
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response - extract the results array
        workOrdersData = List<dynamic>.from(data['results']);
      } else if (data is List) {
        // Direct list response
        workOrdersData = data;
      } else {
        throw Exception('Unexpected response format');
      }
      
      return workOrdersData.map((json) => WorkOrder.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch work orders: ${e.toString()}');
    }
  }

  /// Create a new work order
  Future<WorkOrder> createWorkOrder(Map<String, dynamic> workOrderData, {XFile? audioFile}) async {
    try {
      Response response;
      
      if (audioFile != null) {
        // Upload with audio file
        response = await _apiService.uploadFile(
          '/operations/work-orders/',
          audioFile,
          fieldName: 'remark_audio',
          additionalData: workOrderData,
        );
      } else {
        // Upload without audio file
        response = await _apiService.post(
          '/operations/work-orders/',
          data: workOrderData,
        );
      }

      return WorkOrder.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create work order: ${e.toString()}');
    }
  }

  /// Update an existing work order
  Future<WorkOrder> updateWorkOrder(int workOrderId, Map<String, dynamic> workOrderData, {XFile? audioFile}) async {
    try {
      Response response;
      
      if (audioFile != null) {
        // Update with audio file
        response = await _apiService.uploadFile(
          '/operations/work-orders/$workOrderId/',
          audioFile,
          fieldName: 'remark_audio',
          additionalData: workOrderData,
        );
      } else {
        // Update without audio file
        response = await _apiService.put(
          '/operations/work-orders/$workOrderId/',
          data: workOrderData,
        );
      }

      return WorkOrder.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update work order: ${e.toString()}');
    }
  }

  /// Link a purchase order to a work order (many-to-many)
  Future<void> linkPurchaseOrder(int workOrderId, int purchaseOrderId) async {
    try {
      await _apiService.post(
        '/operations/work-orders/$workOrderId/link_po/',
        data: {'purchase_order': purchaseOrderId},
      );
    } catch (e) {
      throw Exception('Failed to link purchase order: ${e.toString()}');
    }
  }

  /// Unlink a purchase order from a work order (many-to-many)
  Future<void> unlinkPurchaseOrder(int workOrderId, int purchaseOrderId) async {
    try {
      await _apiService.post(
        '/operations/work-orders/$workOrderId/unlink_po/',
        data: {'purchase_order': purchaseOrderId},
      );
    } catch (e) {
      throw Exception('Failed to unlink purchase order: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAudits(int workOrderId) async {
    try {
      final response = await _apiService.get('/operations/work-orders/$workOrderId/audits/');
      final data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load audits: ${e.toString()}');
    }
  }

  /// Update bill number
  Future<void> updateBillNumber(int workOrderId, String billNo) async {
    try {
      await _apiService.patch(
        '/operations/work-orders/$workOrderId/update_bill_number/',
        data: {'bill_no': billNo},
      );
    } catch (e) {
      throw Exception('Failed to update bill number: ${e.toString()}');
    }
  }

  /// Close work order
  Future<void> closeWorkOrder(int workOrderId) async {
    try {
      await _apiService.patch(
        '/operations/work-orders/$workOrderId/close_work_order/',
      );
    } catch (e) {
      throw Exception('Failed to close work order: ${e.toString()}');
    }
  }

  /// Delete a work order
  Future<void> deleteWorkOrder(int workOrderId) async {
    try {
      await _apiService.delete('/operations/work-orders/$workOrderId/');
    } catch (e) {
      throw Exception('Failed to delete work order: ${e.toString()}');
    }
  }
}

// Provider for WorkOrderService
final workOrderServiceProvider = Provider<WorkOrderService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return WorkOrderService(apiService);
});

// Providers for work order operations
final workOrdersProvider = FutureProvider.family<List<WorkOrder>, String?>((ref, status) async {
  final workOrderService = ref.read(workOrderServiceProvider);
  return workOrderService.getWorkOrders(status: status);
}); 