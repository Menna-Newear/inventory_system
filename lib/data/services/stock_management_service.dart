// ✅ data/services/stock_management_service.dart (COMPLETE FIXED VERSION FOR SELL ORDERS)
import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../core/error/failures.dart';

class StockManagementService {
  final InventoryRepository inventoryRepository;

  StockManagementService({required this.inventoryRepository});

  /// Updates stock levels when order status changes
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

      // ✅ NOTIFY INVENTORY REFRESH IF STOCK CHANGED
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

          if (inventoryItem.stockQuantity < orderItem.quantity) {
            print('❌ STOCK SERVICE: Insufficient stock for ${inventoryItem.nameEn}');
            return Left(ValidationFailure(
                'Insufficient stock for ${inventoryItem.nameEn}. '
                    'Available: ${inventoryItem.stockQuantity}, Required: ${orderItem.quantity}'
            ));
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

    // ✅ RESTORE STOCK: When approved order is cancelled/rejected (BOTH SELL & RENTAL)
    if (oldStatus == OrderStatus.approved &&
        (newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected)) {
      print('✅ STOCK SERVICE: Should restore stock (cancellation/rejection from approved - applies to both sell and rental)');
      return true;
    }

    // ✅ RESTORE STOCK: When any order type is returned
    if (newStatus == OrderStatus.returned && oldStatus != OrderStatus.returned) {
      print('✅ STOCK SERVICE: Should restore stock (order returned - applies to both sell and rental)');
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

    // ✅ REDUCE STOCK: When approving any order type (sell or rental)
    if (newStatus == OrderStatus.approved &&
        (oldStatus == OrderStatus.draft || oldStatus == OrderStatus.pending)) {
      print('📉 STOCK SERVICE: Reducing stock by ${orderItem.quantity} (approval - ${order.orderType.displayName})');
      return -orderItem.quantity;
    }

    // ✅ RESTORE STOCK: When cancelling/rejecting approved order (BOTH SELL & RENTAL)
    else if ((newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected) &&
        oldStatus == OrderStatus.approved) {
      print('📈 STOCK SERVICE: Restoring stock by ${orderItem.quantity} (${newStatus.displayName} from approved - ${order.orderType.displayName})');
      return orderItem.quantity;
    }

    // ✅ RESTORE STOCK: When returning any order type (sell or rental)
    else if (newStatus == OrderStatus.returned && oldStatus != OrderStatus.returned) {
      print('📈 STOCK SERVICE: Restoring stock by ${orderItem.quantity} (${order.orderType.displayName} returned)');
      return orderItem.quantity;
    }

    print('➡️ STOCK SERVICE: No stock change calculated');
    return 0;
  }

  /// Gets the reason text for the stock update
  String _getUpdateReason(Order order, OrderStatus newStatus) {
    final reason = switch (newStatus) {
      OrderStatus.approved => '${order.orderType.displayName} approved: ${order.orderNumber}',
      OrderStatus.cancelled => '${order.orderType.displayName} cancelled: ${order.orderNumber}', // ✅ UPDATED
      OrderStatus.rejected => '${order.orderType.displayName} rejected: ${order.orderNumber}',   // ✅ UPDATED
      OrderStatus.returned => '${order.orderType.displayName} returned: ${order.orderNumber}',   // ✅ UPDATED
      OrderStatus.draft ||
      OrderStatus.pending ||
      OrderStatus.processing ||
      OrderStatus.shipped ||
      OrderStatus.delivered => '${order.orderType.displayName} status change: ${order.orderNumber}',
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
      // Get current inventory items
      final itemsResult = await inventoryRepository.getAllInventoryItems();
      if (itemsResult.isLeft()) {
        print('❌ STOCK SERVICE: Failed to get inventory items for update');
        return itemsResult.fold((l) => Left(l), (r) => throw Exception());
      }

      final items = itemsResult.fold((l) => throw Exception(), (r) => r);

      try {
        final item = items.firstWhere((i) => i.id == itemId);
        print('🔍 STOCK SERVICE: Found item ${item.nameEn}, current stock: ${item.stockQuantity}');

        // Calculate new stock level
        final newStock = item.stockQuantity + quantityChange;
        print('🔍 STOCK SERVICE: New stock will be: $newStock');

        // Validate new stock level
        if (newStock < 0) {
          print('❌ STOCK SERVICE: Insufficient stock for update');
          return Left(ValidationFailure(
              'Insufficient stock for ${item.nameEn}. '
                  'Available: ${item.stockQuantity}, Required: ${-quantityChange}'
          ));
        }

        // Create updated item
        final updatedItem = item.copyWith(
          stockQuantity: newStock,
          updatedAt: DateTime.now(),
        );

        print('📦 STOCK SERVICE: Stock Update: ${item.nameEn} | ${item.stockQuantity} → $newStock | Reason: $reason');

        // Update in database
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

      // Use the global inventory refresh notifier
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

  /// Add a listener for inventory refresh events
  void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
      print('🔄 REFRESH NOTIFIER: Added listener (total: ${_listeners.length})');
    }
  }

  /// Remove a listener
  void removeListener(VoidCallback callback) {
    if (_listeners.remove(callback)) {
      print('🔄 REFRESH NOTIFIER: Removed listener (total: ${_listeners.length})');
    }
  }

  /// Notify all listeners that inventory has changed
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

  /// Clear all listeners (useful for cleanup)
  void clearListeners() {
    final count = _listeners.length;
    _listeners.clear();
    print('🔄 REFRESH NOTIFIER: Cleared $count listeners');
  }

  /// Get current listener count
  int get listenerCount => _listeners.length;
}
