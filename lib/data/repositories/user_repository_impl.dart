// data/repositories/user_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<User>>> getAllUsers() async {
    try {
      final users = await remoteDataSource.getAllUsers();
      return Right(users.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> createUser({
    required String email,
    required String name,
    required String password,
    required UserRole role,
    required List<Permission> permissions,
  }) async {
    try {
      debugPrint('👤 USER REPO: Creating user $email...');

      final user = await remoteDataSource.createUser(
        email: email,
        name: name,
        password: password,
        role: role,
        permissions: permissions,
      );

      debugPrint('✅ USER REPO: User created successfully');
      return Right(user.toEntity());
    } on ServerException catch (e) {
      debugPrint('❌ USER REPO: Create user failed - ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('❌ USER REPO: Unexpected error - $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser({
    required String userId,
    String? name,
    UserRole? role,
    List<Permission>? permissions,
    bool? isActive,
  }) async {
    try {
      final user = await remoteDataSource.updateUser(
        userId: userId,
        name: name,
        role: role,
        permissions: permissions,
        isActive: isActive,
      );
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await remoteDataSource.deleteUser(userId);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.updateUserPassword(
        userId: userId,
        newPassword: newPassword,
      );
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
