import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/miscellaneous_cost_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../../../shared/models/party_master_model.dart';
import '../../auth/auth_service.dart';

// State classes
class MiscellaneousCostState {
  final List<MiscellaneousCost> miscellaneousCosts;
  final List<CargoOperation> operations;
  final List<PartyMaster> parties;
  final bool isLoading;
  final String? error;

  const MiscellaneousCostState({
    this.miscellaneousCosts = const [],
    this.operations = const [],
    this.parties = const [],
    this.isLoading = false,
    this.error,
  });

  MiscellaneousCostState copyWith({
    List<MiscellaneousCost>? miscellaneousCosts,
    List<CargoOperation>? operations,
    List<PartyMaster>? parties,
    bool? isLoading,
    String? error,
  }) {
    return MiscellaneousCostState(
      miscellaneousCosts: miscellaneousCosts ?? this.miscellaneousCosts,
      operations: operations ?? this.operations,
      parties: parties ?? this.parties,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Miscellaneous Cost Notifier
class MiscellaneousCostNotifier extends StateNotifier<MiscellaneousCostState> {
  final ApiService _apiService;

  MiscellaneousCostNotifier(this._apiService) : super(const MiscellaneousCostState());

  // Load all miscellaneous costs with optional filtering
  Future<void> loadMiscellaneousCosts({
    String? search,
    String? costType,
    int? operationId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (costType != null && costType.isNotEmpty) {
        queryParams['cost_type'] = costType;
      }
      if (operationId != null) {
        queryParams['operation'] = operationId.toString();
      }

      final uri = Uri.parse('${AppConstants.operationsBaseUrl}/miscellaneous-costs/')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _apiService.get(uri.toString());
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        
        // Transform total field to amount field for each record
        final transformedResults = results.map((json) {
          final jsonMap = Map<String, dynamic>.from(json);
          if (jsonMap.containsKey('total')) {
            jsonMap['amount'] = jsonMap['total'];
            jsonMap.remove('total');
          }
          return jsonMap;
        }).toList();
        
        final miscellaneousCosts = transformedResults.map((json) => MiscellaneousCost.fromJson(json)).toList();
        
        state = state.copyWith(
          miscellaneousCosts: miscellaneousCosts,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to load miscellaneous costs');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load miscellaneous costs: ${e.toString()}',
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

  // Get specific miscellaneous cost
  Future<MiscellaneousCost?> getMiscellaneousCost(int costId) async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/miscellaneous-costs/$costId/');
      
      if (response.statusCode == 200) {
        // Transform total field to amount field
        final jsonData = Map<String, dynamic>.from(response.data);
        if (jsonData.containsKey('total')) {
          jsonData['amount'] = jsonData['total'];
          jsonData.remove('total');
        }
        return MiscellaneousCost.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load miscellaneous cost: ${e.toString()}');
    }
  }

  // Create new miscellaneous cost
  Future<bool> createMiscellaneousCost(MiscellaneousCost miscellaneousCost) async {
    try {
      // Convert the model to backend format (total instead of amount)
      final data = miscellaneousCost.toJson();
      if (data.containsKey('amount')) {
        data['total'] = data['amount'];
        data.remove('amount');
      }

      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/miscellaneous-costs/',
        data: data,
      );
      
      if (response.statusCode == 201) {
        // Reload miscellaneous costs to include the new one
        await loadMiscellaneousCosts();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to create miscellaneous cost: ${e.toString()}');
    }
  }

  // Update miscellaneous cost
  Future<bool> updateMiscellaneousCost(int costId, MiscellaneousCost miscellaneousCost) async {
    try {
      // Convert the model to backend format (total instead of amount)
      final data = miscellaneousCost.toJson();
      if (data.containsKey('amount')) {
        data['total'] = data['amount'];
        data.remove('amount');
      }

      final response = await _apiService.patch(
        '${AppConstants.operationsBaseUrl}/miscellaneous-costs/$costId/',
        data: data,
      );
      
      if (response.statusCode == 200) {
        // Reload miscellaneous costs to reflect changes
        await loadMiscellaneousCosts();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to update miscellaneous cost: ${e.toString()}');
    }
  }

  Future<bool> deleteMiscellaneousCost(int costId) async {
    try {
      final response = await _apiService.delete('${AppConstants.operationsBaseUrl}/miscellaneous-costs/$costId/');
      
      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete miscellaneous cost: ${e.toString()}');
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

  // Load master data (parties)
  Future<void> loadMasterData() async {
    try {
      await loadParties();
    } catch (e) {
      state = state.copyWith(error: 'Failed to load master data: ${e.toString()}');
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

  // Add new party
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
final miscellaneousCostProvider = StateNotifierProvider<MiscellaneousCostNotifier, MiscellaneousCostState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MiscellaneousCostNotifier(apiService);
}); 