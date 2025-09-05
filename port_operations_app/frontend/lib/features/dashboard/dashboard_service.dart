import '../../core/services/api_service.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _apiService.get('/operations/dashboard/');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }
} 