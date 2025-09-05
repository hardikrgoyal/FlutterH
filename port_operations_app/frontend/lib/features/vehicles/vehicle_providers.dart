import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/vehicle_model.dart';
import '../../shared/models/vehicle_type_model.dart';
import 'vehicle_service.dart';

// Shared vehicle service provider
final vehicleServiceProvider = Provider((ref) => VehicleService());

// Vehicle types provider
final vehicleTypesProvider = FutureProvider.autoDispose<List<VehicleType>>((ref) async {
  final service = ref.read(vehicleServiceProvider);
  return service.getVehicleTypes();
});

// Vehicles provider with filters
final vehiclesProvider = FutureProvider.autoDispose.family<List<Vehicle>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.read(vehicleServiceProvider);
  return service.getVehicles(
    vehicleType: filters['vehicleType'],
    status: filters['status'],
    ownership: filters['ownership'],
  );
});

// Vehicle documents by vehicle ID
final vehicleDocumentsProvider = FutureProvider.autoDispose.family<List<VehicleDocumentGroup>, int>((ref, vehicleId) async {
  final service = ref.read(vehicleServiceProvider);
  return service.getVehicleDocumentsByVehicle(vehicleId);
});

// Expiring documents
final expiringSoonDocumentsProvider = FutureProvider.autoDispose<List<VehicleDocument>>((ref) async {
  final service = ref.read(vehicleServiceProvider);
  return service.getExpiringSoonDocuments();
});

// Document types
final documentTypesProvider = FutureProvider.autoDispose<List<DocumentType>>((ref) async {
  final service = ref.read(vehicleServiceProvider);
  return service.getDocumentTypes();
}); 