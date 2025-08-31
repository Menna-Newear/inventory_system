// core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}

// Specific business logic failures
class ItemNotFoundFailure extends Failure {
  const ItemNotFoundFailure(String message) : super(message);
}

class DuplicateSkuFailure extends Failure {
  const DuplicateSkuFailure(String message) : super(message);
}

class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure(String message) : super(message);
}

class InvalidOperationFailure extends Failure {
  const InvalidOperationFailure(String message) : super(message);
}
