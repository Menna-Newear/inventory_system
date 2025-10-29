// ✅ domain/usecases/user/update_user_password.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/user_repository.dart';

class UpdateUserPassword implements UseCase<void, UpdateUserPasswordParams> {
  final UserRepository repository;

  UpdateUserPassword(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserPasswordParams params) async {
    return await repository.updateUserPassword(
      userId: params.userId,
      newPassword: params.newPassword,
    );
  }
}

class UpdateUserPasswordParams extends Equatable {
  final String userId;
  final String newPassword;

  const UpdateUserPasswordParams({
    required this.userId,
    required this.newPassword,
  });

  @override
  List<Object> get props => [userId, newPassword];
}
