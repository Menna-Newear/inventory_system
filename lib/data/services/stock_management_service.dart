// ✅ data/services/stock_management_service.dart
import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../core/error/failures.dart';

class StockManagementService {
  final InventoryRepository inventoryRepository;

  StockManagementService({required this.inventoryRepository});

  /// Updates stock levels and serial statuses when order status changes
  Future<Either<Failure, void>> handleOrderStatusChange(
      Order order,
      OrderStatus oldStatus,
      OrderStatus newStatus,
      ) async {
    print('🔍 STOCK SERVICE: Starting handleOrderStatusChange');
    print('🔍 STOCK SERVICE: Order ${order.orderNumber} (${order.orderType.displayName})');
    print('🔍 STOCK SERVICE: Status change: $oldStatus → $newStatus');
    print('🔍 STOCK SERVICE: Items count: ${order.items.length}');

    if (!_shouldUpdateStock(oldStatus, newStatus)) {
      print('❌ STOCK SERVICE: No stock update needed, returning');
      return Right(null);
    }

    print('📦 STOCK SERVICE: Processing stock change for order ${order.orderNumber}: $oldStatus → $newStatus');

    try {
      bool anyStockChanged = false;
      List<String> updatedItemIds = [];

      // ✅ STEP 1: Update stock quantities
      for (final orderItem in order.items) {
        print('🔍 STOCK SERVICE: Processing item ${orderItem.itemName} (ID: ${orderItem.itemId})');

        final stockChange = _calculateStockChange(order, orderItem, oldStatus, newStatus);
        print('🔍 STOCK SERVICE: Calculated stock change: $stockChange');

        if (stockChange != 0) {
          final result = await _updateItemStock(
            orderItem.itemId,
            stockChange,
            _getUpdateReason(order, newStatus),
          );

          if (result.isLeft()) {
            print('❌ STOCK SERVICE: Stock update failed for item ${orderItem.itemName}');
            return result.fold((l) => Left(l), (r) => throw Exception());
          }

          print('✅ STOCK SERVICE: Stock updated successfully for item ${orderItem.itemName}');
          anyStockChanged = true;
          updatedItemIds.add(orderItem.itemId);
        } else {
          print('➡️ STOCK SERVICE: No stock change needed for item ${orderItem.itemName}');
        }
      }

      // ✅ STEP 2: Update serial statuses
      if (anyStockChanged) {
        print('🔄 STOCK SERVICE: Stock changed - now updating serial statuses');
        final serialResult = await _updateSerialStatuses(order, oldStatus, newStatus);
        if (serialResult.isLeft()) {
          print('⚠️ STOCK SERVICE: Serial status update failed but stock was updated');
          // Continue anyway - stock is more critical than serial status
        }
      }

      // ✅ STEP 3: Notify inventory refresh
      if (anyStockChanged) {
        print('🔄 STOCK SERVICE: Stock changed for ${updatedItemIds.length} items - triggering inventory refresh');
        _notifyInventoryRefresh();
      }

      print('✅ STOCK SERVICE: All stock updates completed successfully');
      return Right(null);
    } catch (e) {
      print('❌ STOCK SERVICE: Exception during stock update: $e');
      return Left(ServerFailure('Stock management error: $e'));
    }
  }

