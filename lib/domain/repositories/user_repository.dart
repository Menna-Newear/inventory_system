// ✅ domain/repositories/user_repository.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, List<User>>> getAllUsers();

  Future<Either<Failure, User>> createUser({
    required String email,
    required String name,
    required String password,
    required UserRole role,
    required List<Permission> permissions,
  });

  Future<Either<Failure, User>> updateUser({
    required String userId,
    String? name,
    UserRole? role,
    List<Permission>? permissions,
    bool? isActive,
  });

  Future<Either<Failure, void>> deleteUser(String userId);

  Future<Either<Failure, void>> updateUserPassword({
    required String userId,
    required String newPassword,
  });
}
