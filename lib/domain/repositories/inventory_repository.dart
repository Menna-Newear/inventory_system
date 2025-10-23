// domain/repositories/inventory_repository.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/inventory_item.dart';

abstract class InventoryRepository {

  Future<Either<Failure, List<InventoryItem>>> getAllInventoryItems();
  Future<Either<Failure, InventoryItem>> getInventoryItem(String id);
  Future<Either<Failure, InventoryItem>> createInventoryItem(InventoryItem item);
  Future<Either<Failure, InventoryItem>> updateInventoryItem(InventoryItem item);
  Future<Either<Failure, void>> deleteInventoryItem(String id);

  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(String query);
  Future<Either<Failure, List<InventoryItem>>> filterInventoryItems(Map<String, dynamic> filters);
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems();
  Stream<List<InventoryItem>> watchInventoryItems();
  Future<Either<Failure, List<InventoryItem>>> getInventoryItemsPaginated({
    required int page,
    required int pageSize,
  });
  Future<Either<Failure, int>> getTotalItemCount();

  Future<Either<Failure, List<SerialNumber>>> addSerialNumbers(
      String itemId,
      List<SerialNumber> serialNumbers,
      );

  /// Get all serial numbers for a specific inventory item
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbers(String itemId);

  /// Update the status of a single serial number
  Future<Either<Failure, SerialNumber>> updateSerialStatus(
      String serialId,
      SerialStatus newStatus, {
        String? notes,
      });

  /// Delete a single serial number
  Future<Either<Failure, void>> deleteSerialNumber(String serialId);

  /// Get all serial numbers with a specific status across all items
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbersByStatus(SerialStatus status);

  /// Check if a serial number already exists in the system
  Future<Either<Failure, bool>> serialNumberExists(
      String serialNumber, {
        String? excludeId,
      });

  /// Bulk update multiple serial numbers to the same status
  Future<Either<Failure, List<SerialNumber>>> bulkUpdateSerialStatus(
      List<String> serialIds,
      SerialStatus newStatus, {
        String? notes,
      });

  // ✅ NEW - Advanced Analytics & Statistics
  /// Get comprehensive inventory statistics including serial number metrics
  Future<Either<Failure, Map<String, dynamic>>> getInventoryStats();

  /// Check if a SKU already exists in the system (for validation)
  Future<Either<Failure, bool>> skuExists(String sku, {String? excludeId});

  // ✅ NEW - Utility Methods for Offline Support
  /// Sync offline changes when internet connection is restored
  Future<Either<Failure, void>> syncOfflineChanges();

  // ✅ NEW - Serial Number Reporting & Analysis
  /// Get serial numbers that need attention (e.g., recalled, damaged)
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbersRequiringAttention();

  /// Get serial number history/audit trail for an item
  Future<Either<Failure, List<Map<String, dynamic>>>> getSerialNumberHistory(String itemId);

  /// Generate serial number utilization report
  Future<Either<Failure, Map<String, dynamic>>> getSerialNumberUtilizationReport({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });
}
