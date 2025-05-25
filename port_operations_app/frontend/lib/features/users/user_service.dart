import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/user_model.dart';
import '../auth/auth_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  /// Get list of all users (admin only)
  Future<List<User>> getUsers({String? role}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null && role != 'all') {
        queryParams['role'] = role;
      }

      final response = await _apiService.get(
        '/auth/users/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Handle Django REST framework pagination
      final data = response.data;
      List<dynamic> userData;
      
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        // Paginated response - extract the results array
        userData = List<dynamic>.from(data['results']);
      } else if (data is List) {
        // Direct list response
        userData = data;
      } else {
        throw Exception('Unexpected response format');
      }
      
      return userData.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: ${e.toString()}');
    }
  }

  /// Create a new user (admin only)
  Future<User> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post(
        '/auth/users/',
        data: userData,
      );

      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  /// Update an existing user (admin only)
  Future<User> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.patch(
        '/auth/users/$userId/',
        data: userData,
      );

      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  /// Delete/deactivate a user (admin only)
  Future<void> deleteUser(int userId) async {
    try {
      await _apiService.delete('/auth/users/$userId/');
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  /// Get a specific user by ID (admin only)
  Future<User> getUser(int userId) async {
    try {
      final response = await _apiService.get('/auth/users/$userId/');
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch user: ${e.toString()}');
    }
  }

  /// Toggle user active status
  Future<User> toggleUserStatus(int userId, bool isActive) async {
    try {
      final response = await _apiService.patch(
        '/auth/users/$userId/',
        data: {'is_active': isActive},
      );

      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update user status: ${e.toString()}');
    }
  }
}

// User management state
class UserManagementState {
  final List<User> users;
  final bool isLoading;
  final String? error;
  final String selectedRole;
  final String searchQuery;

  UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.selectedRole = 'all',
    this.searchQuery = '',
  });

  UserManagementState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
    String? selectedRole,
    String? searchQuery,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedRole: selectedRole ?? this.selectedRole,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Filter users based on search query and selected role
  List<User> get filteredUsers {
    var filtered = users;

    // Filter by role
    if (selectedRole != 'all') {
      filtered = filtered.where((user) => user.role == selectedRole).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        final name = '${user.firstName} ${user.lastName}'.toLowerCase();
        final email = user.email.toLowerCase();
        final username = user.username.toLowerCase();
        
        return name.contains(query) || 
               email.contains(query) || 
               username.contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Get user statistics
  Map<String, int> get userStats {
    return {
      'total': users.length,
      'active': users.where((u) => u.isActive == true).length,
      'inactive': users.where((u) => u.isActive == false).length,
      'filtered': filteredUsers.length,
    };
  }
}

// User management notifier
class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserService _userService;

  UserManagementNotifier(this._userService) : super(UserManagementState()) {
    loadUsers();
  }

  /// Load users from API
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final users = await _userService.getUsers(role: state.selectedRole);
      state = state.copyWith(
        users: users,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh users list
  Future<void> refreshUsers() async {
    await loadUsers();
  }

  /// Create a new user
  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final newUser = await _userService.createUser(userData);
      state = state.copyWith(
        users: [...state.users, newUser],
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update an existing user
  Future<bool> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      final updatedUser = await _userService.updateUser(userId, userData);
      final updatedUsers = state.users.map((user) {
        return user.id == userId ? updatedUser : user;
      }).toList();
      
      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a user
  Future<bool> deleteUser(int userId) async {
    try {
      await _userService.deleteUser(userId);
      final updatedUsers = state.users.where((user) => user.id != userId).toList();
      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> toggleUserStatus(int userId, bool isActive) async {
    try {
      final updatedUser = await _userService.toggleUserStatus(userId, isActive);
      final updatedUsers = state.users.map((user) {
        return user.id == userId ? updatedUser : user;
      }).toList();
      
      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Update selected role filter
  void updateRoleFilter(String role) {
    state = state.copyWith(selectedRole: role);
    loadUsers(); // Reload users with new role filter
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final userServiceProvider = Provider<UserService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return UserService(apiService);
});

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  final userService = ref.read(userServiceProvider);
  return UserManagementNotifier(userService);
}); 