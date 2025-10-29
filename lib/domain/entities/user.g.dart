// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  permissions: (json['permissions'] as List<dynamic>)
      .map((e) => $enumDecode(_$PermissionEnumMap, e))
      .toList(),
  isActive: json['is_active'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
  lastLogin: json['last_login'] == null
      ? null
      : DateTime.parse(json['last_login'] as String),
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'role': _$UserRoleEnumMap[instance.role]!,
  'permissions': instance.permissions
      .map((e) => _$PermissionEnumMap[e]!)
      .toList(),
  'is_active': instance.isActive,
  'created_at': instance.createdAt.toIso8601String(),
  'last_login': instance.lastLogin?.toIso8601String(),
  'avatar_url': instance.avatarUrl,
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.manager: 'manager',
  UserRole.staff: 'staff',
  UserRole.viewer: 'viewer',
};

const _$PermissionEnumMap = {
  Permission.inventoryView: 'inventory_view',
  Permission.inventoryCreate: 'inventory_create',
  Permission.inventoryEdit: 'inventory_edit',
  Permission.inventoryDelete: 'inventory_delete',
  Permission.inventoryExport: 'inventory_export',
  Permission.serialView: 'serial_view',
  Permission.serialManage: 'serial_manage',
  Permission.orderView: 'order_view',
  Permission.orderCreate: 'order_create',
  Permission.orderEdit: 'order_edit',
  Permission.orderDelete: 'order_delete',
  Permission.orderConfirm: 'order_confirm',
  Permission.orderCancel: 'order_cancel',
  Permission.categoryView: 'category_view',
  Permission.categoryManage: 'category_manage',
  Permission.userView: 'user_view',
  Permission.userCreate: 'user_create',
  Permission.userEdit: 'user_edit',
  Permission.userDelete: 'user_delete',
  Permission.reportsView: 'reports_view',
  Permission.reportsExport: 'reports_export',
};