  /// Updates serial statuses when order status changes
  Future<Either<Failure, void>> _updateSerialStatuses(
      Order order,
      OrderStatus oldStatus,
      OrderStatus newStatus,
      ) async {
    print('🔍 STOCK SERVICE: Updating serial statuses for order ${order.orderNumber}');

    try {
      for (final orderItem in order.items) {
        if (orderItem.serialNumbers != null && orderItem.serialNumbers!.isNotEmpty) {
          print('🔍 STOCK SERVICE: Item ${orderItem.itemName} has ${orderItem.serialNumbers!.length} serial numbers');
          print('🔍 STOCK SERVICE: Serial numbers: ${orderItem.serialNumbers}');

          // ✅ NEW: Convert serial number strings to IDs
          final serialIds = await _getSerialIdsByNumbers(orderItem.itemId, orderItem.serialNumbers!);

          if (serialIds.isEmpty) {
            print('⚠️ STOCK SERVICE: No serial IDs found for serial numbers: ${orderItem.serialNumbers}');
            print('⚠️ STOCK SERVICE: Skipping serial status update for ${orderItem.itemName}');
            continue;
          }

          print('🔍 STOCK SERVICE: Found ${serialIds.length} serial IDs to update');

          final serialStatus = _getSerialStatusForOrder(newStatus, order.orderType);
          print('🔍 STOCK SERVICE: Updating serials to status: $serialStatus');

          final result = await inventoryRepository.bulkUpdateSerialStatus(
            serialIds,
            serialStatus,
          );

          if (result.isLeft()) {
            print('❌ STOCK SERVICE: Failed to update serial statuses for ${orderItem.itemName}');
            return result;
          }

          print('✅ STOCK SERVICE: Serial statuses updated successfully for ${orderItem.itemName}');
        } else {
          print('➡️ STOCK SERVICE: No serial numbers to update for ${orderItem.itemName}');
        }
      }

      print('✅ STOCK SERVICE: All serial statuses updated successfully');
      return Right(null);
    } catch (e) {
      print('❌ STOCK SERVICE: Exception during serial status update: $e');
      return Left(ServerFailure('Failed to update serial statuses: $e'));
    }
  }

  /// ✅ NEW: Helper method to convert serial number strings to IDs
  Future<List<String>> _getSerialIdsByNumbers(String itemId, List<String> serialNumbers) async {
    try {
      print('🔍 STOCK SERVICE: Looking up serial IDs for ${serialNumbers.length} serial numbers');
      print('🔍 STOCK SERVICE: Item ID: $itemId');
      print('🔍 STOCK SERVICE: Serial numbers to find: $serialNumbers');

      final itemsResult = await inventoryRepository.getAllInventoryItems();
      if (itemsResult.isLeft()) {
        print('❌ STOCK SERVICE: Failed to get inventory items for serial lookup');
        return [];
      }

      final items = itemsResult.fold((l) => <InventoryItem>[], (r) => r);
      final item = items.firstWhere(
            (i) => i.id == itemId,
        orElse: () => throw Exception('Item not found'),
      );

      print('🔍 STOCK SERVICE: Found item ${item.nameEn} with ${item.serialNumbers.length} total serials');

      // Find serial IDs that match the serial number strings
      final matchingSerials = item.serialNumbers
          .where((serial) => serialNumbers.contains(serial.serialNumber))
          .map((serial) => serial.id)
          .toList();

      print('🔍 STOCK SERVICE: Matched ${matchingSerials.length} serial IDs');
      if (matchingSerials.isNotEmpty) {
        print('🔍 STOCK SERVICE: Matched serial IDs: $matchingSerials');
      }

      return matchingSerials;
    } catch (e) {
      print('❌ STOCK SERVICE: Error getting serial IDs: $e');
      return [];
    }
  }

  /// Determines serial status based on order status and type
  SerialStatus _getSerialStatusForOrder(OrderStatus orderStatus, OrderType orderType) {
    final status = switch (orderStatus) {
      OrderStatus.approved => orderType == OrderType.rental ? SerialStatus.rented : SerialStatus.sold,
      OrderStatus.cancelled => SerialStatus.available,
      OrderStatus.rejected => SerialStatus.available,
      OrderStatus.returned => SerialStatus.available,
      OrderStatus.pending => SerialStatus.reserved,
      OrderStatus.draft => SerialStatus.available,
      OrderStatus.processing => orderType == OrderType.rental ? SerialStatus.rented : SerialStatus.sold,
      OrderStatus.shipped => orderType == OrderType.rental ? SerialStatus.rented : SerialStatus.sold,
      OrderStatus.delivered => orderType == OrderType.rental ? SerialStatus.rented : SerialStatus.sold,
    };

    print('🔍 STOCK SERVICE: Serial status for $orderStatus (${orderType.displayName}): $status');
    return status;
  }

