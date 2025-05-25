import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/contractor_model.dart';
import '../auth/auth_service.dart';

class ContractorService {
  final ApiService _apiService;

  ContractorService(this._apiService);

  Future<List<ContractorMaster>> getContractors() async {
    try {
      final response = await _apiService.get('/operations/contractor-master/');
      
      List<dynamic> data;
      
      // Handle different response formats
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('results')) {
          // Paginated response
          data = responseMap['results'] as List<dynamic>;
        } else {
          // Single object response (shouldn't happen for list endpoint)
          throw Exception('Unexpected single object response');
        }
      } else if (response.data is List<dynamic>) {
        // Direct array response (pagination disabled)
        data = response.data as List<dynamic>;
      } else {
        throw Exception('Unexpected response format: ${response.data.runtimeType}');
      }
      
      return data.map((json) => ContractorMaster.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load contractors: $e');
    }
  }

  Future<ContractorMaster> getContractor(int id) async {
    try {
      final response = await _apiService.get('/operations/contractor-master/$id/');
      return ContractorMaster.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load contractor: $e');
    }
  }

  Future<ContractorMaster> createContractor(ContractorMaster contractor) async {
    try {
      final response = await _apiService.post(
        '/operations/contractor-master/',
        data: contractor.toJson(),
      );
      return ContractorMaster.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create contractor: $e');
    }
  }

  Future<ContractorMaster> updateContractor(int id, ContractorMaster contractor) async {
    try {
      final response = await _apiService.put(
        '/operations/contractor-master/$id/',
        data: contractor.toJson(),
      );
      return ContractorMaster.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update contractor: $e');
    }
  }

  Future<void> deleteContractor(int id) async {
    try {
      await _apiService.delete('/operations/contractor-master/$id/');
    } catch (e) {
      throw Exception('Failed to delete contractor: $e');
    }
  }
}

// Providers
final contractorServiceProvider = Provider<ContractorService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ContractorService(apiService);
});

// State management for contractors
class ContractorNotifier extends StateNotifier<AsyncValue<List<ContractorMaster>>> {
  final ContractorService _contractorService;

  ContractorNotifier(this._contractorService) : super(const AsyncValue.loading()) {
    loadContractors();
  }

  Future<void> loadContractors() async {
    try {
      state = const AsyncValue.loading();
      final contractors = await _contractorService.getContractors();
      state = AsyncValue.data(contractors);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addContractor(ContractorMaster contractor) async {
    try {
      await _contractorService.createContractor(contractor);
      await loadContractors(); // Refresh the list
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateContractor(int id, ContractorMaster contractor) async {
    try {
      await _contractorService.updateContractor(id, contractor);
      await loadContractors(); // Refresh the list
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteContractor(int id) async {
    try {
      await _contractorService.deleteContractor(id);
      await loadContractors(); // Refresh the list
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadContractors();
  }
}

final contractorProvider = StateNotifierProvider<ContractorNotifier, AsyncValue<List<ContractorMaster>>>((ref) {
  final contractorService = ref.read(contractorServiceProvider);
  return ContractorNotifier(contractorService);
}); 