// ✅ data/datasources/auth_remote_data_source.dart (WITH DEFAULT PERMISSIONS FIX!)
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<UserModel> refreshSession();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  // ✅ Helper method to parse permissions from database
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

// ✅ FIXED: Always use default permissions based on role
  Future<UserModel> _fetchUserProfile(String userId) async {
    final userData = await supabaseClient
        .from('users')
        .select('*, user_permissions(permission)')
        .eq('id', userId)
        .single();

    // Parse role FIRST
    final role = UserRole.values.firstWhere(
          (r) => r.name == userData['role'],
      orElse: () => UserRole.viewer,
    );

    // ✅ ALWAYS use default permissions for the role (ignore database)
    final effectivePermissions = role.defaultPermissions;

    debugPrint('🔍 AUTH DS: User role: ${role.name}');
    debugPrint('✅ AUTH DS: Using default permissions for role');
    debugPrint('✅ AUTH DS: Effective permissions: ${effectivePermissions.map((p) => p.name).toList()}');

    return UserModel(
      id: userData['id'],
      email: userData['email'],
      name: userData['name'],
      role: role,
      permissions: effectivePermissions, // ✅ Use role defaults
      isActive: userData['is_active'] ?? true,
      createdAt: DateTime.parse(userData['created_at']),
      lastLogin: userData['last_login'] != null
          ? DateTime.parse(userData['last_login'])
          : null,
      avatarUrl: userData['avatar_url'],
    );
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      debugPrint('🔐 AUTH DS: Attempting login for $email...');

      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw UnauthorizedException('Login failed');
      }

      final userId = response.user!.id;
      debugPrint('✅ AUTH DS: Login successful - $userId');

      // Update last login
      await supabaseClient.from('users').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Fetch user profile
      final user = await _fetchUserProfile(userId);

      // Return with updated last login
      return UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        permissions: user.permissions,
        isActive: user.isActive,
        createdAt: user.createdAt,
        lastLogin: DateTime.now(),
        avatarUrl: user.avatarUrl,
      );
    } on AuthException catch (e) {
      debugPrint('❌ AUTH DS: Auth error - ${e.message}');
      throw UnauthorizedException(e.message);
    } catch (e) {
      debugPrint('❌ AUTH DS: Login error - $e');
      throw ServerException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      debugPrint('🚪 AUTH DS: Logging out...');
      await supabaseClient.auth.signOut(scope: SignOutScope.global);
      debugPrint('✅ AUTH DS: Logged out successfully');
    } catch (e) {
      debugPrint('❌ AUTH DS: Logout error - $e');
      throw ServerException('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final session = supabaseClient.auth.currentSession;

      if (session == null) {
        throw UnauthorizedException('No active session');
      }

      final userId = session.user.id;

      // Fetch user profile
      return await _fetchUserProfile(userId);
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      debugPrint('❌ AUTH DS: Get current user error - $e');
      throw ServerException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> refreshSession() async {
    try {
      debugPrint('🔄 AUTH DS: Refreshing session...');

      // Refresh the session
      final response = await supabaseClient.auth.refreshSession();

      if (response.user == null) {
        throw UnauthorizedException('Session refresh failed');
      }

      final userId = response.user!.id;
      debugPrint('✅ AUTH DS: Session refreshed - $userId');

      // Fetch user profile
      return await _fetchUserProfile(userId);
    } on AuthException catch (e) {
      debugPrint('❌ AUTH DS: Refresh error - ${e.message}');
      throw UnauthorizedException(e.message);
    } catch (e) {
      debugPrint('❌ AUTH DS: Refresh session error - $e');
      throw ServerException('Failed to refresh session: ${e.toString()}');
    }
  }
}
