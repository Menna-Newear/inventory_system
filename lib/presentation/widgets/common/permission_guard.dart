// ✅ presentation/widgets/common/permission_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_state.dart';

class PermissionGuard extends StatelessWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    Key? key,
    required this.permission,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          if (state.user.hasPermission(permission)) {
            return child;
          }
        }
        return fallback ?? SizedBox.shrink();
      },
    );
  }
}

// ✅ Multiple permissions guard
class MultiPermissionGuard extends StatelessWidget {
  final List<Permission> permissions;
  final bool requireAll; // true = need ALL, false = need ANY
  final Widget child;
  final Widget? fallback;

  const MultiPermissionGuard({
    Key? key,
    required this.permissions,
    this.requireAll = true,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final hasPermission = requireAll
              ? state.user.hasAllPermissions(permissions)
              : state.user.hasAnyPermission(permissions);

          if (hasPermission) {
            return child;
          }
        }
        return fallback ?? SizedBox.shrink();
      },
    );
  }
}
