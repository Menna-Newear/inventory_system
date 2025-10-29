// ✅ domain/usecases/user/delete_user.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/user_repository.dart';

class DeleteUser implements UseCase<void, DeleteUserParams> {
  final UserRepository repository;

  DeleteUser(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteUserParams params) async {
    return await repository.deleteUser(params.userId);
  }
}

class DeleteUserParams extends Equatable {
  final String userId;

  const DeleteUserParams(this.userId);

  @override
  List<Object> get props => [userId];
}
