// ✅ data/services/stock_management_service.dart (WITH DATE-AWARE RENTAL SUPPORT)
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
    debugPrint('🔍 STOCK SERVICE: Order ${order.orderNumber} (${order.orderType.displayName})');
    debugPrint('🔍 STOCK SERVICE: Status change: $oldStatus → $newStatus');

    if (!_shouldUpdateStock(oldStatus, newStatus)) {
      debugPrint('➡️ STOCK SERVICE: No stock update needed');
      return Right(null);
    }

    try {
      List<String> updatedItemIds = [];

      // STEP 1: Update stock quantities
      for (final orderItem in order.items) {
        final stockChange = _calculateStockChange(order, orderItem, oldStatus, newStatus);

        if (stockChange != 0) {
          final result = await _updateItemStock(
            orderItem.itemId,
            stockChange,
            _getUpdateReason(order, newStatus),
          );

          if (result.isLeft()) {
            return result.fold((l) => Left(l), (r) => throw Exception());
          }

          updatedItemIds.add(orderItem.itemId);
          debugPrint('✅ STOCK SERVICE: Updated ${orderItem.itemName}');
        }
      }

      // STEP 2: Update serial statuses
      if (updatedItemIds.isNotEmpty) {
        final serialResult = await _updateSerialStatuses(order, oldStatus, newStatus);
        if (serialResult.isLeft()) {
          debugPrint('⚠️ STOCK SERVICE: Serial update failed but stock was updated');
        }
      }

      // STEP 3: Notify ONLY affected items to refresh (NOT full inventory!)
      if (updatedItemIds.isNotEmpty) {
        _notifySpecificItemsRefresh(updatedItemIds);
        debugPrint('✅ STOCK SERVICE: Completed - refreshed ${updatedItemIds.length} items');
      }

      return Right(null);
    } catch (e) {
      debugPrint('❌ STOCK SERVICE: Exception: $e');
      return Left(ServerFailure('Stock management error: $e'));
    }
  }

  /// Updates serial statuses when order status changes
  Future<Either<Failure, void>> _updateSerialStatuses(
      Order order,
      OrderStatus oldStatus,
      OrderStatus newStatus,
      ) async {
    try {
      for (final orderItem in order.items) {
        if (orderItem.serialNumbers != null && orderItem.serialNumbers!.isNotEmpty) {
          debugPrint('🔍 STOCK SERVICE: Updating ${orderItem.serialNumbers!.length} serials for ${orderItem.itemName}');

          final serialIds = await _getSerialIdsByNumbers(
            orderItem.itemId,
            orderItem.serialNumbers!,
          );

          if (serialIds.isEmpty) {
            debugPrint('⚠️ STOCK SERVICE: No serial IDs found, skipping');
            continue;
          }

          final serialStatus = _getSerialStatusForOrder(newStatus, order.orderType);

          final result = await inventoryRepository.bulkUpdateSerialStatus(
            serialIds,
            serialStatus,
          );

          if (result.isLeft()) {
            return result;
          }

          debugPrint('✅ STOCK SERVICE: Serial statuses updated to $serialStatus');
        }
      }

      return Right(null);
    } catch (e) {
      debugPrint('❌ STOCK SERVICE: Serial update exception: $e');
      return Left(ServerFailure('Failed to update serial statuses: $e'));
    }
  }

  /// Converts serial number strings to IDs
  Future<List<String>> _getSerialIdsByNumbers(String itemId, List<String> serialNumbers) async {
    try {
      debugPrint('🔍 STOCK SERVICE: Looking up serial IDs for ${serialNumbers.length} serial numbers');
      debugPrint('🔍 STOCK SERVICE: Item ID: $itemId');

      final itemResult = await inventoryRepository.getInventoryItem(itemId);

      if (itemResult.isLeft()) {
        debugPrint('❌ STOCK SERVICE: Failed to get item for serial lookup');
        return [];
      }

      final item = itemResult.fold((l) => throw Exception(), (r) => r);
      debugPrint('🔍 STOCK SERVICE: Found item ${item.nameEn} with ${item.serialNumbers.length} total serials');

      final matchingSerials = item.serialNumbers
          .where((serial) => serialNumbers.contains(serial.serialNumber))
          .map((serial) => serial.id)
          .toList();

      debugPrint('🔍 STOCK SERVICE: Matched ${matchingSerials.length}/${serialNumbers.length} serial IDs');
      return matchingSerials;
    } catch (e) {
      debugPrint('❌ STOCK SERVICE: Error getting serial IDs: $e');
      return [];
    }
  }

  /// Determines serial status based on order status and type
  SerialStatus _getSerialStatusForOrder(OrderStatus orderStatus, OrderType orderType) {
    return switch (orderStatus) {
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
  }

  /// Validates if there's enough stock before approving an order
  Future<Either<Failure, void>> validateStockAvailability(Order order) async {
    debugPrint('🔍 STOCK SERVICE: Validating stock for ${order.orderNumber}');

    try {
      for (final orderItem in order.items) {
        final itemResult = await inventoryRepository.getInventoryItem(orderItem.itemId);

        if (itemResult.isLeft()) {
          debugPrint('❌ STOCK SERVICE: Item ${orderItem.itemId} not found');
          return Left(ValidationFailure('Item ${orderItem.itemId} not found in inventory'));
        }

        final inventoryItem = itemResult.fold((l) => throw Exception(), (r) => r);

        debugPrint('🔍 STOCK SERVICE: Checking ${inventoryItem.nameEn} - Available: ${inventoryItem.stockQuantity}, Required: ${orderItem.quantity}');

        // Check stock quantity
        if (inventoryItem.stockQuantity < orderItem.quantity) {
          debugPrint('❌ STOCK SERVICE: Insufficient stock for ${inventoryItem.nameEn}');
          return Left(ValidationFailure(
              'Insufficient stock for ${inventoryItem.nameEn}. '
                  'Available: ${inventoryItem.stockQuantity}, Required: ${orderItem.quantity}'
          ));
        }

        // Validate serial-tracked items
        if (inventoryItem.isSerialTracked) {
          if (orderItem.serialNumbers == null || orderItem.serialNumbers!.isEmpty) {
            debugPrint('❌ STOCK SERVICE: Serial-tracked item ${inventoryItem.nameEn} has no serial numbers assigned');
            return Left(ValidationFailure(
                'Serial-tracked item ${inventoryItem.nameEn} requires serial number selection'
            ));
          }

          if (orderItem.serialNumbers!.length != orderItem.quantity) {
            debugPrint('❌ STOCK SERVICE: Serial count mismatch for ${inventoryItem.nameEn}');
            return Left(ValidationFailure(
                'Serial count mismatch for ${inventoryItem.nameEn}. '
                    'Required: ${orderItem.quantity}, Selected: ${orderItem.serialNumbers!.length}'
            ));
          }

          // ✅ FIXED: Date-aware validation for rental orders
          debugPrint('🔍 STOCK SERVICE: Validating ${orderItem.serialNumbers!.length} serial numbers for ${order.orderType.displayName} order');

          final validSerialNumbers = inventoryItem.serialNumbers
              .where((s) {
            // ✅ For rental orders: allow both available and rented serials
            // (date conflicts were already validated when selecting serials)
            if (order.orderType == OrderType.rental) {
              return s.status == SerialStatus.available || s.status == SerialStatus.rented;
            }
            // For sell orders: only available
            return s.status == SerialStatus.available;
          })
              .map((s) => s.serialNumber)
              .toList();

          for (final serialNumber in orderItem.serialNumbers!) {
            if (!validSerialNumbers.contains(serialNumber)) {
              debugPrint('❌ STOCK SERVICE: Serial number $serialNumber is not valid for ${order.orderType.displayName} order');
              return Left(ValidationFailure(
                  'Serial number $serialNumber for ${inventoryItem.nameEn} is not valid for this ${order.orderType.displayName} order'
              ));
            }
          }
          debugPrint('✅ STOCK SERVICE: All serial numbers are valid for ${order.orderType.displayName} order');
        }
      }

      debugPrint('✅ STOCK SERVICE: Stock validation passed for all ${order.items.length} items');
      return Right(null);
    } catch (e) {
      debugPrint('❌ STOCK SERVICE: Exception during stock validation: $e');
      return Left(ServerFailure('Failed to validate stock: $e'));
    }
  }

  /// Determines if stock update is needed
  bool _shouldUpdateStock(OrderStatus oldStatus, OrderStatus newStatus) {
    // Reduce stock: approval from draft/pending
    if ((oldStatus == OrderStatus.draft || oldStatus == OrderStatus.pending) &&
        newStatus == OrderStatus.approved) {
      return true;
    }

    // Restore stock: cancellation/rejection from approved
    if (oldStatus == OrderStatus.approved &&
        (newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected)) {
      return true;
    }

    // Restore stock: return
    if (newStatus == OrderStatus.returned && oldStatus != OrderStatus.returned) {
      return true;
    }

    return false;
  }

  /// Calculates stock change quantity
  int _calculateStockChange(Order order, OrderItem orderItem, OrderStatus oldStatus, OrderStatus newStatus) {
    // Reduce stock on approval
    if (newStatus == OrderStatus.approved &&
        (oldStatus == OrderStatus.draft || oldStatus == OrderStatus.pending)) {
      return -orderItem.quantity;
    }

    // Restore stock on cancel/reject
    if ((newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected) &&
        oldStatus == OrderStatus.approved) {
      return orderItem.quantity;
    }

    // Restore stock on return
    if (newStatus == OrderStatus.returned && oldStatus != OrderStatus.returned) {
      return orderItem.quantity;
    }

    return 0;
  }

  /// Gets update reason text
  String _getUpdateReason(Order order, OrderStatus newStatus) {
    return switch (newStatus) {
      OrderStatus.approved => '${order.orderType.displayName} approved: ${order.orderNumber}',
      OrderStatus.cancelled => '${order.orderType.displayName} cancelled: ${order.orderNumber}',
      OrderStatus.rejected => '${order.orderType.displayName} rejected: ${order.orderNumber}',
      OrderStatus.returned => '${order.orderType.displayName} returned: ${order.orderNumber}',
      _ => '${order.orderType.displayName} status change: ${order.orderNumber}',
    };
  }

  /// Updates stock for specific item
  Future<Either<Failure, void>> _updateItemStock(
      String itemId,
      int quantityChange,
      String reason,
      ) async {
    try {
      final itemResult = await inventoryRepository.getInventoryItem(itemId);

      if (itemResult.isLeft()) {
        debugPrint('❌ STOCK SERVICE: Failed to get item for update');
        return itemResult.fold((l) => Left(l), (r) => throw Exception());
      }

      final item = itemResult.fold((l) => throw Exception(), (r) => r);
      debugPrint('🔍 STOCK SERVICE: Found item ${item.nameEn}, current stock: ${item.stockQuantity}');

      final newStock = item.stockQuantity + quantityChange;

      if (newStock < 0) {
        return Left(ValidationFailure(
            'Insufficient stock for ${item.nameEn}. '
                'Available: ${item.stockQuantity}, Required: ${-quantityChange}'
        ));
      }

      final updatedItem = item.copyWith(
        stockQuantity: newStock,
        updatedAt: DateTime.now(),
      );

      debugPrint('📦 STOCK UPDATE: ${item.nameEn} | ${item.stockQuantity} → $newStock | $reason');

      final updateResult = await inventoryRepository.updateInventoryItem(updatedItem);

      return updateResult.fold(
            (failure) => Left(failure),
            (success) => Right(null),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to update stock for item $itemId: $e'));
    }
  }

  /// Notifies ONLY specific items to refresh (not full inventory!)
  void _notifySpecificItemsRefresh(List<String> itemIds) {
    try {
      debugPrint('🔄 STOCK SERVICE: Triggering refresh for ${itemIds.length} specific items');
      InventoryRefreshNotifier().notifySpecificItemsChanged(itemIds);
      debugPrint('✅ STOCK SERVICE: Specific items refresh notification sent');
    } catch (e) {
      debugPrint('⚠️ STOCK SERVICE: Failed to notify refresh: $e');
    }
  }

  /// Gets summary of stock changes (for debugging)
  Map<String, dynamic> getStockChangeSummary(Order order, OrderStatus oldStatus, OrderStatus newStatus) {
    return {
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
      }).toList(),
    };
  }
}