  /// Validates if there's enough stock before approving an order
  Future<Either<Failure, void>> validateStockAvailability(Order order) async {
    print('🔍 STOCK SERVICE: Validating stock availability for order ${order.orderNumber}');

    try {
      final itemsResult = await inventoryRepository.getAllInventoryItems();
      if (itemsResult.isLeft()) {
        print('❌ STOCK SERVICE: Failed to get inventory items');
        return itemsResult.fold((l) => Left(l), (r) => throw Exception());
      }

      final items = itemsResult.fold((l) => throw Exception(), (r) => r);
      print('🔍 STOCK SERVICE: Retrieved ${items.length} inventory items for validation');

      for (final orderItem in order.items) {
        try {
          final inventoryItem = items.firstWhere((i) => i.id == orderItem.itemId);
          print('🔍 STOCK SERVICE: Checking ${inventoryItem.nameEn} - Available: ${inventoryItem.stockQuantity}, Required: ${orderItem.quantity}');

          // Check stock availability
          if (inventoryItem.stockQuantity < orderItem.quantity) {
            print('❌ STOCK SERVICE: Insufficient stock for ${inventoryItem.nameEn}');
            return Left(ValidationFailure(
                'Insufficient stock for ${inventoryItem.nameEn}. '
                    'Available: ${inventoryItem.stockQuantity}, Required: ${orderItem.quantity}'
            ));
          }

          // ✅ Validate serial numbers for serial-tracked items
          if (inventoryItem.isSerialTracked) {
            if (orderItem.serialNumbers == null || orderItem.serialNumbers!.isEmpty) {
              print('❌ STOCK SERVICE: Serial-tracked item ${inventoryItem.nameEn} has no serial numbers assigned');
              return Left(ValidationFailure(
                  'Serial-tracked item ${inventoryItem.nameEn} requires serial number selection'
              ));
            }

            if (orderItem.serialNumbers!.length != orderItem.quantity) {
              print('❌ STOCK SERVICE: Serial count mismatch for ${inventoryItem.nameEn}');
              return Left(ValidationFailure(
                  'Serial count mismatch for ${inventoryItem.nameEn}. '
                      'Required: ${orderItem.quantity}, Selected: ${orderItem.serialNumbers!.length}'
              ));
            }

            // ✅ NEW: Validate that serial numbers exist and are available
            print('🔍 STOCK SERVICE: Validating serial numbers: ${orderItem.serialNumbers}');
            final availableSerialNumbers = inventoryItem.serialNumbers
                .where((s) => s.status == SerialStatus.available)
                .map((s) => s.serialNumber)
                .toList();

            for (final serialNumber in orderItem.serialNumbers!) {
              if (!availableSerialNumbers.contains(serialNumber)) {
                print('❌ STOCK SERVICE: Serial number $serialNumber is not available');
                return Left(ValidationFailure(
                    'Serial number $serialNumber for ${inventoryItem.nameEn} is not available'
                ));
              }
            }
            print('✅ STOCK SERVICE: All serial numbers are valid and available');
          }
        } catch (e) {
          print('❌ STOCK SERVICE: Item ${orderItem.itemId} not found in inventory');
          return Left(ValidationFailure('Item ${orderItem.itemId} not found in inventory'));
        }
      }

      print('✅ STOCK SERVICE: Stock validation passed for all ${order.items.length} items');
      return Right(null);
    } catch (e) {
      print('❌ STOCK SERVICE: Exception during stock validation: $e');
      return Left(ServerFailure('Failed to validate stock: $e'));
    }
  }

