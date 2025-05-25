import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/cargo_operation_model.dart';
import '../auth/auth_service.dart';

class OperationsService {
  final ApiService _apiService;

  OperationsService(this._apiService);

  /// Get list of all cargo operations
  Future<List<CargoOperation>> getOperations({String? status, String? cargoType}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }
      if (cargoType != null && cargoType != 'all') {
        queryParams['cargo_type'] = cargoType;
      }

      final response = await _apiService.get(
        '/operations/cargo-operations/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Handle Django REST framework pagination
      final data = response.data;
      List<dynamic> operationsData;
      
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response - extract the results array
        operationsData = List<dynamic>.from(data['results']);
      } else if (data is List) {
        // Direct list response
        operationsData = data;
      } else {
        throw Exception('Unexpected response format');
      }
      
      return operationsData.map((json) => CargoOperation.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch operations: ${e.toString()}');
    }
  }

  /// Create a new cargo operation
  Future<CargoOperation> createOperation(Map<String, dynamic> operationData) async {
    try {
      final response = await _apiService.post(
        '/operations/cargo-operations/',
        data: operationData,
      );

      return CargoOperation.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create operation: ${e.toString()}');
    }
  }

  /// Update an existing cargo operation
  Future<CargoOperation> updateOperation(int operationId, Map<String, dynamic> operationData) async {
    try {
      final response = await _apiService.patch(
        '/operations/cargo-operations/$operationId/',
        data: operationData,
      );

      return CargoOperation.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update operation: ${e.toString()}');
    }
  }

  /// Delete a cargo operation
  Future<void> deleteOperation(int operationId) async {
    try {
      await _apiService.delete('/operations/cargo-operations/$operationId/');
    } catch (e) {
      throw Exception('Failed to delete operation: ${e.toString()}');
    }
  }

  /// Get a specific operation by ID
  Future<CargoOperation> getOperation(int operationId) async {
    try {
      final response = await _apiService.get('/operations/cargo-operations/$operationId/');
      return CargoOperation.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch operation: ${e.toString()}');
    }
  }

  /// Get operations statistics
  Future<Map<String, int>> getOperationsStats() async {
    try {
      final operations = await getOperations();
      
      return {
        'total': operations.length,
        'pending': operations.where((op) => op.projectStatus == 'pending').length,
        'ongoing': operations.where((op) => op.projectStatus == 'ongoing').length,
        'completed': operations.where((op) => op.projectStatus == 'completed').length,
      };
    } catch (e) {
      throw Exception('Failed to fetch operations stats: ${e.toString()}');
    }
  }
}

// Operations management state
class OperationsManagementState {
  final List<CargoOperation> operations;
  final bool isLoading;
  final String? error;
  final String selectedStatus;
  final String selectedCargoType;
  final String searchQuery;

  OperationsManagementState({
    this.operations = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus = 'all',
    this.selectedCargoType = 'all',
    this.searchQuery = '',
  });

  OperationsManagementState copyWith({
    List<CargoOperation>? operations,
    bool? isLoading,
    String? error,
    String? selectedStatus,
    String? selectedCargoType,
    String? searchQuery,
  }) {
    return OperationsManagementState(
      operations: operations ?? this.operations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedCargoType: selectedCargoType ?? this.selectedCargoType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Filter operations based on search query, status, and cargo type
  List<CargoOperation> get filteredOperations {
    var filtered = operations;

    // Filter by status
    if (selectedStatus != 'all') {
      filtered = filtered.where((op) => op.projectStatus == selectedStatus).toList();
    }

    // Filter by cargo type
    if (selectedCargoType != 'all') {
      filtered = filtered.where((op) => op.cargoType == selectedCargoType).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((op) {
        final operationName = op.operationName.toLowerCase();
        final partyName = op.partyName.toLowerCase();
        final packaging = op.packaging.toLowerCase();
        
        return operationName.contains(query) || 
               partyName.contains(query) || 
               packaging.contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Get operations statistics
  Map<String, int> get operationsStats {
    return {
      'total': operations.length,
      'pending': operations.where((op) => op.projectStatus == 'pending').length,
      'ongoing': operations.where((op) => op.projectStatus == 'ongoing').length,
      'completed': operations.where((op) => op.projectStatus == 'completed').length,
      'filtered': filteredOperations.length,
    };
  }
}

// Operations management notifier
class OperationsManagementNotifier extends StateNotifier<OperationsManagementState> {
  final OperationsService _operationsService;

  OperationsManagementNotifier(this._operationsService) : super(OperationsManagementState()) {
    loadOperations();
  }

  /// Load operations from API
  Future<void> loadOperations() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final operations = await _operationsService.getOperations(
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        cargoType: state.selectedCargoType != 'all' ? state.selectedCargoType : null,
      );
      state = state.copyWith(
        operations: operations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh operations list
  Future<void> refreshOperations() async {
    await loadOperations();
  }

  /// Create a new operation
  Future<bool> createOperation(Map<String, dynamic> operationData) async {
    try {
      final newOperation = await _operationsService.createOperation(operationData);
      state = state.copyWith(
        operations: [...state.operations, newOperation],
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update an existing operation
  Future<bool> updateOperation(int operationId, Map<String, dynamic> operationData) async {
    try {
      final updatedOperation = await _operationsService.updateOperation(operationId, operationData);
      final updatedOperations = state.operations.map((operation) {
        return operation.id == operationId ? updatedOperation : operation;
      }).toList();
      
      state = state.copyWith(operations: updatedOperations);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete an operation
  Future<bool> deleteOperation(int operationId) async {
    try {
      await _operationsService.deleteOperation(operationId);
      final updatedOperations = state.operations.where((operation) => operation.id != operationId).toList();
      state = state.copyWith(operations: updatedOperations);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Update status filter
  void updateStatusFilter(String status) {
    state = state.copyWith(selectedStatus: status);
    loadOperations(); // Reload operations with new filter
  }

  /// Update cargo type filter
  void updateCargoTypeFilter(String cargoType) {
    state = state.copyWith(selectedCargoType: cargoType);
    loadOperations(); // Reload operations with new filter
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final operationsServiceProvider = Provider<OperationsService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return OperationsService(apiService);
});

final operationsManagementProvider = StateNotifierProvider<OperationsManagementNotifier, OperationsManagementState>((ref) {
  final operationsService = ref.read(operationsServiceProvider);
  return OperationsManagementNotifier(operationsService);
}); 