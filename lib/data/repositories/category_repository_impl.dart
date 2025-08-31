// data/repositories/category_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final categoryModels = await remoteDataSource.getAllCategories();
      final categories = categoryModels.map((model) => model.toEntity()).toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch categories: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final categoryModel = CategoryModel.fromEntity(category);
      final createdModel = await remoteDataSource.createCategory(categoryModel);
      return Right(createdModel.toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to create category: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete category: $e'));
    }
  }
}