  /// Determines if stock update is needed based on status transition
  bool _shouldUpdateStock(OrderStatus oldStatus, OrderStatus newStatus) {
    print('🔍 STOCK SERVICE: Checking if stock update is needed: $oldStatus → $newStatus');

    // ✅ REDUCE STOCK: When any order type is approved
    if ((oldStatus == OrderStatus.draft || oldStatus == OrderStatus.pending) &&
        newStatus == OrderStatus.approved) {
      print('✅ STOCK SERVICE: Should reduce stock (approval from draft/pending)');
      return true;
    }

    // ✅ RESTORE STOCK: When approved order is cancelled/rejected
    if (oldStatus == OrderStatus.approved &&
        (newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected)) {
      print('✅ STOCK SERVICE: Should restore stock (cancellation/rejection from approved)');
      return true;
    }

    // ✅ RESTORE STOCK: When any order type is returned
    if (newStatus == OrderStatus.returned && oldStatus != OrderStatus.returned) {
      print('✅ STOCK SERVICE: Should restore stock (order returned)');
      return true;
    }

    print('❌ STOCK SERVICE: No stock update needed for this status change');
    return false;
  }

  /// Calculates the stock change quantity for an item
  int _calculateStockChange(Order order, OrderItem orderItem, OrderStatus oldStatus, OrderStatus newStatus) {
    print('🔍 STOCK SERVICE: Calculating stock change for ${order.orderType.displayName} order');
    print('🔍 STOCK SERVICE: Item: ${orderItem.itemName}, Quantity: ${orderItem.quantity}');
    print('🔍 STOCK SERVICE: Status: $oldStatus → $newStatus');

    // ✅ REDUCE STOCK: When approving any order type
    if (newStatus == OrderStatus.approved &&
        (oldStatus == OrderStatus.draft || oldStatus == OrderStatus.pending)) {
      print('📉 STOCK SERVICE: Reducing stock by ${orderItem.quantity} (approval)');
      return -orderItem.quantity;
    }

    // ✅ RESTORE STOCK: When cancelling/rejecting approved order
    else if ((newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected) &&
        oldStatus == OrderStatus.approved) {
      print('📈 STOCK SERVICE: Restoring stock by ${orderItem.quantity} (${newStatus.displayName} from approved)');
      return orderItem.quantity;
    }

    // ✅ RESTORE STOCK: When returning any order type
    else if (newStatus == OrderStatus.returned && oldStatus != OrderStatus.returned) {
      print('📈 STOCK SERVICE: Restoring stock by ${orderItem.quantity} (returned)');
      return orderItem.quantity;
    }

    print('➡️ STOCK SERVICE: No stock change calculated');
    return 0;
  }

  /// Gets the reason text for the stock update
  String _getUpdateReason(Order order, OrderStatus newStatus) {
    final reason = switch (newStatus) {
      OrderStatus.approved => '${order.orderType.displayName} approved: ${order.orderNumber}',
      OrderStatus.cancelled => '${order.orderType.displayName} cancelled: ${order.orderNumber}',
      OrderStatus.rejected => '${order.orderType.displayName} rejected: ${order.orderNumber}',
      OrderStatus.returned => '${order.orderType.displayName} returned: ${order.orderNumber}',
      _ => '${order.orderType.displayName} status change: ${order.orderNumber}',
    };

    print('🔍 STOCK SERVICE: Update reason: $reason');
    return reason;
  }

