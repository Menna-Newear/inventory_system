// domain/usecases/delete_category.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/category_repository.dart';

class DeleteCategory implements UseCase<void, DeleteCategoryParams> {
  final CategoryRepository repository;

  DeleteCategory(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCategoryParams params) async {
    return await repository.deleteCategory(params.categoryId);
  }
}

class DeleteCategoryParams {
  final String categoryId;

  DeleteCategoryParams(this.categoryId);
}
