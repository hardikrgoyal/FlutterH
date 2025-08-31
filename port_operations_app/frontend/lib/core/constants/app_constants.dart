class AppConstants {
  // API Configuration
  // For Android Emulator: use 10.0.2.2
  // For iOS Simulator: use 127.0.0.1 or localhost  
  // For Physical Device: use your computer's IP address
  static const String baseUrl = 'http://10.0.2.2:8001/api';
  
  // Alternative base URLs for different environments
  static const String iOSSimulatorBaseUrl = 'http://127.0.0.1:8001/api';
  static const String localBaseUrl = 'http://localhost:8001/api';
  
  // For physical device, uncomment and replace with your computer's IP
  // static const String physicalDeviceBaseUrl = 'http://192.168.1.xxx:8001/api';
  
  static const String authBaseUrl = '$baseUrl/auth';
  static const String operationsBaseUrl = '$baseUrl/operations';
  static const String financialBaseUrl = '$baseUrl/financial';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // App Info
  static const String appName = 'Port Operations';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Image Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Roles
  static const String adminRole = 'admin';
  static const String managerRole = 'manager';
  static const String supervisorRole = 'supervisor';
  static const String accountantRole = 'accountant';
  
  // Status
  static const String pendingStatus = 'pending';
  static const String ongoingStatus = 'ongoing';
  static const String completedStatus = 'completed';
  static const String submittedStatus = 'submitted';
  static const String approvedStatus = 'approved';
  static const String rejectedStatus = 'rejected';
  static const String finalizedStatus = 'finalized';
  
  // Equipment Status
  static const String runningStatus = 'running';
  static const String equipmentCompletedStatus = 'completed';
  
  // Cargo Types
  static const String breakbulkCargo = 'breakbulk';
  static const String containerCargo = 'container';
  static const String bulkCargo = 'bulk';
  static const String projectCargo = 'project';
  static const String othersCargo = 'others';
  
  // Work Types
  static const String loadingWork = 'loading';
  static const String unloadingWork = 'unloading';
  static const String shiftingWork = 'shifting';
  static const String othersWork = 'others';
  
  // Contract Types
  static const String hourlyContract = 'hourly';
  static const String dailyContract = 'daily';
  static const String tripContract = 'trip';
  static const String lumpsumContract = 'lumpsum';
  
  // Gates
  static const String gate1 = 'gate_1';
  static const String gate2 = 'gate_2';
  static const String gate3 = 'gate_3';
  static const String mainGate = 'main_gate';
  
  // Expense Categories
  static const String fuelCategory = 'fuel';
  static const String maintenanceCategory = 'maintenance';
  static const String officeSuppliesCategory = 'office_supplies';
  static const String travelCategory = 'travel';
  static const String mealsCategory = 'meals';
  static const String communicationCategory = 'communication';
  static const String utilitiesCategory = 'utilities';
  static const String professionalServicesCategory = 'professional_services';
  static const String othersCategory = 'others';
  
  // Payment Methods
  static const String impsPayment = 'imps';
  static const String neftPayment = 'neft';
  static const String cashPayment = 'cash';
  static const String chequePayment = 'cheque';
  static const String othersPayment = 'others';
} 