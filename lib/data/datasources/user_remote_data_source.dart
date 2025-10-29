// ✅ data/datasources/user_remote_data_source.dart (WITH EDGE FUNCTION)
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserModel>> getAllUsers();
  Future<UserModel> createUser({
    required String email,
    required String name,
    required String password,
    required UserRole role,
    required List<Permission> permissions,
  });
  Future<UserModel> updateUser({
    required String userId,
    String? name,
    UserRole? role,
    List<Permission>? permissions,
    bool? isActive,
  });
  Future<void> deleteUser(String userId);
  Future<void> updateUserPassword({
    required String userId,
    required String newPassword,
  });
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient supabaseClient;

  UserRemoteDataSourceImpl(this.supabaseClient);

  // ✅ Helper method to parse permissions
  Permission? _parsePermission(String permString) {
    final permMap = {
      'inventoryView': Permission.inventoryView,
      'inventoryCreate': Permission.inventoryCreate,
      'inventoryEdit': Permission.inventoryEdit,
      'inventoryDelete': Permission.inventoryDelete,
      'inventoryExport': Permission.inventoryExport,
      'serialView': Permission.serialView,
      'serialManage': Permission.serialManage,
      'orderView': Permission.orderView,
      'orderCreate': Permission.orderCreate,
      'orderEdit': Permission.orderEdit,
      'orderDelete': Permission.orderDelete,
      'orderConfirm': Permission.orderConfirm,
      'orderCancel': Permission.orderCancel,
      'categoryView': Permission.categoryView,
      'categoryManage': Permission.categoryManage,
      'userView': Permission.userView,
      'userCreate': Permission.userCreate,
      'userEdit': Permission.userEdit,
      'userDelete': Permission.userDelete,
      'reportsView': Permission.reportsView,
      'reportsExport': Permission.reportsExport,
    };
    return permMap[permString];
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      debugPrint('👥 USER DS: Fetching all users...');

      final usersData = await supabaseClient
          .from('users')
          .select('*, user_permissions(permission)')
          .order('created_at', ascending: false);

      final users = (usersData as List).map((userData) {
        final List<Permission> permissions = [];
        if (userData['user_permissions'] != null) {
          for (var perm in userData['user_permissions'] as List) {
            final permString = perm['permission'] as String?;
            if (permString != null) {
              final permission = _parsePermission(permString);
              if (permission != null) {
                permissions.add(permission);
              } else {
                debugPrint('⚠️ Unknown permission: $permString');
              }
            }
          }
        }

        final role = UserRole.values.firstWhere(
              (r) => r.name == userData['role'],
          orElse: () => UserRole.viewer,
        );

        return UserModel(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
          role: role,
          permissions: permissions,
          isActive: userData['is_active'] ?? true,
          createdAt: DateTime.parse(userData['created_at']),
          lastLogin: userData['last_login'] != null
              ? DateTime.parse(userData['last_login'])
              : null,
          avatarUrl: userData['avatar_url'],
        );
      }).toList();

      debugPrint('✅ USER DS: Fetched ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('❌ USER DS: Get all users error - $e');
      throw ServerException('Failed to get users: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> createUser({
    required String email,
    required String name,
    required String password,
    required UserRole role,
    required List<Permission> permissions,
  }) async {
    try {
      debugPrint('➕ USER DS: Creating user via Edge Function: $email...');

      // ✅ Call Edge Function instead of admin API
      final response = await supabaseClient.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'name': name,
          'role': role.name,
          'permissions': permissions.map((p) => p.name).toList(),
        },
      );

      debugPrint('📡 USER DS: Edge Function response status: ${response.status}');

      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map
            ? (errorData['error'] ?? 'Failed to create user')
            : 'Failed to create user';
        debugPrint('❌ USER DS: Edge Function error: $errorMessage');
        throw ServerException(errorMessage);
      }

      final responseData = response.data;
      if (responseData == null || responseData['user'] == null) {
        throw ServerException('Invalid response from server');
      }

      final userData = responseData['user'];
      final userId = userData['id'] as String;
      debugPrint('✅ USER DS: User created successfully - $userId');

      // Fetch complete user data with permissions
      final completeUserData = await supabaseClient
          .from('users')
          .select('*, user_permissions(permission)')
          .eq('id', userId)
          .single();

      final List<Permission> userPermissions = [];
      if (completeUserData['user_permissions'] != null) {
        for (var perm in completeUserData['user_permissions'] as List) {
          final permString = perm['permission'] as String?;
          if (permString != null) {
            final permission = _parsePermission(permString);
            if (permission != null) {
              userPermissions.add(permission);
            }
          }
        }
      }

      return UserModel(
        id: completeUserData['id'],
        email: completeUserData['email'],
        name: completeUserData['name'],
        role: role,
        permissions: userPermissions,
        isActive: completeUserData['is_active'] ?? true,
        createdAt: DateTime.parse(completeUserData['created_at']),
        lastLogin: null,
        avatarUrl: completeUserData['avatar_url'],
      );
    } on FunctionException catch (e) {
      debugPrint('❌ USER DS: Function exception - ${e.details}');
      throw ServerException('Failed to create user: ${e.details}');
    } catch (e) {
      debugPrint('❌ USER DS: Create user error - $e');
      throw ServerException('Failed to create user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUser({
    required String userId,
    String? name,
    UserRole? role,
    List<Permission>? permissions,
    bool? isActive,
  }) async {
    try {
      debugPrint('✏️ USER DS: Updating user $userId...');

      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (role != null) updates['role'] = role.name;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isNotEmpty) {
        await supabaseClient.from('users').update(updates).eq('id', userId);
        debugPrint('✅ USER DS: User profile updated');
      }

      if (permissions != null) {
        await supabaseClient.from('user_permissions').delete().eq('user_id', userId);

        if (permissions.isNotEmpty) {
          final permissionRecords = permissions
              .map((perm) => {
            'user_id': userId,
            'permission': perm.name,
          })
              .toList();

          await supabaseClient.from('user_permissions').insert(permissionRecords);
          debugPrint('✅ USER DS: ${permissions.length} permissions updated');
        }
      }

      final userData = await supabaseClient
          .from('users')
          .select('*, user_permissions(permission)')
          .eq('id', userId)
          .single();

      final List<Permission> userPermissions = [];
      if (userData['user_permissions'] != null) {
        for (var perm in userData['user_permissions'] as List) {
          final permString = perm['permission'] as String?;
          if (permString != null) {
            final permission = _parsePermission(permString);
            if (permission != null) {
              userPermissions.add(permission);
            }
          }
        }
      }

      final userRole = UserRole.values.firstWhere(
            (r) => r.name == userData['role'],
        orElse: () => UserRole.viewer,
      );

      return UserModel(
        id: userData['id'],
        email: userData['email'],
        name: userData['name'],
        role: userRole,
        permissions: userPermissions,
        isActive: userData['is_active'] ?? true,
        createdAt: DateTime.parse(userData['created_at']),
        lastLogin: userData['last_login'] != null
            ? DateTime.parse(userData['last_login'])
            : null,
        avatarUrl: userData['avatar_url'],
      );
    } catch (e) {
      debugPrint('❌ USER DS: Update user error - $e');
      throw ServerException('Failed to update user: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      debugPrint('🗑️ USER DS: Deleting user $userId...');

      await supabaseClient.from('user_permissions').delete().eq('user_id', userId);
      await supabaseClient.from('users').delete().eq('id', userId);

      debugPrint('✅ USER DS: User profile deleted');
    } catch (e) {
      debugPrint('❌ USER DS: Delete user error - $e');
      throw ServerException('Failed to delete user: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      debugPrint('🔑 USER DS: Updating password for user $userId...');
      throw ServerException(
        'Password update must be done via Supabase Dashboard or password reset email',
      );
    } catch (e) {
      debugPrint('❌ USER DS: Update password error - $e');
      throw ServerException('Failed to update password: ${e.toString()}');
    }
  }
}
