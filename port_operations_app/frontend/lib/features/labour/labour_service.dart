import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/labour_cost_model.dart';
import '../auth/auth_service.dart';

class LabourService {
  final ApiService _apiService;

  LabourService(this._apiService);

  // Get all labour costs with optional filters
  Future<List<LabourCost>> getLabourCosts({
    int? operationId,
    String? labourType,
    bool? invoiceStatus,
    int? page,
    int? pageSize,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (operationId != null) queryParams['operation'] = operationId.toString();
    if (labourType != null) queryParams['labour_type'] = labourType;
    if (invoiceStatus != null) {
      queryParams['invoice_received'] = invoiceStatus.toString();
    }
    if (page != null) queryParams['page'] = page.toString();
    if (pageSize != null) queryParams['page_size'] = pageSize.toString();

    final response = await _apiService.get(
      '/operations/labour-costs/',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return (data['results'] as List)
          .map((json) => LabourCost.fromJson(json))
          .toList();
    } else if (data is List) {
      return data.map((json) => LabourCost.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // Get labour cost by ID
  Future<LabourCost> getLabourCost(int id) async {
    final response = await _apiService.get('/operations/labour-costs/$id/');
    return LabourCost.fromJson(response.data);
  }

  // Create new labour cost
  Future<LabourCost> createLabourCost(LabourCost labourCost) async {
    final response = await _apiService.post(
      '/operations/labour-costs/',
      data: labourCost.toJson(),
    );
    return LabourCost.fromJson(response.data);
  }

  // Update labour cost
  Future<LabourCost> updateLabourCost(int id, LabourCost labourCost) async {
    final response = await _apiService.put(
      '/operations/labour-costs/$id/',
      data: labourCost.toJson(),
    );
    return LabourCost.fromJson(response.data);
  }

  // Delete labour cost
  Future<void> deleteLabourCost(int id) async {
    await _apiService.delete('/operations/labour-costs/$id/');
  }

  // Get labour costs for specific operation
  Future<List<LabourCost>> getLabourCostsByOperation(int operationId) async {
    return getLabourCosts(operationId: operationId);
  }

  // Get labour costs by type
  Future<List<LabourCost>> getLabourCostsByType(String labourType) async {
    return getLabourCosts(labourType: labourType);
  }

  // Get labour cost statistics
  Future<Map<String, dynamic>> getLabourCostStats({
    int? operationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (operationId != null) queryParams['operation'] = operationId.toString();
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await _apiService.get(
      '/operations/labour-costs/stats/',
      queryParameters: queryParams,
    );
    
    return response.data as Map<String, dynamic>;
  }
}

// Provider for labour service
final labourServiceProvider = Provider<LabourService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return LabourService(apiService);
});

// State notifier for labour costs
class LabourCostNotifier extends StateNotifier<AsyncValue<List<LabourCost>>> {
  final LabourService _labourService;

  LabourCostNotifier(this._labourService) : super(const AsyncValue.loading());

  // Load labour costs
  Future<void> loadLabourCosts({
    int? operationId,
    String? labourType,
    bool? invoiceStatus,
    bool refresh = false,
  }) async {
    if (!refresh && state.hasValue) return;

    state = const AsyncValue.loading();
    
    try {
      final labourCosts = await _labourService.getLabourCosts(
        operationId: operationId,
        labourType: labourType,
        invoiceStatus: invoiceStatus,
      );
      state = AsyncValue.data(labourCosts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Clear state and reload
  Future<void> clearAndReload({
    int? operationId,
    String? labourType,
    bool? invoiceStatus,
  }) async {
    state = const AsyncValue.loading();
    await loadLabourCosts(
      operationId: operationId,
      labourType: labourType,
      invoiceStatus: invoiceStatus,
      refresh: true,
    );
  }

  // Add new labour cost
  Future<void> addLabourCost(LabourCost labourCost) async {
    try {
      final newLabourCost = await _labourService.createLabourCost(labourCost);
      
      state.whenData((labourCosts) {
        state = AsyncValue.data([newLabourCost, ...labourCosts]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Update labour cost
  Future<void> updateLabourCost(int id, LabourCost labourCost) async {
    try {
      final updatedLabourCost = await _labourService.updateLabourCost(id, labourCost);
      
      state.whenData((labourCosts) {
        final index = labourCosts.indexWhere((lc) => lc.id == id);
        if (index != -1) {
          final updatedList = [...labourCosts];
          updatedList[index] = updatedLabourCost;
          state = AsyncValue.data(updatedList);
        }
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Delete labour cost
  Future<void> deleteLabourCost(int id) async {
    try {
      await _labourService.deleteLabourCost(id);
      
      state.whenData((labourCosts) {
        final updatedList = labourCosts.where((lc) => lc.id != id).toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Refresh labour costs
  Future<void> refresh({
    int? operationId, 
    String? labourType,
    bool? invoiceStatus,
  }) async {
    await loadLabourCosts(
      operationId: operationId,
      labourType: labourType,
      invoiceStatus: invoiceStatus,
      refresh: true,
    );
  }
}

// Provider for labour cost notifier
final labourCostProvider = StateNotifierProvider<LabourCostNotifier, AsyncValue<List<LabourCost>>>((ref) {
  final labourService = ref.watch(labourServiceProvider);
  return LabourCostNotifier(labourService);
});

// Provider for labour cost statistics
final labourCostStatsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) {
  final labourService = ref.watch(labourServiceProvider);
  return labourService.getLabourCostStats(
    operationId: params['operationId'] as int?,
    startDate: params['startDate'] as DateTime?,
    endDate: params['endDate'] as DateTime?,
  );
}); 