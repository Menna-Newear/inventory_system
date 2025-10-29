// ✅ core/error/failures.dart (ENHANCED WITH AUTH FAILURES)
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// ===================================
// GENERAL FAILURES
// ===================================

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

// ===================================
// ✅ NEW: AUTH-SPECIFIC FAILURES
// ===================================

class AuthFailure extends Failure {
  final String? code;

  const AuthFailure(String message, {this.code}) : super(message);

  @override
  List<Object> get props => code != null ? [message, code!] : [message];  // ✅ CORRECT
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(String message) : super(message);
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure(String message) : super(message);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure(String message) : super(message);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure(String message) : super(message);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure(String message) : super(message);
}

class UserAlreadyExistsFailure extends Failure {
  const UserAlreadyExistsFailure(String message) : super(message);
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure(String message) : super(message);
}

// ===================================
// INVENTORY-SPECIFIC FAILURES
// ===================================

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

// ===================================
// CATEGORY-SPECIFIC FAILURES
// ===================================

class DuplicateNameFailure extends Failure {
  const DuplicateNameFailure(String message) : super(message);
}

class CategoryNotFoundFailure extends Failure {
  const CategoryNotFoundFailure(String message) : super(message);
}

class CategoryInUseFailure extends Failure {
  const CategoryInUseFailure(String message) : super(message);
}

class CategoryConstraintFailure extends Failure {
  const CategoryConstraintFailure(String message) : super(message);
}

// ===================================
// FILE/MEDIA FAILURES
// ===================================

class FileUploadFailure extends Failure {
  const FileUploadFailure(String message) : super(message);
}

class InvalidFileFailure extends Failure {
  const InvalidFileFailure(String message) : super(message);
}

class FileDownloadFailure extends Failure {
  const FileDownloadFailure(String message) : super(message);
}

// ===================================
// IMPORT/EXPORT FAILURES
// ===================================

class ImportFailure extends Failure {
  const ImportFailure(String message) : super(message);
}

class ExportFailure extends Failure {
  const ExportFailure(String message) : super(message);
}

class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure(String message) : super(message);
}

// ===================================
// QR CODE FAILURES
// ===================================

class QrCodeGenerationFailure extends Failure {
  const QrCodeGenerationFailure(String message) : super(message);
}

class QrCodeScanFailure extends Failure {
  const QrCodeScanFailure(String message) : super(message);
}

class InvalidQrDataFailure extends Failure {
  const InvalidQrDataFailure(String message) : super(message);
}

// ===================================
// SEARCH/FILTER FAILURES
// ===================================

class SearchFailure extends Failure {
  const SearchFailure(String message) : super(message);
}

class FilterFailure extends Failure {
  const FilterFailure(String message) : super(message);
}

// ===================================
// BUSINESS RULE FAILURES
// ===================================

class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure(String message) : super(message);
}

class DataConstraintFailure extends Failure {
  const DataConstraintFailure(String message) : super(message);
}

class ConcurrencyFailure extends Failure {
  const ConcurrencyFailure(String message) : super(message);
}

// ===================================
// HELPER EXTENSIONS
// ===================================

extension FailureExtension on Failure {
  String get userFriendlyMessage {
    switch (runtimeType) {
      case ServerFailure:
        return 'Server error occurred. Please try again later.';
      case NetworkFailure:
        return 'Please check your internet connection and try again.';
      case CacheFailure:
        return 'Local storage error. Please restart the app.';
      case ValidationFailure:
        return 'Please check your input and try again.';
      case AuthenticationFailure:
      case AuthFailure:
      case InvalidCredentialsFailure:
        return 'Authentication failed. Please check your credentials.';
      case UnauthorizedFailure:
      case SessionExpiredFailure:
        return 'Your session has expired. Please log in again.';
      case PermissionDeniedFailure:
      case PermissionFailure:
        return 'You don\'t have permission to perform this action.';
      case UserNotFoundFailure:
        return 'User not found. Please check the information.';
      case UserAlreadyExistsFailure:
        return 'A user with this email already exists.';
      case WeakPasswordFailure:
        return 'Password is too weak. Please use a stronger password.';
      case ItemNotFoundFailure:
        return 'The requested item could not be found.';
      case DuplicateSkuFailure:
        return 'This SKU already exists. Please use a different one.';
      case CategoryInUseFailure:
        return 'Cannot delete this category as it contains items.';
      case DuplicateNameFailure:
        return 'This name already exists. Please choose a different name.';
      case FileUploadFailure:
        return 'Failed to upload file. Please try again.';
      case ImportFailure:
        return 'Failed to import data. Please check your file format.';
      case QrCodeGenerationFailure:
        return 'Failed to generate QR code. Please try again.';
      default:
        return message.isNotEmpty ? message : 'An unexpected error occurred.';
    }
  }

  String get logMessage => '${runtimeType}: $message';

  bool get isNetworkRelated =>
      this is NetworkFailure || this is ServerFailure;

  bool get isAuthRelated =>
      this is AuthenticationFailure ||
          this is AuthFailure ||
          this is UnauthorizedFailure ||
          this is PermissionDeniedFailure ||
          this is SessionExpiredFailure ||
          this is InvalidCredentialsFailure;

  bool get isUserActionable =>
      this is ValidationFailure ||
          this is DuplicateSkuFailure ||
          this is DuplicateNameFailure ||
          this is CategoryInUseFailure ||
          this is WeakPasswordFailure ||
          this is UserAlreadyExistsFailure;

  bool get requiresRetry =>
      this is NetworkFailure ||
          this is ServerFailure ||
          this is CacheFailure;

  bool get requiresReauth =>
      this is UnauthorizedFailure ||
          this is SessionExpiredFailure;
}
