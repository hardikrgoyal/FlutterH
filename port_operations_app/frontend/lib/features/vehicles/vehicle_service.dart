import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/vehicle_model.dart';
import '../../shared/models/vehicle_type_model.dart';

class VehicleService {
  final ApiService _apiService = ApiService();

  // Vehicle CRUD operations
  Future<List<Vehicle>> getVehicles({
    int? vehicleType,
    String? status,
    String? ownership,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (vehicleType != null) queryParams['vehicle_type'] = vehicleType;
      if (status != null) queryParams['status'] = status;
      if (ownership != null) queryParams['ownership'] = ownership;

      final response = await _apiService.get(
        '/operations/vehicles/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => Vehicle.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vehicles: $e');
    }
  }

  Future<Vehicle> getVehicle(int id) async {
    try {
      final response = await _apiService.get('/operations/vehicles/$id/');
      return Vehicle.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch vehicle: $e');
    }
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await _apiService.post(
        '/operations/vehicles/',
        data: vehicleData,
      );
      return Vehicle.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create vehicle: $e');
    }
  }

  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> vehicleData) async {
    try {
      final response = await _apiService.patch(
        '/operations/vehicles/$id/',
        data: vehicleData,
      );
      return Vehicle.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update vehicle: $e');
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _apiService.delete('/operations/vehicles/$id/');
    } catch (e) {
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  // Vehicle Document operations
  Future<List<VehicleDocument>> getVehicleDocuments({
    int? vehicleId,
    String? documentType,
    String? status,
    bool? expiringSoon,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (vehicleId != null) queryParams['vehicle'] = vehicleId;
      if (documentType != null) queryParams['document_type'] = documentType;
      if (status != null) queryParams['status'] = status;
      if (expiringSoon == true) queryParams['expiring_soon'] = 'true';

      final response = await _apiService.get(
        '/operations/vehicle-documents/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => VehicleDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vehicle documents: $e');
    }
  }

  Future<List<VehicleDocumentGroup>> getVehicleDocumentsByVehicle(int vehicleId) async {
    try {
      final response = await _apiService.get('/operations/vehicles/$vehicleId/documents/');
      
      final List<dynamic> data = response.data;
      return data.map((json) => VehicleDocumentGroup.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vehicle documents: $e');
    }
  }

  Future<List<VehicleDocument>> getExpiringSoonDocuments() async {
    try {
      final response = await _apiService.get('/operations/vehicle-documents/expiring-soon/');
      
      final List<dynamic> data = response.data;
      return data.map((json) => VehicleDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expiring documents: $e');
    }
  }

  Future<List<VehicleDocument>> getExpiredDocuments() async {
    try {
      final response = await _apiService.get('/operations/vehicle-documents/expired/');
      
      final List<dynamic> data = response.data;
      return data.map((json) => VehicleDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expired documents: $e');
    }
  }

  Future<VehicleDocument> createDocument(Map<String, dynamic> documentData) async {
    try {
      final response = await _apiService.post(
        '/operations/vehicle-documents/',
        data: documentData,
      );
      return VehicleDocument.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  Future<VehicleDocument> createDocumentWithFile(
    Map<String, dynamic> documentData,
    XFile? file,
  ) async {
    try {
      if (file != null) {
        final response = await _apiService.uploadFile(
          '/operations/vehicle-documents/',
          file,
          fieldName: 'document_file',
          additionalData: documentData,
        );
        return VehicleDocument.fromJson(response.data);
      } else {
        // No file, use regular POST
        return await createDocument(documentData);
      }
    } catch (e) {
      throw Exception('Failed to create document with file: $e');
    }
  }

  Future<VehicleDocument> updateDocument(int id, Map<String, dynamic> documentData) async {
    try {
      final response = await _apiService.patch(
        '/operations/vehicle-documents/$id/',
        data: documentData,
      );
      return VehicleDocument.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  Future<VehicleDocument> updateDocumentWithFile(
    int id,
    Map<String, dynamic> documentData,
    XFile? file,
  ) async {
    try {
      if (file != null) {
        final response = await _apiService.uploadFile(
          '/operations/vehicle-documents/$id/',
          file,
          fieldName: 'document_file',
          additionalData: documentData,
        );
        return VehicleDocument.fromJson(response.data);
      } else {
        // No file, use regular PATCH
        return await updateDocument(id, documentData);
      }
    } catch (e) {
      throw Exception('Failed to update document with file: $e');
    }
  }

  Future<VehicleDocument> renewDocument(int documentId, Map<String, dynamic> renewalData) async {
    try {
      final response = await _apiService.post(
        '/operations/vehicle-documents/$documentId/renew/',
        data: renewalData,
      );
      return VehicleDocument.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to renew document: $e');
    }
  }

  Future<VehicleDocument> renewDocumentWithFile(
    int documentId,
    Map<String, dynamic> renewalData,
    XFile? file,
  ) async {
    try {
      if (file != null) {
        final response = await _apiService.uploadFile(
          '/operations/vehicle-documents/$documentId/renew/',
          file,
          fieldName: 'document_file',
          additionalData: renewalData,
        );
        return VehicleDocument.fromJson(response.data);
      } else {
        // No file, use regular POST
        return await renewDocument(documentId, renewalData);
      }
    } catch (e) {
      throw Exception('Failed to renew document with file: $e');
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _apiService.delete('/operations/vehicle-documents/$id/');
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<List<DocumentType>> getDocumentTypes() async {
    try {
      final response = await _apiService.get('/operations/vehicle-documents/document-types/');
      
      final List<dynamic> data = response.data;
      return data.map((json) => DocumentType.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch document types: $e');
    }
  }

  Future<List<VehicleType>> getVehicleTypes() async {
    try {
      final response = await _apiService.get('/operations/vehicle-types/');
      
      // Vehicle types API returns a direct list, not paginated
      final List<dynamic> data = response.data is List 
          ? response.data 
          : response.data['results'] ?? response.data;
      return data.map((json) => VehicleType.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vehicle types: $e');
    }
  }

  Future<String> getFileDownloadUrl(String? documentFileUrl) async {
    if (documentFileUrl == null || documentFileUrl.isEmpty) {
      throw Exception('No file URL provided');
    }
    
    // The backend returns full URLs, so we can return them directly
    // But let's ensure they're properly formatted
    if (documentFileUrl.startsWith('http')) {
      return documentFileUrl;
    }
    
    // If it's a relative path, construct the full URL
    const baseUrl = 'http://localhost:8001'; // This should match your backend URL
    return documentFileUrl.startsWith('/') ? '$baseUrl$documentFileUrl' : '$baseUrl/$documentFileUrl';
  }

  Future<bool> isFileImage(String? fileUrl) async {
    if (fileUrl == null) return false;
    final lowercaseUrl = fileUrl.toLowerCase();
    return lowercaseUrl.endsWith('.jpg') || 
           lowercaseUrl.endsWith('.jpeg') || 
           lowercaseUrl.endsWith('.png') || 
           lowercaseUrl.endsWith('.gif') || 
           lowercaseUrl.endsWith('.bmp') || 
           lowercaseUrl.endsWith('.webp');
  }
} 