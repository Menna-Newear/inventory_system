// domain/repositories/category_repository.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getAllCategories();
  Future<Either<Failure, Category>> createCategory(Category category);
  Future<Either<Failure, void>> deleteCategory(String id);
}
