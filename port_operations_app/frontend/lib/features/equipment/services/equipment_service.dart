import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/equipment_model.dart';
import '../../../shared/models/vehicle_type_model.dart';
import '../../../shared/models/work_type_model.dart';
import '../../../shared/models/party_master_model.dart';
import '../../../shared/models/cargo_operation_model.dart';
import '../../auth/auth_service.dart';

// State classes
class EquipmentManagementState {
  final List<Equipment> runningEquipment;
  final List<Equipment> allEquipment;
  final List<VehicleType> vehicleTypes;
  final List<WorkType> workTypes;
  final List<PartyMaster> parties;
  final List<CargoOperation> runningOperations;
  final bool isLoading;
  final String? error;

  const EquipmentManagementState({
    this.runningEquipment = const [],
    this.allEquipment = const [],
    this.vehicleTypes = const [],
    this.workTypes = const [],
    this.parties = const [],
    this.runningOperations = const [],
    this.isLoading = false,
    this.error,
  });

  EquipmentManagementState copyWith({
    List<Equipment>? runningEquipment,
    List<Equipment>? allEquipment,
    List<VehicleType>? vehicleTypes,
    List<WorkType>? workTypes,
    List<PartyMaster>? parties,
    List<CargoOperation>? runningOperations,
    bool? isLoading,
    String? error,
  }) {
    return EquipmentManagementState(
      runningEquipment: runningEquipment ?? this.runningEquipment,
      allEquipment: allEquipment ?? this.allEquipment,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      workTypes: workTypes ?? this.workTypes,
      parties: parties ?? this.parties,
      runningOperations: runningOperations ?? this.runningOperations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Equipment Management Notifier
class EquipmentManagementNotifier extends StateNotifier<EquipmentManagementState> {
  final ApiService _apiService;

  EquipmentManagementNotifier(this._apiService) : super(const EquipmentManagementState());

  // Load all master data needed for equipment forms
  Future<void> loadMasterData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Load all master data in parallel
      final results = await Future.wait([
        _loadVehicleTypes(),
        _loadWorkTypes(),
        _loadParties(),
        _loadRunningOperations(),
      ]);

      state = state.copyWith(
        vehicleTypes: results[0] as List<VehicleType>,
        workTypes: results[1] as List<WorkType>,
        parties: results[2] as List<PartyMaster>,
        runningOperations: results[3] as List<CargoOperation>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load master data: ${e.toString()}',
      );
    }
  }

  // Load running equipment for end equipment screen
  Future<void> loadRunningEquipment() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/equipment/running/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final equipment = data.map((json) => Equipment.fromJson(json)).toList();
        
        state = state.copyWith(
          runningEquipment: equipment,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to load running equipment');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load running equipment: ${e.toString()}',
      );
    }
  }

  // Start equipment
  Future<bool> startEquipment({
    required int operationId,
    required String date,
    required int vehicleTypeId,
    required String vehicleNumber,
    required int workTypeId,
    required int partyId,
    required String contractType,
    required DateTime startTime,
  }) async {
    try {
      final data = {
        'operation': operationId,
        'date': date,
        'vehicle_type': vehicleTypeId,
        'vehicle_number': vehicleNumber.toUpperCase(),
        'work_type': workTypeId,
        'party': partyId,
        'contract_type': contractType,
        'start_time': startTime.toIso8601String(),
      };

      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/equipment/',
        data: data,
      );

      if (response.statusCode == 201) {
        // Refresh running equipment list
        await loadRunningEquipment();
        return true;
      } else {
        state = state.copyWith(error: 'Failed to start equipment');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to start equipment: ${e.toString()}');
      return false;
    }
  }

  // End equipment
  Future<bool> endEquipment({
    required int equipmentId,
    required DateTime endTime,
    String? comments,
    String? quantity,
  }) async {
    try {
      final data = {
        'end_time': endTime.toIso8601String(),
        if (comments != null && comments.isNotEmpty) 'comments': comments,
        if (quantity != null && quantity.isNotEmpty) 'quantity': quantity,
      };

      final response = await _apiService.patch(
        '${AppConstants.operationsBaseUrl}/equipment/$equipmentId/end/',
        data: data,
      );

      if (response.statusCode == 200) {
        // Refresh running equipment list
        await loadRunningEquipment();
        return true;
      } else {
        state = state.copyWith(error: 'Failed to end equipment');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to end equipment: ${e.toString()}');
      return false;
    }
  }

  // Get individual equipment details
  Future<Equipment> getEquipment(int equipmentId) async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/equipment/$equipmentId/');
      
      if (response.statusCode == 200) {
        return Equipment.fromJson(response.data);
      } else {
        throw Exception('Failed to load equipment details');
      }
    } catch (e) {
      throw Exception('Failed to load equipment: ${e.toString()}');
    }
  }

  // Update equipment
  Future<Equipment> updateEquipment(int equipmentId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '${AppConstants.operationsBaseUrl}/equipment/$equipmentId/',
        data: data,
      );

      if (response.statusCode == 200) {
        return Equipment.fromJson(response.data);
      } else {
        throw Exception('Failed to update equipment');
      }
    } catch (e) {
      throw Exception('Failed to update equipment: ${e.toString()}');
    }
  }

  // Delete equipment
  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      final response = await _apiService.delete('${AppConstants.operationsBaseUrl}/equipment/$equipmentId/');
      
      if (response.statusCode == 204) {
        // Refresh equipment lists if needed
        await loadRunningEquipment();
        return true;
      } else {
        state = state.copyWith(error: 'Failed to delete equipment');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete equipment: ${e.toString()}');
      return false;
    }
  }

  // Get all equipment (for history)
  Future<List<Equipment>> getAllEquipment() async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/equipment/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is Map ? data['results'] ?? data : data;
        return results.map((json) => Equipment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load equipment');
      }
    } catch (e) {
      throw Exception('Failed to load equipment: ${e.toString()}');
    }
  }

  // Helper methods to get master data separately
  Future<List<VehicleType>> getVehicleTypes() async {
    return await _loadVehicleTypes();
  }

  Future<List<WorkType>> getWorkTypes() async {
    return await _loadWorkTypes();
  }

  Future<List<PartyMaster>> getParties() async {
    return await _loadParties();
  }

  // Add new vehicle type (for managers/admins)
  Future<bool> addVehicleType(String name) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/vehicle-types/',
        data: {'name': name},
      );

      if (response.statusCode == 201) {
        // Refresh vehicle types list
        final vehicleTypes = await _loadVehicleTypes();
        state = state.copyWith(vehicleTypes: vehicleTypes);
        return true;
      } else {
        state = state.copyWith(error: 'Failed to add vehicle type');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add vehicle type: ${e.toString()}');
      return false;
    }
  }

  // Add new work type (for managers/admins)
  Future<bool> addWorkType(String name) async {
    try {
      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/work-types/',
        data: {'name': name},
      );

      if (response.statusCode == 201) {
        // Refresh work types list
        final workTypes = await _loadWorkTypes();
        state = state.copyWith(workTypes: workTypes);
        return true;
      } else {
        state = state.copyWith(error: 'Failed to add work type');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add work type: ${e.toString()}');
      return false;
    }
  }

  // Add new party (for managers/admins)
  Future<bool> addParty({
    required String name,
    String? contactPerson,
    String? phoneNumber,
  }) async {
    try {
      final data = {
        'name': name,
        if (contactPerson != null && contactPerson.isNotEmpty) 'contact_person': contactPerson,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      };

      final response = await _apiService.post(
        '${AppConstants.operationsBaseUrl}/party-master/',
        data: data,
      );

      if (response.statusCode == 201) {
        // Refresh parties list
        final parties = await _loadParties();
        state = state.copyWith(parties: parties);
        return true;
      } else {
        state = state.copyWith(error: 'Failed to add party');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add party: ${e.toString()}');
      return false;
    }
  }

  // Private helper methods
  Future<List<VehicleType>> _loadVehicleTypes() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/vehicle-types/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => VehicleType.fromJson(json)).toList();
    }
    throw Exception('Failed to load vehicle types');
  }

  Future<List<WorkType>> _loadWorkTypes() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/work-types/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => WorkType.fromJson(json)).toList();
    }
    throw Exception('Failed to load work types');
  }

  Future<List<PartyMaster>> _loadParties() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/party-master/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => PartyMaster.fromJson(json)).toList();
    }
    throw Exception('Failed to load parties');
  }

  Future<List<CargoOperation>> _loadRunningOperations() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/cargo-operations/?running_only=true');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => CargoOperation.fromJson(json)).toList();
    }
    throw Exception('Failed to load running operations');
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Equipment Service Provider (for direct method access)
final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EquipmentService(apiService);
});

