// ✅ domain/usecases/user/get_all_users.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

class GetAllUsers implements UseCase<List<User>, NoParams> {
  final UserRepository repository;

  GetAllUsers(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(NoParams params) async {
    return await repository.getAllUsers();
  }
}
