import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/rate_master_model.dart';
import '../auth/auth_service.dart';

class RateMasterService {
  final ApiService _apiService;

  RateMasterService(this._apiService);

  Future<List<RateMaster>> getRateMasters({int? contractorId, String? labourType}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (contractorId != null) queryParams['contractor'] = contractorId.toString();
      if (labourType != null) queryParams['labour_type'] = labourType;
      
      final response = await _apiService.get('/operations/rate-master/', queryParameters: queryParams);
      
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
      
      return data.map((json) => RateMaster.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load rate masters: $e');
    }
  }

  Future<RateMaster> createRateMaster(RateMaster rateMaster) async {
    try {
      final response = await _apiService.post('/operations/rate-master/', data: rateMaster.toJson());
      return RateMaster.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create rate master: $e');
    }
  }

  Future<RateMaster> updateRateMaster(int id, RateMaster rateMaster) async {
    try {
      final response = await _apiService.put('/operations/rate-master/$id/', data: rateMaster.toJson());
      return RateMaster.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update rate master: $e');
    }
  }

  Future<void> deleteRateMaster(int id) async {
    try {
      await _apiService.delete('/operations/rate-master/$id/');
    } catch (e) {
      throw Exception('Failed to delete rate master: $e');
    }
  }

  Future<double?> getRate(int contractorId, String labourType) async {
    try {
      final rateMasters = await getRateMasters(contractorId: contractorId, labourType: labourType);
      if (rateMasters.isNotEmpty) {
        return rateMasters.first.rate;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// Providers
final rateMasterServiceProvider = Provider<RateMasterService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return RateMasterService(apiService);
});

class RateMasterNotifier extends StateNotifier<AsyncValue<List<RateMaster>>> {
  final RateMasterService _rateMasterService;

  RateMasterNotifier(this._rateMasterService) : super(const AsyncValue.loading());

  Future<void> loadRateMasters({int? contractorId, String? labourType}) async {
    try {
      state = const AsyncValue.loading();
      final rateMasters = await _rateMasterService.getRateMasters(
        contractorId: contractorId,
        labourType: labourType,
      );
      state = AsyncValue.data(rateMasters);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createRateMaster(RateMaster rateMaster) async {
    try {
      await _rateMasterService.createRateMaster(rateMaster);
      await loadRateMasters(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateRateMaster(int id, RateMaster rateMaster) async {
    try {
      await _rateMasterService.updateRateMaster(id, rateMaster);
      await loadRateMasters(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteRateMaster(int id) async {
    try {
      await _rateMasterService.deleteRateMaster(id);
      await loadRateMasters(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final rateMasterProvider = StateNotifierProvider<RateMasterNotifier, AsyncValue<List<RateMaster>>>((ref) {
  final rateMasterService = ref.read(rateMasterServiceProvider);
  return RateMasterNotifier(rateMasterService);
}); 