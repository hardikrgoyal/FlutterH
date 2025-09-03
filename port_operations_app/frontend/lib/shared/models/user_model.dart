import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String role;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'employee_id')
  final String? employeeId;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.employeeId,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName => '$firstName $lastName'.trim();
  
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isSupervisor => role == 'supervisor';
  bool get isAccountant => role == 'accountant';

  // Permission helper methods
  bool get canCreateOperations => isAdmin || isManager;
  bool get canEditOperations => isAdmin || isManager;
  bool get canManageEquipment => isAdmin || isManager || isSupervisor;
  bool get canEditEquipment => isAdmin || isManager;
  bool get canApproveExpenses => isAdmin || isManager || isAccountant;
  bool get canManageUsers => isAdmin;
  bool get canViewReports => isAdmin || isManager || isAccountant;
  bool get canManageWallet => isAdmin || isAccountant;
  bool get hasWallet => isAdmin || isManager || isSupervisor;
  bool get canSubmitExpenses => isSupervisor;
  bool get canManageLabourCosts => isAdmin || isManager || isSupervisor || isAccountant;
  bool get canEditLabourCosts => isAdmin || isManager || isAccountant;
  bool get canAccessInvoiceTracking => isAdmin || isManager || isAccountant;
  bool get canAccessCostDetails => isAdmin || isManager;

  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'supervisor':
        return 'Supervisor';
      case 'accountant':
        return 'Accountant';
      default:
        return role;
    }
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phoneNumber,
    String? employeeId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      employeeId: employeeId ?? this.employeeId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, username: $username, fullName: $fullName, role: $role}';
  }
}

@JsonSerializable()
class LoginResponse {
  final String access;
  final String refresh;
  final User user;

  LoginResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class UserPermissions {
  @JsonKey(name: 'user_id')
  final int userId;
  final String username;
  final String role;
  final List<String> permissions;

  UserPermissions({
    required this.userId,
    required this.username,
    required this.role,
    required this.permissions,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) => _$UserPermissionsFromJson(json);
  Map<String, dynamic> toJson() => _$UserPermissionsToJson(this);

  bool hasPermission(String permission) => permissions.contains(permission);
} 