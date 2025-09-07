import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/transport_detail_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../../../shared/models/vehicle_type_model.dart';
import '../../../shared/models/party_master_model.dart';
import '../../auth/auth_service.dart';

// State classes
class TransportDetailState {
  final List<TransportDetail> transportDetails;
  final List<CargoOperation> operations;
  final List<VehicleType> vehicleTypes;
  final List<PartyMaster> parties;
  final bool isLoading;
  final String? error;

  const TransportDetailState({
    this.transportDetails = const [],
    this.operations = const [],
    this.vehicleTypes = const [],
    this.parties = const [],
    this.isLoading = false,
    this.error,
  });

  TransportDetailState copyWith({
    List<TransportDetail>? transportDetails,
    List<CargoOperation>? operations,
    List<VehicleType>? vehicleTypes,
    List<PartyMaster>? parties,
    bool? isLoading,
    String? error,
  }) {
    return TransportDetailState(
      transportDetails: transportDetails ?? this.transportDetails,
      operations: operations ?? this.operations,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      parties: parties ?? this.parties,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Transport Detail Notifier
class TransportDetailNotifier extends StateNotifier<TransportDetailState> {
  final ApiService _apiService;

  TransportDetailNotifier(this._apiService) : super(const TransportDetailState());

  // Load all transport details with optional filtering
  Future<void> loadTransportDetails({
    String? search,
    String? contractType,
    int? operationId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (contractType != null && contractType.isNotEmpty) {
        queryParams['contract_type'] = contractType;
      }
      if (operationId != null) {
        queryParams['operation'] = operationId.toString();
      }

      final uri = Uri.parse('${AppConstants.operationsBaseUrl}/transport-details/')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _apiService.get(uri.toString());
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        final transportDetails = results.map((json) => TransportDetail.fromJson(json)).toList();
        
        state = state.copyWith(
          transportDetails: transportDetails,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to load transport details');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transport details: ${e.toString()}',
      );
    }
  }

  // Load operations for dropdown
  Future<void> loadOperations() async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/cargo-operations/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        final operations = results.map((json) => CargoOperation.fromJson(json)).toList();
        
        state = state.copyWith(operations: operations);
      }
    } catch (e) {
      // Operations loading failure shouldn't stop the whole flow
      // Silently fail for operations loading - not critical
    }
  }

  // Get specific transport detail
  Future<TransportDetail?> getTransportDetail(int transportId) async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/transport-details/$transportId/');
      
      if (response.statusCode == 200) {
        return TransportDetail.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load transport detail: ${e.toString()}');
    }
  }

  // Create new transport detail
  Future<bool> createTransportDetail(TransportDetail transportDetail) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/transport-details/',
        data: transportDetail.toJson(),
      );
      
      if (response.statusCode == 201) {
        // Reload transport details to include the new one
        await loadTransportDetails();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to create transport detail: ${e.toString()}');
    }
  }

  // Update transport detail
  Future<bool> updateTransportDetail(int transportId, TransportDetail transportDetail) async {
    try {
      final response = await _apiService.patch(
        '${AppConstants.operationsBaseUrl}/transport-details/$transportId/',
        data: transportDetail.toJson(),
      );
      
      if (response.statusCode == 200) {
        // Reload transport details to reflect changes
        await loadTransportDetails();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to update transport detail: ${e.toString()}');
    }
  }

  Future<bool> deleteTransportDetail(int transportId) async {
    try {
      final response = await _apiService.delete('${AppConstants.operationsBaseUrl}/transport-details/$transportId/');
      
      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete transport detail: ${e.toString()}');
    }
  }

  Future<List<CargoOperation>> getOperations() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/cargo-operations/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => CargoOperation.fromJson(json)).toList();
    }
    throw Exception('Failed to load operations');
  }

  // Load master data (vehicle types and parties)
  Future<void> loadMasterData() async {
    try {
      await Future.wait([
        loadVehicleTypes(),
        loadParties(),
      ]);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load master data: ${e.toString()}');
    }
  }

  // Load vehicle types
  Future<void> loadVehicleTypes() async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/vehicle-types/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        final vehicleTypes = results.map((json) => VehicleType.fromJson(json)).toList();
        
        state = state.copyWith(vehicleTypes: vehicleTypes);
      }
    } catch (e) {
      // Vehicle types loading failure shouldn't stop the whole flow
      // Silently fail for vehicle types loading - not critical
    }
  }

  // Load parties
  Future<void> loadParties() async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/party-master/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        final parties = results.map((json) => PartyMaster.fromJson(json)).toList();
        
        state = state.copyWith(parties: parties);
      }
    } catch (e) {
      // Parties loading failure shouldn't stop the whole flow
      // Silently fail for parties loading - not critical
    }
  }

  // Add new vehicle type
  Future<bool> addVehicleType(String name) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/vehicle-types/',
        data: {'name': name},
      );
      
      if (response.statusCode == 201) {
        // Reload vehicle types to include the new one
        await loadVehicleTypes();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add vehicle type: ${e.toString()}');
      return false;
    }
  }

  // Add new partyy
  Future<bool> addParty({
    required String name,
  }) async {
    try {
      final data = <String, dynamic>{'name': name};
      
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/party-master/',
        data: data,
      );
      
      if (response.statusCode == 201) {
        // Reload parties to include the new one
        await loadParties();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add party: ${e.toString()}');
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final transportDetailProvider = StateNotifierProvider<TransportDetailNotifier, TransportDetailState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TransportDetailNotifier(apiService);
}); 