  /// Updates the stock quantity for a specific item
  Future<Either<Failure, void>> _updateItemStock(
      String itemId,
      int quantityChange,
      String reason,
      ) async {
    print('🔍 STOCK SERVICE: Updating stock for item $itemId, change: $quantityChange');

    try {
      final itemsResult = await inventoryRepository.getAllInventoryItems();
      if (itemsResult.isLeft()) {
        print('❌ STOCK SERVICE: Failed to get inventory items for update');
        return itemsResult.fold((l) => Left(l), (r) => throw Exception());
      }

      final items = itemsResult.fold((l) => throw Exception(), (r) => r);

      try {
        final item = items.firstWhere((i) => i.id == itemId);
        print('🔍 STOCK SERVICE: Found item ${item.nameEn}, current stock: ${item.stockQuantity}');

        final newStock = item.stockQuantity + quantityChange;
        print('🔍 STOCK SERVICE: New stock will be: $newStock');

        if (newStock < 0) {
          print('❌ STOCK SERVICE: Insufficient stock for update');
          return Left(ValidationFailure(
              'Insufficient stock for ${item.nameEn}. '
                  'Available: ${item.stockQuantity}, Required: ${-quantityChange}'
          ));
        }

        final updatedItem = item.copyWith(
          stockQuantity: newStock,
          updatedAt: DateTime.now(),
        );

        print('📦 STOCK SERVICE: Stock Update: ${item.nameEn} | ${item.stockQuantity} → $newStock | Reason: $reason');

        final updateResult = await inventoryRepository.updateInventoryItem(updatedItem);

        return updateResult.fold(
              (failure) {
            print('❌ STOCK SERVICE: Database update failed: ${failure.message}');
            return Left(failure);
          },
              (success) {
            print('✅ STOCK SERVICE: Database update successful for ${item.nameEn}');
            return Right(null);
          },
        );
      } catch (e) {
        print('❌ STOCK SERVICE: Item $itemId not found in inventory items list');
        return Left(ValidationFailure('Item $itemId not found in inventory'));
      }
    } catch (e) {
      print('❌ STOCK SERVICE: Exception during stock update: $e');
      return Left(ServerFailure('Failed to update stock for item $itemId: $e'));
    }
  }

  /// Notifies the inventory system to refresh after stock changes
  void _notifyInventoryRefresh() {
    try {
      print('🔄 STOCK SERVICE: Triggering inventory refresh notification');
      InventoryRefreshNotifier().notifyInventoryChanged();
      print('✅ STOCK SERVICE: Inventory refresh notification sent');
    } catch (e) {
      print('⚠️ STOCK SERVICE: Failed to notify inventory refresh: $e');
    }
  }

  /// Gets a summary of stock changes for logging/debugging
  Map<String, dynamic> getStockChangeSummary(Order order, OrderStatus oldStatus, OrderStatus newStatus) {
    final summary = <String, dynamic>{
      'orderNumber': order.orderNumber,
      'orderType': order.orderType.displayName,
      'statusChange': '$oldStatus → $newStatus',
      'shouldUpdate': _shouldUpdateStock(oldStatus, newStatus),
      'itemsCount': order.items.length,
      'items': order.items.map((item) => {
        'itemName': item.itemName,
        'itemId': item.itemId,
        'quantity': item.quantity,
        'stockChange': _calculateStockChange(order, item, oldStatus, newStatus),
        'hasSerials': item.serialNumbers != null && item.serialNumbers!.isNotEmpty,
        'serialCount': item.serialNumbers?.length ?? 0,
        'serialNumbers': item.serialNumbers, // ✅ Now shows actual serial numbers
      }).toList(),
    };

    print('📊 STOCK SERVICE: Stock change summary: $summary');
    return summary;
  }
}

// ✅ Validation Failure class
class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);

  @override
  List<Object> get props => [message];
}

// ✅ Global Inventory Refresh Notifier
class InventoryRefreshNotifier {
  static final _instance = InventoryRefreshNotifier._internal();
  factory InventoryRefreshNotifier() => _instance;
  InventoryRefreshNotifier._internal();

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
      print('🔄 REFRESH NOTIFIER: Added listener (total: ${_listeners.length})');
    }
  }

  void removeListener(VoidCallback callback) {
    if (_listeners.remove(callback)) {
      print('🔄 REFRESH NOTIFIER: Removed listener (total: ${_listeners.length})');
    }
  }

  void notifyInventoryChanged() {
    print('🔄 REFRESH NOTIFIER: Notifying ${_listeners.length} listeners of inventory change');

    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        print('⚠️ REFRESH NOTIFIER: Error calling listener: $e');
      }
    }

    print('✅ REFRESH NOTIFIER: All listeners notified');
  }

  void clearListeners() {
    final count = _listeners.length;
    _listeners.clear();
    print('🔄 REFRESH NOTIFIER: Cleared $count listeners');
  }

  int get listenerCount => _listeners.length;
}