// Validation Failure class
class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);

  @override
  List<Object> get props => [message];
}

// Inventory Refresh Notifier with specific item support
class InventoryRefreshNotifier {
  static final _instance = InventoryRefreshNotifier._internal();
  factory InventoryRefreshNotifier() => _instance;
  InventoryRefreshNotifier._internal();

  final List<VoidCallback> _listeners = [];
  final List<Function(List<String>)> _specificItemListeners = [];

  void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
      debugPrint('🔄 NOTIFIER: Added full refresh listener (total: ${_listeners.length})');
    }
  }

  void removeListener(VoidCallback callback) {
    if (_listeners.remove(callback)) {
      debugPrint('🔄 NOTIFIER: Removed full refresh listener (total: ${_listeners.length})');
    }
  }

  void addSpecificItemListener(Function(List<String>) callback) {
    if (!_specificItemListeners.contains(callback)) {
      _specificItemListeners.add(callback);
      debugPrint('🔄 NOTIFIER: Added specific item listener (total: ${_specificItemListeners.length})');
    }
  }

  void removeSpecificItemListener(Function(List<String>) callback) {
    if (_specificItemListeners.remove(callback)) {
      debugPrint('🔄 NOTIFIER: Removed specific item listener (total: ${_specificItemListeners.length})');
    }
  }

  void notifyInventoryChanged() {
    debugPrint('⚠️ NOTIFIER: Full inventory refresh called (consider using specific items)');

    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('⚠️ NOTIFIER: Error calling listener: $e');
      }
    }
  }

  void notifySpecificItemsChanged(List<String> itemIds) {
    debugPrint('🔄 NOTIFIER: Notifying ${_specificItemListeners.length} listeners about ${itemIds.length} items');

    for (final listener in _specificItemListeners) {
      try {
        listener(itemIds);
      } catch (e) {
        debugPrint('⚠️ NOTIFIER: Error calling specific item listener: $e');
      }
    }

    debugPrint('✅ NOTIFIER: Specific item notifications sent');
  }

  void clearListeners() {
    final fullCount = _listeners.length;
    final specificCount = _specificItemListeners.length;
    _listeners.clear();
    _specificItemListeners.clear();
    debugPrint('🔄 NOTIFIER: Cleared $fullCount full + $specificCount specific listeners');
  }

  int get listenerCount => _listeners.length + _specificItemListeners.length;
}
