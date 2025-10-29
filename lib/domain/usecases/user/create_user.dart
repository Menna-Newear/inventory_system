
// ✅ domain/usecases/user/create_user.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

class CreateUser implements UseCase<User, CreateUserParams> {
  final UserRepository repository;

  CreateUser(this.repository);

  @override
  Future<Either<Failure, User>> call(CreateUserParams params) async {
    return await repository.createUser(
      email: params.email,
      name: params.name,
      password: params.password,
      role: params.role,
      permissions: params.permissions,
    );
  }
}

class CreateUserParams extends Equatable {
  final String email;
  final String name;
  final String password;
  final UserRole role;
  final List<Permission> permissions;

  const CreateUserParams({
    required this.email,
    required this.name,
    required this.password,
    required this.role,
    required this.permissions,
  });

  @override
  List<Object> get props => [email, name, password, role, permissions];
}

