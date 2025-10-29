// ✅ presentation/blocs/auth/auth_state.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final List<User>? allUsers; // For admin user management

  const Authenticated({
    required this.user,
    this.allUsers,
  });

  @override
  List<Object?> get props => [user, allUsers];

  Authenticated copyWith({
    User? user,
    List<User>? allUsers,
  }) {
    return Authenticated(
      user: user ?? this.user,
      allUsers: allUsers ?? this.allUsers,
    );
  }
}

class Unauthenticated extends AuthState {
  final String? message;

  const Unauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class UserManagementLoading extends AuthState {
  final User currentUser;

  const UserManagementLoading(this.currentUser);

  @override
  List<Object> get props => [currentUser];
}

class UserCreated extends AuthState {
  final User newUser;

  const UserCreated(this.newUser);

  @override
  List<Object> get props => [newUser];
}

class UserUpdated extends AuthState {
  final User updatedUser;

  const UserUpdated(this.updatedUser);

  @override
  List<Object> get props => [updatedUser];
}

class UserDeleted extends AuthState {
  final String userId;

  const UserDeleted(this.userId);

  @override
  List<Object> get props => [userId];
}
