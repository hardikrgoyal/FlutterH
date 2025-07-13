import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/equipment_rate_master_model.dart';
import '../../auth/auth_service.dart';

// State class for equipment rate master
class EquipmentRateMasterState {
  final List<EquipmentRateMaster> rateMasters;
  final bool isLoading;
  final String? error;

  EquipmentRateMasterState({
    this.rateMasters = const [],
    this.isLoading = false,
    this.error,
  });

  EquipmentRateMasterState copyWith({
    List<EquipmentRateMaster>? rateMasters,
    bool? isLoading,
    String? error,
  }) {
    return EquipmentRateMasterState(
      rateMasters: rateMasters ?? this.rateMasters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Equipment Rate Master Service
class EquipmentRateMasterService extends StateNotifier<EquipmentRateMasterState> {
  final ApiService _apiService;

  EquipmentRateMasterService(this._apiService) : super(EquipmentRateMasterState());

  // Load all equipment rate masters
  Future<void> loadEquipmentRateMasters({
    int? partyId,
    int? vehicleTypeId,
    int? workTypeId,
    String? contractType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      if (partyId != null) queryParams['party'] = partyId.toString();
      if (vehicleTypeId != null) queryParams['vehicle_type'] = vehicleTypeId.toString();
      if (workTypeId != null) queryParams['work_type'] = workTypeId.toString();
      if (contractType != null) queryParams['contract_type'] = contractType;

      final response = await _apiService.get(
        '${AppConstants.operationsBaseUrl}/equipment-rate-master/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final rateMasters = data.map((json) => EquipmentRateMaster.fromJson(json)).toList();
        state = state.copyWith(
          rateMasters: rateMasters,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Failed to load equipment rate masters',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error loading equipment rate masters: $e',
        isLoading: false,
      );
    }
  }

  // Create new equipment rate master
  Future<bool> createEquipmentRateMaster({
    required int partyId,
    required int vehicleTypeId,
    required int workTypeId,
    required String contractType,
    required double rate,
  }) async {
    try {
      final data = {
        'party': partyId,
        'vehicle_type': vehicleTypeId,
        'work_type': workTypeId,
        'contract_type': contractType,
        'rate': rate,
        'is_active': true,
      };

      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/equipment-rate-master/',
        data: data,
      );

      if (response.statusCode == 201) {
        // Refresh the list
        await loadEquipmentRateMasters();
        return true;
      } else {
        state = state.copyWith(error: 'Failed to create equipment rate master');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error creating equipment rate master: $e');
      return false;
    }
  }

  // Update equipment rate master
  Future<bool> updateEquipmentRateMaster({
    required int id,
    required int partyId,
    required int vehicleTypeId,
    required int workTypeId,
    required String contractType,
    required double rate,
    bool? isActive,
  }) async {
    try {
      final data = {
        'party': partyId,
        'vehicle_type': vehicleTypeId,
        'work_type': workTypeId,
        'contract_type': contractType,
        'rate': rate,
        if (isActive != null) 'is_active': isActive,
      };

      final response = await _apiService.put(
        '${AppConstants.operationsBaseUrl}/equipment-rate-master/$id/',
        data: data,
      );

      if (response.statusCode == 200) {
        // Refresh the list
        await loadEquipmentRateMasters();
        return true;
      } else {
        state = state.copyWith(error: 'Failed to update equipment rate master');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error updating equipment rate master: $e');
      return false;
    }
  }

  // Delete equipment rate master
  Future<bool> deleteEquipmentRateMaster(int id) async {
    try {
      final response = await _apiService.delete(
        '${AppConstants.operationsBaseUrl}/equipment-rate-master/$id/',
      );

      if (response.statusCode == 204) {
        // Refresh the list
        await loadEquipmentRateMasters();
        return true;
      } else {
        state = state.copyWith(error: 'Failed to delete equipment rate master');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error deleting equipment rate master: $e');
      return false;
    }
  }

  // Get rate for specific combination
  EquipmentRateMaster? getRateForCombination({
    required int partyId,
    required int vehicleTypeId,
    required int workTypeId,
    required String contractType,
  }) {
    return state.rateMasters.firstWhere(
      (rateMaster) =>
          rateMaster.party == partyId &&
          rateMaster.vehicleType == vehicleTypeId &&
          rateMaster.workType == workTypeId &&
          rateMaster.contractType == contractType &&
          rateMaster.isActive,
      orElse: () => throw StateError('No rate master found'),
    );
  }

  // Check if rate exists for combination
  bool hasRateForCombination({
    required int partyId,
    required int vehicleTypeId,
    required int workTypeId,
    required String contractType,
  }) {
    try {
      getRateForCombination(
        partyId: partyId,
        vehicleTypeId: vehicleTypeId,
        workTypeId: workTypeId,
        contractType: contractType,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for Equipment Rate Master Service
final equipmentRateMasterServiceProvider = StateNotifierProvider<EquipmentRateMasterService, EquipmentRateMasterState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EquipmentRateMasterService(apiService);
}); 