// ✅ domain/entities/user.dart (WITH CORRECT PERMISSIONS!)
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  @JsonKey(name: 'role')
  final UserRole role;
  @JsonKey(name: 'permissions')
  final List<Permission> permissions;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.avatarUrl,
  });

  // ✅ Check if user has specific permission
  bool hasPermission(Permission permission) {
    return permissions.contains(permission) || role == UserRole.admin;
  }

  // ✅ Check multiple permissions (user needs ALL)
  bool hasAllPermissions(List<Permission> requiredPermissions) {
    if (role == UserRole.admin) return true;
    return requiredPermissions.every((p) => permissions.contains(p));
  }

  // ✅ Check multiple permissions (user needs ANY)
  bool hasAnyPermission(List<Permission> requiredPermissions) {
    if (role == UserRole.admin) return true;
    return requiredPermissions.any((p) => permissions.contains(p));
  }

  // ✅ Quick role checks
  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isStaff => role == UserRole.staff;
  bool get isViewer => role == UserRole.viewer;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [id, email, name, role, permissions, isActive, createdAt, lastLogin, avatarUrl];
}

// ✅ User Roles
@JsonEnum()
enum UserRole {
  @JsonValue('admin')
  admin,        // Full access to everything
  @JsonValue('manager')
  manager,      // Can manage inventory, orders, and approve orders
  @JsonValue('staff')
  staff,        // Can create/edit inventory and orders, but NOT approve
  @JsonValue('viewer')
  viewer,       // Read-only access
}

// ✅ Granular Permissions
@JsonEnum()
enum Permission {
  // Inventory Permissions
  @JsonValue('inventory_view')
  inventoryView,
  @JsonValue('inventory_create')
  inventoryCreate,
  @JsonValue('inventory_edit')
  inventoryEdit,
  @JsonValue('inventory_delete')
  inventoryDelete,
  @JsonValue('inventory_export')
  inventoryExport,

  // Serial Number Permissions
  @JsonValue('serial_view')
  serialView,
  @JsonValue('serial_manage')
  serialManage,

  // Order Permissions
  @JsonValue('order_view')
  orderView,
  @JsonValue('order_create')
  orderCreate,
  @JsonValue('order_edit')
  orderEdit,
  @JsonValue('order_delete')
  orderDelete,
  @JsonValue('order_confirm')
  orderConfirm,
  @JsonValue('order_cancel')
  orderCancel,

  // Category Permissions
  @JsonValue('category_view')
  categoryView,
  @JsonValue('category_manage')
  categoryManage,

  // User Management Permissions
  @JsonValue('user_view')
  userView,
  @JsonValue('user_create')
  userCreate,
  @JsonValue('user_edit')
  userEdit,
  @JsonValue('user_delete')
  userDelete,

  // Reports & Analytics
  @JsonValue('reports_view')
  reportsView,
  @JsonValue('reports_export')
  reportsExport,
}

// ✅ Role Extensions
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full system access';
      case UserRole.manager:
        return 'Can manage inventory, orders, and approve orders';
      case UserRole.staff:
        return 'Can create and edit inventory and orders';
      case UserRole.viewer:
        return 'Read-only access';
    }
  }

  // ✅ Default permissions for each role (MATCHING YOUR TABLE EXACTLY!)
  List<Permission> get defaultPermissions {
    switch (this) {
      case UserRole.admin:
        return Permission.values; // ✅ Admin: ALL permissions

      case UserRole.manager:
        return [
          // ✅ Inventory: view, create, edit, delete, export
          Permission.inventoryView,
          Permission.inventoryCreate,
          Permission.inventoryEdit,
          Permission.inventoryDelete,
          Permission.inventoryExport,
          // ✅ Serial: view, manage
          Permission.serialView,
          Permission.serialManage,
          // ✅ Orders: view, create, edit, delete, confirm, cancel
          Permission.orderView,
          Permission.orderCreate,
          Permission.orderEdit,
          Permission.orderDelete,
          Permission.orderConfirm,
          Permission.orderCancel,
          // ✅ Category: view, manage
          Permission.categoryView,
          Permission.categoryManage,
          // ✅ Users: NO ACCESS (only Admin)
          // ✅ Reports: view, export
          Permission.reportsView,
          Permission.reportsExport,
        ];

      case UserRole.staff:
        return [
          // ✅ Inventory: view, create, edit (NO delete, NO export)
          Permission.inventoryView,
          Permission.inventoryCreate,
          Permission.inventoryEdit,
          // ✅ Serial: view, manage
          Permission.serialView,
          Permission.serialManage,
          // ✅ Orders: view, create, edit (NO delete, NO confirm, NO cancel)
          Permission.orderView,
          Permission.orderCreate,
          Permission.orderEdit,
          // ✅ Category: view only (NO manage)
          Permission.categoryView,
          // ✅ Users: NO ACCESS
          // ✅ Reports: view only (NO export)
          Permission.reportsView,
        ];

      case UserRole.viewer:
        return [
          // ✅ Inventory: view only
          Permission.inventoryView,
          // ✅ Serial: view only (NO manage)
          Permission.serialView,
          // ✅ Orders: view only
          Permission.orderView,
          // ✅ Category: view only
          Permission.categoryView,
          // ✅ Users: NO ACCESS
          // ✅ Reports: view only
          Permission.reportsView,
        ];
    }
  }
}

// ✅ Permission Extensions
extension PermissionExtension on Permission {
  String get displayName {
    switch (this) {
      case Permission.inventoryView:
        return 'View Inventory';
      case Permission.inventoryCreate:
        return 'Create Inventory Items';
      case Permission.inventoryEdit:
        return 'Edit Inventory Items';
      case Permission.inventoryDelete:
        return 'Delete Inventory Items';
      case Permission.inventoryExport:
        return 'Export Inventory Data';
      case Permission.serialView:
        return 'View Serial Numbers';
      case Permission.serialManage:
        return 'Manage Serial Numbers';
      case Permission.orderView:
        return 'View Orders';
      case Permission.orderCreate:
        return 'Create Orders';
      case Permission.orderEdit:
        return 'Edit Orders';
      case Permission.orderDelete:
        return 'Delete Orders';
      case Permission.orderConfirm:
        return 'Confirm Orders';
      case Permission.orderCancel:
        return 'Cancel Orders';
      case Permission.categoryView:
        return 'View Categories';
      case Permission.categoryManage:
        return 'Manage Categories';
      case Permission.userView:
        return 'View Users';
      case Permission.userCreate:
        return 'Create Users';
      case Permission.userEdit:
        return 'Edit Users';
      case Permission.userDelete:
        return 'Delete Users';
      case Permission.reportsView:
        return 'View Reports';
      case Permission.reportsExport:
        return 'Export Reports';
    }
  }

  String get category {
    if (this.name.startsWith('inventory')) return 'Inventory';
    if (this.name.startsWith('serial')) return 'Serial Numbers';
    if (this.name.startsWith('order')) return 'Orders';
    if (this.name.startsWith('category')) return 'Categories';
    if (this.name.startsWith('user')) return 'User Management';
    if (this.name.startsWith('reports')) return 'Reports';
    return 'Other';
  }
}
