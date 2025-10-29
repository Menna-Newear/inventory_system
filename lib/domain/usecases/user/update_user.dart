// ✅ domain/usecases/user/update_user.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

class UpdateUser implements UseCase<User, UpdateUserParams> {
  final UserRepository repository;

  UpdateUser(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateUserParams params) async {
    return await repository.updateUser(
      userId: params.userId,
      name: params.name,
      role: params.role,
      permissions: params.permissions,
      isActive: params.isActive,
    );
  }
}

class UpdateUserParams extends Equatable {
  final String userId;
  final String? name;
  final UserRole? role;
  final List<Permission>? permissions;
  final bool? isActive;

  const UpdateUserParams({
    required this.userId,
    this.name,
    this.role,
    this.permissions,
    this.isActive,
  });

  @override
  List<Object?> get props => [userId, name, role, permissions, isActive];
}
