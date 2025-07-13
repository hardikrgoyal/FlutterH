import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/revenue_stream_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../../../shared/models/party_master_model.dart';
import '../../../shared/models/service_type_master_model.dart';
import '../../../shared/models/unit_type_master_model.dart';
import '../../auth/auth_service.dart';

// Revenue Stream State
class RevenueStreamState {
  final List<RevenueStream> revenueStreams;
  final List<CargoOperation> operations;
  final List<PartyMaster> parties;
  final List<ServiceTypeMaster> serviceTypes;
  final List<UnitTypeMaster> unitTypes;
  final bool isLoading;
  final String? error;

  const RevenueStreamState({
    this.revenueStreams = const [],
    this.operations = const [],
    this.parties = const [],
    this.serviceTypes = const [],
    this.unitTypes = const [],
    this.isLoading = false,
    this.error,
  });

  RevenueStreamState copyWith({
    List<RevenueStream>? revenueStreams,
    List<CargoOperation>? operations,
    List<PartyMaster>? parties,
    List<ServiceTypeMaster>? serviceTypes,
    List<UnitTypeMaster>? unitTypes,
    bool? isLoading,
    String? error,
  }) {
    return RevenueStreamState(
      revenueStreams: revenueStreams ?? this.revenueStreams,
      operations: operations ?? this.operations,
      parties: parties ?? this.parties,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      unitTypes: unitTypes ?? this.unitTypes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Revenue Stream Provider
final revenueStreamProvider = StateNotifierProvider<RevenueStreamNotifier, RevenueStreamState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return RevenueStreamNotifier(apiService);
});

// Revenue Stream Notifier
class RevenueStreamNotifier extends StateNotifier<RevenueStreamState> {
  final ApiService _apiService;

  RevenueStreamNotifier(this._apiService) : super(const RevenueStreamState());

  // Load all revenue streams with optional filtering
  Future<void> loadRevenueStreams({
    String? search,
    String? serviceType,
    String? unitType,
    int? operationId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (serviceType != null && serviceType.isNotEmpty) {
        queryParams['service_type'] = serviceType;
      }
      if (unitType != null && unitType.isNotEmpty) {
        queryParams['unit_type'] = unitType;
      }
      if (operationId != null) {
        queryParams['operation'] = operationId.toString();
      }

      final uri = Uri.parse('${AppConstants.operationsBaseUrl}/revenue-streams/')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _apiService.get(uri.toString());
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        
        // Transform amount field if needed (backend sends 'amount', frontend expects 'amount')
        final transformedResults = results.map((json) {
          final jsonMap = Map<String, dynamic>.from(json);
          // Revenue stream backend already uses 'amount' field, no transformation needed
          return jsonMap;
        }).toList();
        
        final revenueStreams = transformedResults.map((json) => RevenueStream.fromJson(json)).toList();
        
        state = state.copyWith(
          revenueStreams: revenueStreams,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to load revenue streams');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load revenue streams: ${e.toString()}',
      );
    }
  }

  // Load master data (operations, parties, service types, and unit types)
  Future<void> loadMasterData() async {
    try {
      // Load all master data in parallel
      await Future.wait([
        loadOperations(),
        loadParties(),
        loadServiceTypes(),
        loadUnitTypes(),
      ]);
    } catch (e) {
      // Master data loading failure shouldn't stop the whole flow
      // Silently fail - not critical for the main functionality
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

  // Load parties for dropdown
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

  // Load service types for dropdown
  Future<void> loadServiceTypes() async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/service-type-master/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        final serviceTypes = results.map((json) => ServiceTypeMaster.fromJson(json)).toList();
        
        state = state.copyWith(serviceTypes: serviceTypes);
      }
    } catch (e) {
      // Service types loading failure shouldn't stop the whole flow
      // Silently fail for service types loading - not critical
    }
  }

  // Load unit types for dropdown
  Future<void> loadUnitTypes() async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/unit-type-master/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        final unitTypes = results.map((json) => UnitTypeMaster.fromJson(json)).toList();
        
        state = state.copyWith(unitTypes: unitTypes);
      }
    } catch (e) {
      // Unit types loading failure shouldn't stop the whole flow
      // Silently fail for unit types loading - not critical
    }
  }

  // Get specific revenue stream
  Future<RevenueStream?> getRevenueStream(int streamId) async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/revenue-streams/$streamId/');
      
      if (response.statusCode == 200) {
        final jsonData = Map<String, dynamic>.from(response.data);
        return RevenueStream.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load revenue stream: ${e.toString()}');
    }
  }

  // Create new revenue stream
  Future<bool> createRevenueStream(RevenueStream revenueStream) async {
    try {
      final data = revenueStream.toJson();

      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/revenue-streams/',
        data: data,
      );
      
      if (response.statusCode == 201) {
        // Reload revenue streams to include the new one
        await loadRevenueStreams();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to create revenue stream: ${e.toString()}');
    }
  }

  // Update revenue stream
  Future<bool> updateRevenueStream(int streamId, RevenueStream revenueStream) async {
    try {
      final data = revenueStream.toJson();

      final response = await _apiService.patch(
        '${AppConstants.operationsBaseUrl}/revenue-streams/$streamId/',
        data: data,
      );
      
      if (response.statusCode == 200) {
        // Reload revenue streams to reflect changes
        await loadRevenueStreams();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to update revenue stream: ${e.toString()}');
    }
  }

  // Delete revenue stream
  Future<bool> deleteRevenueStream(int streamId) async {
    try {
      final response = await _apiService.delete('${AppConstants.operationsBaseUrl}/revenue-streams/$streamId/');
      
      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete revenue stream: ${e.toString()}');
    }
  }

  // Get operations for dropdown
  Future<List<CargoOperation>> getOperations() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/cargo-operations/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => CargoOperation.fromJson(json)).toList();
    }
    throw Exception('Failed to load operations');
  }

  // Get parties for dropdown
  Future<List<PartyMaster>> getParties() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/party-master/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => PartyMaster.fromJson(json)).toList();
    }
    throw Exception('Failed to load parties');
  }

  // Create new party
  Future<bool> createParty(String partyName) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/party-master/',
        data: {
          'name': partyName,
        },
      );
      
      if (response.statusCode == 201) {
        // Reload parties to include the new one
        await loadParties();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to create party: ${e.toString()}');
    }
  }

  // Create new service type
  Future<bool> createServiceType(String name, String code) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/service-type-master/',
        data: {
          'name': name,
          'code': code,
        },
      );
      
      if (response.statusCode == 201) {
        // Reload service types to include the new one
        await loadServiceTypes();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to create service type: ${e.toString()}');
    }
  }

  // Create new unit type
  Future<bool> createUnitType(String name, String code) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/unit-type-master/',
        data: {
          'name': name,
          'code': code,
        },
      );
      
      if (response.statusCode == 201) {
        // Reload unit types to include the new one
        await loadUnitTypes();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to create unit type: ${e.toString()}');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh data
  Future<void> refresh() async {
    await Future.wait([
      loadRevenueStreams(),
      loadMasterData(),
    ]);
  }
} 