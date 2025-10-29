// ✅ data/repositories/auth_repository_impl.dart (COMPLETE - NO EXPORTS)
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 AUTH REPO: Attempting login for $email');

      final user = await remoteDataSource.login(email, password);

      debugPrint('✅ AUTH REPO: Login successful - ${user.name}');
      return Right(user.toEntity());
    } on UnauthorizedException catch (e) {
      debugPrint('❌ AUTH REPO: Unauthorized - ${e.message}');
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      debugPrint('❌ AUTH REPO: Login failed - ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('❌ AUTH REPO: Unexpected error - $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      debugPrint('🚪 AUTH REPO: Logging out');
      await remoteDataSource.logout();
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      debugPrint('🔍 AUTH REPO: Checking for current user session');

      final user = await remoteDataSource.getCurrentUser();

      debugPrint('✅ AUTH REPO: Session found - ${user.name}');
      return Right(user.toEntity());
    } on UnauthorizedException catch (e) {
      debugPrint('⚠️ AUTH REPO: No active session');
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      debugPrint('❌ AUTH REPO: Server error - ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('❌ AUTH REPO: Unexpected error - $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> refreshSession() async {
    try {
      debugPrint('🔄 AUTH REPO: Refreshing session');

      final user = await remoteDataSource.refreshSession();

      debugPrint('✅ AUTH REPO: Session refreshed - ${user.name}');
      return Right(user.toEntity());
    } on UnauthorizedException catch (e) {
      debugPrint('❌ AUTH REPO: Refresh failed - ${e.message}');
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      debugPrint('❌ AUTH REPO: Server error - ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('❌ AUTH REPO: Unexpected error - $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
