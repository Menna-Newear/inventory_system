// domain/usecases/create_category.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class CreateCategory implements UseCase<Category, CreateCategoryParams> {
  final CategoryRepository repository;

  CreateCategory(this.repository);

  @override
  Future<Either<Failure, Category>> call(CreateCategoryParams params) async {
    return await repository.createCategory(params.category);
  }
}

class CreateCategoryParams extends Equatable {
  final Category category;

  const CreateCategoryParams(this.category);

  @override
  List<Object> get props => [category];
}
