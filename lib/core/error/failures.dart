// core/error/failures.dart
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

/// Thrown when attempting to create a category with a name that already exists
class DuplicateNameFailure extends Failure {
  const DuplicateNameFailure(String message) : super(message);
}

/// Thrown when attempting to access a category that doesn't exist
class CategoryNotFoundFailure extends Failure {
  const CategoryNotFoundFailure(String message) : super(message);
}

/// Thrown when attempting to delete a category that is still being used by inventory items
class CategoryInUseFailure extends Failure {
  const CategoryInUseFailure(String message) : super(message);
}

/// Thrown when category operation violates business rules
class CategoryConstraintFailure extends Failure {
  const CategoryConstraintFailure(String message) : super(message);
}

// ===================================
// FILE/MEDIA FAILURES
// ===================================

/// Thrown when file upload operations fail
class FileUploadFailure extends Failure {
  const FileUploadFailure(String message) : super(message);
}

/// Thrown when file is too large or invalid format
class InvalidFileFailure extends Failure {
  const InvalidFileFailure(String message) : super(message);
}

/// Thrown when file download operations fail
class FileDownloadFailure extends Failure {
  const FileDownloadFailure(String message) : super(message);
}

// ===================================
// IMPORT/EXPORT FAILURES
// ===================================

/// Thrown when CSV import operations fail
class ImportFailure extends Failure {
  const ImportFailure(String message) : super(message);
}

/// Thrown when export operations fail
class ExportFailure extends Failure {
  const ExportFailure(String message) : super(message);
}

/// Thrown when file format is not supported
class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure(String message) : super(message);
}

// ===================================
// QR CODE FAILURES
// ===================================

/// Thrown when QR code generation fails
class QrCodeGenerationFailure extends Failure {
  const QrCodeGenerationFailure(String message) : super(message);
}

/// Thrown when QR code scanning fails
class QrCodeScanFailure extends Failure {
  const QrCodeScanFailure(String message) : super(message);
}

/// Thrown when QR code data is invalid or corrupted
class InvalidQrDataFailure extends Failure {
  const InvalidQrDataFailure(String message) : super(message);
}

// ===================================
// SEARCH/FILTER FAILURES
// ===================================

/// Thrown when search operations fail
class SearchFailure extends Failure {
  const SearchFailure(String message) : super(message);
}

/// Thrown when filter operations fail
class FilterFailure extends Failure {
  const FilterFailure(String message) : super(message);
}

// ===================================
// BUSINESS RULE FAILURES
// ===================================

/// Thrown when business rules are violated
class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure(String message) : super(message);
}

/// Thrown when data constraints are violated
class DataConstraintFailure extends Failure {
  const DataConstraintFailure(String message) : super(message);
}

/// Thrown when concurrent modification occurs
class ConcurrencyFailure extends Failure {
  const ConcurrencyFailure(String message) : super(message);
}

// ===================================
// HELPER EXTENSIONS
// ===================================

/// Extension to provide user-friendly error messages
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
        return 'Authentication failed. Please log in again.';
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
      this is NetworkFailure ||
          this is ServerFailure;

  bool get isUserActionable =>
      this is ValidationFailure ||
          this is DuplicateSkuFailure ||
          this is DuplicateNameFailure ||
          this is CategoryInUseFailure;

  bool get requiresRetry =>
      this is NetworkFailure ||
          this is ServerFailure ||
          this is CacheFailure;
}
