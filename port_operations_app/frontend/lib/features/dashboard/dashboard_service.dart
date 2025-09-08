import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardData() async {
    int retryCount = 0;
    const maxRetries = 2;
    
    while (retryCount < maxRetries) {
      try {
        final response = await _apiService.get('${AppConstants.operationsBaseUrl}/dashboard/');
        return response.data;
      } catch (e) {
        final errorMessage = e.toString();
        
        // If it's a 401 and we haven't retried yet, wait and try again
        if ((errorMessage.contains('401') || errorMessage.contains('Given token not valid')) && retryCount < maxRetries - 1) {
          retryCount++;
          print('Dashboard auth error, retry $retryCount/$maxRetries');
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        }
        
        // If it's still a 401 after retries, return a more specific error
        if (errorMessage.contains('401') || errorMessage.contains('Given token not valid')) {
          throw Exception('Authentication expired. Please login again.');
        }
        
        throw Exception('Failed to fetch dashboard data: $e');
      }
    }
    
    throw Exception('Failed to fetch dashboard data after $maxRetries attempts');
  }
} 