// Equipment Service Class
class EquipmentService {
  final ApiService _apiService;

  EquipmentService(this._apiService);

  Future<Equipment> getEquipment(int equipmentId) async {
    try {
      final response = await _apiService.get('${AppConstants.operationsBaseUrl}/equipment/$equipmentId/');
      
      if (response.statusCode == 200) {
        return Equipment.fromJson(response.data);
      } else {
        throw Exception('Failed to load equipment details');
      }
    } catch (e) {
      throw Exception('Failed to load equipment: ${e.toString()}');
    }
  }

  Future<Equipment> updateEquipment(int equipmentId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '${AppConstants.operationsBaseUrl}/equipment/$equipmentId/',
        data: data,
      );

      if (response.statusCode == 200) {
        return Equipment.fromJson(response.data);
      } else {
        throw Exception('Failed to update equipment');
      }
    } catch (e) {
      throw Exception('Failed to update equipment: ${e.toString()}');
    }
  }

  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      final response = await _apiService.delete('${AppConstants.operationsBaseUrl}/equipment/$equipmentId/');
      
      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete equipment: ${e.toString()}');
    }
  }

  Future<List<VehicleType>> getVehicleTypes() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/vehicle-types/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => VehicleType.fromJson(json)).toList();
    }
    throw Exception('Failed to load vehicle types');
  }

  Future<List<WorkType>> getWorkTypes() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/work-types/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => WorkType.fromJson(json)).toList();
    }
    throw Exception('Failed to load work types');
  }

  Future<List<PartyMaster>> getParties() async {
    final response = await _apiService.get('${AppConstants.operationsBaseUrl}/party-master/');
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data is Map ? data['results'] ?? data : data;
      return results.map((json) => PartyMaster.fromJson(json)).toList();
    }
    throw Exception('Failed to load parties');
  }
}

// Provider
final equipmentManagementProvider = StateNotifierProvider<EquipmentManagementNotifier, EquipmentManagementState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EquipmentManagementNotifier(apiService);
}); 