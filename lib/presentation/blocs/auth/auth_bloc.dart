// ✅ presentation/blocs/auth/auth_bloc.dart (FINAL FIXED VERSION!)
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth/login.dart';
import '../../../domain/usecases/auth/logout.dart';
import '../../../domain/usecases/auth/get_current_user.dart';
import '../../../domain/usecases/user/get_all_users.dart';
import '../../../domain/usecases/user/create_user.dart';
import '../../../domain/usecases/user/update_user.dart';
import '../../../domain/usecases/user/delete_user.dart';
import '../../../domain/usecases/user/update_user_password.dart';
import '../../../core/usecases/usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Login loginUseCase;
  final Logout logoutUseCase;
  final GetCurrentUser getCurrentUserUseCase;
  final GetAllUsers getAllUsersUseCase;
  final CreateUser createUserUseCase;
  final UpdateUser updateUserUseCase;
  final DeleteUser deleteUserUseCase;
  final UpdateUserPassword updateUserPasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.getAllUsersUseCase,
    required this.createUserUseCase,
    required this.updateUserUseCase,
    required this.deleteUserUseCase,
    required this.updateUserPasswordUseCase,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoadAllUsers>(_onLoadAllUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<UpdateUserPasswordEvent>(_onUpdateUserPassword);
    on<UpdateCurrentUserProfile>(_onUpdateCurrentUserProfile);
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final result = await getCurrentUserUseCase(NoParams());

      result.fold(
            (failure) {
          debugPrint('⚠️ AUTH: No active session - showing login page');
          emit(Unauthenticated());
        },
            (user) {
          debugPrint('✅ AUTH: User session found - ${user.name}');
          emit(Authenticated(user: user));
        },
      );
    } catch (e) {
      debugPrint('⚠️ AUTH: Error checking session - $e');
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    debugPrint('🔐 AUTH: Login attempt for ${event.email}');

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
          (failure) {
        debugPrint('❌ AUTH: Login failed - ${failure.message}');
        emit(Unauthenticated(message: failure.message));
      },
          (user) {
        debugPrint('✅ AUTH: Login successful - ${user.name} (${user.role.displayName})');
        emit(Authenticated(user: user));
      },
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    debugPrint('🚪 AUTH: Logout requested');

    await logoutUseCase(NoParams());
    emit(Unauthenticated(message: 'Logged out successfully'));
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event,
      Emitter<AuthState> emit,
      ) async {
    final result = await getCurrentUserUseCase(NoParams());

    result.fold(
          (failure) => emit(Unauthenticated()),
          (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onLoadAllUsers(
      LoadAllUsers event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! Authenticated) return;

    final currentUser = (state as Authenticated).user;

    if (!currentUser.hasPermission(Permission.userView)) {
      emit(AuthError('You don\'t have permission to view users'));
      emit(Authenticated(user: currentUser));
      return;
    }

    emit(UserManagementLoading(currentUser));

    debugPrint('👥 AUTH: Loading all users...');

    final result = await getAllUsersUseCase(NoParams());

    result.fold(
          (failure) {
        debugPrint('❌ AUTH: Failed to load users - ${failure.message}');
        emit(AuthError(failure.message));
        emit(Authenticated(user: currentUser));
      },
          (users) {
        debugPrint('✅ AUTH: Loaded ${users.length} users');
        emit(Authenticated(user: currentUser, allUsers: users));
      },
    );
  }

  Future<void> _onCreateUser(
      CreateUserEvent event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! Authenticated) return;

    final currentUser = (state as Authenticated).user;

    if (!currentUser.hasPermission(Permission.userCreate)) {
      emit(AuthError('You don\'t have permission to create users'));
      emit(Authenticated(user: currentUser));
      return;
    }

    emit(UserManagementLoading(currentUser));

    debugPrint('➕ AUTH: Creating user ${event.email}...');

    final result = await createUserUseCase(
      CreateUserParams(
        email: event.email,
        name: event.name,
        password: event.password,
        role: event.role,
        permissions: event.permissions,
      ),
    );

    await result.fold(
          (failure) async {
        debugPrint('❌ AUTH: Failed to create user - ${failure.message}');
        emit(AuthError(failure.message));
        emit(Authenticated(user: currentUser));
      },
          (newUser) async {
        debugPrint('✅ AUTH: User created - ${newUser.name}');

        // ✅ FIXED: Directly load updated list and emit Authenticated
        debugPrint('👥 AUTH: Auto-loading updated user list...');
        final usersResult = await getAllUsersUseCase(NoParams());

        usersResult.fold(
              (failure) {
            debugPrint('❌ AUTH: Failed to reload users - ${failure.message}');
            emit(Authenticated(user: currentUser));
          },
              (users) {
            debugPrint('✅ AUTH: Loaded ${users.length} users after creation');
            emit(Authenticated(user: currentUser, allUsers: users));
          },
        );
      },
    );
  }

  Future<void> _onUpdateUser(
      UpdateUserEvent event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! Authenticated) return;

    final currentUser = (state as Authenticated).user;

    if (!currentUser.hasPermission(Permission.userEdit)) {
      emit(AuthError('You don\'t have permission to edit users'));
      emit(Authenticated(user: currentUser));
      return;
    }

    emit(UserManagementLoading(currentUser));

    debugPrint('✏️ AUTH: Updating user ${event.userId}...');

    final result = await updateUserUseCase(
      UpdateUserParams(
        userId: event.userId,
        name: event.name,
        role: event.role,
        permissions: event.permissions,
        isActive: event.isActive,
      ),
    );

    await result.fold(
          (failure) async {
        debugPrint('❌ AUTH: Failed to update user - ${failure.message}');
        emit(AuthError(failure.message));
        emit(Authenticated(user: currentUser));
      },
          (updatedUser) async {
        debugPrint('✅ AUTH: User updated - ${updatedUser.name}');

        // ✅ FIXED: Directly load updated list and emit Authenticated
        debugPrint('👥 AUTH: Auto-loading updated user list...');
        final usersResult = await getAllUsersUseCase(NoParams());

        usersResult.fold(
              (failure) {
            debugPrint('❌ AUTH: Failed to reload users - ${failure.message}');
            emit(Authenticated(user: currentUser));
          },
              (users) {
            debugPrint('✅ AUTH: Loaded ${users.length} users after update');
            emit(Authenticated(user: currentUser, allUsers: users));
          },
        );
      },
    );
  }

  Future<void> _onDeleteUser(
      DeleteUserEvent event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! Authenticated) return;

    final currentUser = (state as Authenticated).user;

    if (!currentUser.hasPermission(Permission.userDelete)) {
      emit(AuthError('You don\'t have permission to delete users'));
      emit(Authenticated(user: currentUser));
      return;
    }

    if (event.userId == currentUser.id) {
      emit(AuthError('You cannot delete your own account'));
      emit(Authenticated(user: currentUser));
      return;
    }

    emit(UserManagementLoading(currentUser));

    debugPrint('🗑️ AUTH: Deleting user ${event.userId}...');

    final result = await deleteUserUseCase(DeleteUserParams(event.userId));

    await result.fold(
          (failure) async {
        debugPrint('❌ AUTH: Failed to delete user - ${failure.message}');
        emit(AuthError(failure.message));
        emit(Authenticated(user: currentUser));
      },
          (_) async {
        debugPrint('✅ AUTH: User deleted');

        // ✅ FIXED: Directly load updated list and emit Authenticated
        debugPrint('👥 AUTH: Auto-loading updated user list...');
        final usersResult = await getAllUsersUseCase(NoParams());

        usersResult.fold(
              (failure) {
            debugPrint('❌ AUTH: Failed to reload users - ${failure.message}');
            emit(Authenticated(user: currentUser));
          },
              (users) {
            debugPrint('✅ AUTH: Loaded ${users.length} users after deletion');
            emit(Authenticated(user: currentUser, allUsers: users));
          },
        );
      },
    );
  }

  Future<void> _onUpdateUserPassword(
      UpdateUserPasswordEvent event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! Authenticated) return;

    final currentUser = (state as Authenticated).user;

    if (event.userId != currentUser.id &&
        !currentUser.hasPermission(Permission.userEdit)) {
      emit(AuthError('You don\'t have permission to change this password'));
      emit(Authenticated(user: currentUser));
      return;
    }

    emit(UserManagementLoading(currentUser));

    debugPrint('🔑 AUTH: Updating password for user ${event.userId}...');

    final result = await updateUserPasswordUseCase(
      UpdateUserPasswordParams(
        userId: event.userId,
        newPassword: event.newPassword,
      ),
    );

    result.fold(
          (failure) {
        debugPrint('❌ AUTH: Failed to update password - ${failure.message}');
        emit(AuthError(failure.message));
        emit(Authenticated(user: currentUser));
      },
          (_) {
        debugPrint('✅ AUTH: Password updated successfully');
        emit(Authenticated(user: currentUser));
      },
    );
  }

  Future<void> _onUpdateCurrentUserProfile(
      UpdateCurrentUserProfile event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! Authenticated) return;

    final currentUser = (state as Authenticated).user;

    emit(UserManagementLoading(currentUser));

    debugPrint('👤 AUTH: Updating current user profile...');

    final result = await updateUserUseCase(
      UpdateUserParams(
        userId: currentUser.id,
        name: event.name,
      ),
    );

    result.fold(
          (failure) {
        debugPrint('❌ AUTH: Failed to update profile - ${failure.message}');
        emit(AuthError(failure.message));
        emit(Authenticated(user: currentUser));
      },
          (updatedUser) {
        debugPrint('✅ AUTH: Profile updated');
        emit(Authenticated(user: updatedUser));
      },
    );
  }

  Future<void> _onChangePassword(
      ChangePassword event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! Authenticated) return;

    final currentUser = (state as Authenticated).user;

    emit(UserManagementLoading(currentUser));

    add(UpdateUserPasswordEvent(
      userId: currentUser.id,
      newPassword: event.newPassword,
    ));
  }
}
