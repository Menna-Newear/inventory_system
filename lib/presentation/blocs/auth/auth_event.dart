// ✅ presentation/blocs/auth/auth_event.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// ✅ Core Auth Events
class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

// ✅ User Management Events
class LoadAllUsers extends AuthEvent {}

class CreateUserEvent  extends AuthEvent {
  final String email;
  final String name;
  final String password;
  final UserRole role;
  final List<Permission> permissions;

  const CreateUserEvent ({
    required this.email,
    required this.name,
    required this.password,
    required this.role,
    required this.permissions,
  });

  @override
  List<Object> get props => [email, name, password, role, permissions];
}

class UpdateUserEvent extends AuthEvent {
  final String userId;
  final String? name;
  final UserRole? role;
  final List<Permission>? permissions;
  final bool? isActive;

  const UpdateUserEvent({
    required this.userId,
    this.name,
    this.role,
    this.permissions,
    this.isActive,
  });

  @override
  List<Object?> get props => [userId, name, role, permissions, isActive];
}

class DeleteUserEvent  extends AuthEvent {
  final String userId;

  const DeleteUserEvent (this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateUserPasswordEvent  extends AuthEvent {
  final String userId;
  final String newPassword;

  const UpdateUserPasswordEvent ({
    required this.userId,
    required this.newPassword,
  });

  @override
  List<Object> get props => [userId, newPassword];
}

class UpdateCurrentUserProfile extends AuthEvent {
  final String? name;
  final String? avatarUrl;

  const UpdateCurrentUserProfile({this.name, this.avatarUrl});

  @override
  List<Object?> get props => [name, avatarUrl];
}

class ChangePassword extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}
