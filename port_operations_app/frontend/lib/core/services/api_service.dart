import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  late final Logger _logger;
  bool _isRefreshing = false; // Track if refresh is in progress

  void initialize() {
    _storage = const FlutterSecureStorage();
    _logger = Logger();
    
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor to add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        _logger.d('Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) async {
        _logger.e('Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        
        // Handle token refresh on 401, but not for refresh endpoint itself
        if (error.response?.statusCode == 401 && 
            !error.requestOptions.path.contains('/auth/token/refresh/') &&
            !_isRefreshing) {
          
          _isRefreshing = true;
          final refreshed = await _refreshToken();
          _isRefreshing = false;
          
          if (refreshed) {
            // Retry the original request
            final options = error.requestOptions;
            final token = await _storage.read(key: AppConstants.accessTokenKey);
            options.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry fails, proceed with original error
              _logger.e('Retry failed: $e');
            }
          } else {
            // If refresh failed, clear tokens and force logout
            await clearTokens();
          }
        }
        
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        _logger.w('No refresh token available');
        return false;
      }

      _logger.d('Attempting token refresh...');
      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        final newRefreshToken = response.data['refresh']; // JWT rotates refresh tokens
        
        await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
        if (newRefreshToken != null) {
          await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);
        }
        
        _logger.d('Token refresh successful');
        return true;
      }
    } catch (e) {
      _logger.e('Token refresh failed: $e');
      // Don't clear tokens here, let the caller handle it
    }
    return false;
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    _logger.d('🔓 ApiService: Clearing all tokens and user data');
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
    _logger.d('🔓 ApiService: All tokens and user data cleared');
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  // Generic HTTP methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // File upload method
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData();
      
      // Add file
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(file.path),
      ));
      
      // Add additional data
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      return await _dio.post<T>(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = _extractErrorMessage(error.response?.data);
        return ApiException(
          message: message,
          statusCode: statusCode,
          data: error.response?.data,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled',
          statusCode: 0,
        );
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return ApiException(
            message: 'No internet connection',
            statusCode: 0,
          );
        }
        return ApiException(
          message: 'An unexpected error occurred',
          statusCode: 0,
        );
      default:
        return ApiException(
          message: 'An unexpected error occurred',
          statusCode: 0,
        );
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'An error occurred';
    
    if (data is Map<String, dynamic>) {
      // Handle Django REST framework error format
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      
      // Handle field-specific errors
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.addAll(value.map((e) => e.toString()));
        } else {
          errors.add(value.toString());
        }
      });
      
      if (errors.isNotEmpty) {
        return errors.join(', ');
      }
    }
    
    return data.toString();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
} 