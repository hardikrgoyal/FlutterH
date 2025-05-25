import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/user_model.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  AuthService(this._apiService, this._storage);

  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        '/auth/login/',
        data: {
          'username': username,
          'password': password,
        },
      );

      final loginResponse = LoginResponse.fromJson(response.data);
      
      // Store tokens and user data
      await _apiService.setTokens(loginResponse.access, loginResponse.refresh);
      await _storage.write(
        key: AppConstants.userDataKey,
        value: jsonEncode(loginResponse.user.toJson()),
      );

      return loginResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    // Clear all stored data
    await _apiService.clearTokens();
    await _storage.delete(key: AppConstants.userDataKey);
  }

  Future<User?> getCurrentUser() async {
    try {
      final userDataString = await _storage.read(key: AppConstants.userDataKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        return User.fromJson(userData);
      }
    } catch (e) {
      // If there's an error reading user data, clear tokens
      await _apiService.clearTokens();
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiService.getAccessToken();
    return token != null;
  }

  Future<UserPermissions> getUserPermissions() async {
    final response = await _apiService.get('/auth/permissions/');
    return UserPermissions.fromJson(response.data);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _apiService.post(
      '/auth/change-password/',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _apiService.patch('/auth/profile/', data: profileData);
    final updatedUser = User.fromJson(response.data);
    
    // Update stored user data
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(updatedUser.toJson()),
    );
    
    return updatedUser;
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) {
  final apiService = ApiService();
  apiService.initialize();
  return apiService;
});

final storageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final storage = ref.read(storageProvider);
  return AuthService(apiService, storage);
});

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthStateNotifier(authService);
});

// Auth state classes
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          user: user,
          isLoggedIn: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoggedIn: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final loginResponse = await _authService.login(username, password);
      state = state.copyWith(
        user: loginResponse.user,
        isLoggedIn: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      // Reset state to initial state
      state = AuthState(
        user: null,
        isLoading: false,
        isLoggedIn: false,
        error: null,
      );
    } catch (e) {
      // Even if logout fails, reset the state
      state = AuthState(
        user: null,
        isLoading: false,
        isLoggedIn: false,
        error: 'Logout failed: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final updatedUser = await _authService.updateProfile(profileData);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
} 