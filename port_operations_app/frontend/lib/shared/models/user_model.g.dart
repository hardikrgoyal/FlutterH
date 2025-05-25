// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  role: json['role'] as String,
  phoneNumber: json['phone_number'] as String?,
  employeeId: json['employee_id'] as String?,
  isActive: json['is_active'] as bool?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'role': instance.role,
  'phone_number': instance.phoneNumber,
  'employee_id': instance.employeeId,
  'is_active': instance.isActive,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
      'user': instance.user,
    };

UserPermissions _$UserPermissionsFromJson(Map<String, dynamic> json) =>
    UserPermissions(
      userId: (json['user_id'] as num).toInt(),
      username: json['username'] as String,
      role: json['role'] as String,
      permissions:
          (json['permissions'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$UserPermissionsToJson(UserPermissions instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
      'role': instance.role,
      'permissions': instance.permissions,
    };
