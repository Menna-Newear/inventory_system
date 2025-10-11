// data/repositories/inventory_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../models/inventory_item_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ✅ ENHANCED - Get all inventory items with serial numbers
  @override
  Future<Either<Failure, List<InventoryItem>>> getAllInventoryItems() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItems = await remoteDataSource.getAllInventoryItems();
        await localDataSource.cacheInventoryItems(remoteItems);

        // Convert models to entities and load serial numbers
        List<InventoryItem> items = [];
        for (final model in remoteItems) {
          InventoryItem item = model.toEntity();

          // ✅ Load serial numbers for serial-tracked items
          if (item.isSerialTracked) {
            final serialsResult = await getSerialNumbers(item.id);
            final serials = serialsResult.fold(
                  (failure) => <SerialNumber>[],
                  (serialNumbers) => serialNumbers,
            );
            item = item.copyWith(serialNumbers: serials);
          }

          items.add(item);
        }

        return Right(items);
      } catch (e) {
        // Fallback to cached data
        try {
          final cachedItems = await localDataSource.getCachedInventoryItems();
          List<InventoryItem> items = [];

          for (final model in cachedItems) {
            InventoryItem item = model.toEntity();

            // Load cached serial numbers
            if (item.isSerialTracked) {
              final serialsResult = await getSerialNumbers(item.id);
              final serials = serialsResult.fold(
                    (failure) => <SerialNumber>[],
                    (serialNumbers) => serialNumbers,
              );
              item = item.copyWith(serialNumbers: serials);
            }

            items.add(item);
          }

          return Right(items);
        } catch (cacheError) {
          return Left(ServerFailure('Failed to load inventory items: $e'));
        }
      }
    } else {
      try {
        final cachedItems = await localDataSource.getCachedInventoryItems();
        if (cachedItems.isNotEmpty) {
          List<InventoryItem> items = [];

          for (final model in cachedItems) {
            InventoryItem item = model.toEntity();

            // Load cached serial numbers
            if (item.isSerialTracked) {
              final serialsResult = await getSerialNumbers(item.id);
              final serials = serialsResult.fold(
                    (failure) => <SerialNumber>[],
                    (serialNumbers) => serialNumbers,
              );
              item = item.copyWith(serialNumbers: serials);
            }

            items.add(item);
          }

          return Right(items);
        } else {
          return Left(CacheFailure('No cached data available'));
        }
      } catch (e) {
        return Left(CacheFailure('Failed to load cached inventory items: $e'));
      }
    }
  }

  // ✅ ENHANCED - Get single inventory item with serial numbers
  @override
  Future<Either<Failure, InventoryItem>> getInventoryItem(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItem = await remoteDataSource.getInventoryItem(id);
        await localDataSource.cacheInventoryItem(remoteItem);

        InventoryItem item = remoteItem.toEntity();

        // ✅ Load serial numbers if item is serial-tracked
        if (item.isSerialTracked) {
          final serialsResult = await getSerialNumbers(item.id);
          final serials = serialsResult.fold(
                (failure) => <SerialNumber>[],
                (serialNumbers) => serialNumbers,
          );
          item = item.copyWith(serialNumbers: serials);
        }

        return Right(item);
      } catch (e) {
        // Fallback to cached data
        try {
          final cachedItem = await localDataSource.getCachedInventoryItem(id);
          if (cachedItem != null) {
            InventoryItem item = cachedItem.toEntity();

            if (item.isSerialTracked) {
              final serialsResult = await getSerialNumbers(item.id);
              final serials = serialsResult.fold(
                    (failure) => <SerialNumber>[],
                    (serialNumbers) => serialNumbers,
              );
              item = item.copyWith(serialNumbers: serials);
            }

            return Right(item);
          } else {
            return Left(ItemNotFoundFailure('Item with ID $id not found'));
          }
        } catch (cacheError) {
          return Left(ServerFailure('Failed to load inventory item: $e'));
        }
      }
    } else {
      try {
        final cachedItem = await localDataSource.getCachedInventoryItem(id);
        if (cachedItem != null) {
          InventoryItem item = cachedItem.toEntity();

          if (item.isSerialTracked) {
            final serialsResult = await getSerialNumbers(item.id);
            final serials = serialsResult.fold(
                  (failure) => <SerialNumber>[],
                  (serialNumbers) => serialNumbers,
            );
            item = item.copyWith(serialNumbers: serials);
          }

          return Right(item);
        } else {
          return Left(CacheFailure('Item with ID $id not found in cache'));
        }
      } catch (e) {
        return Left(CacheFailure('Failed to load cached inventory item: $e'));
      }
    }
  }

  // ✅ ENHANCED - Create inventory item with serial number setup
  @override
  Future<Either<Failure, InventoryItem>> createInventoryItem(InventoryItem item) async {
    if (await networkInfo.isConnected) {
      try {
        // Check for duplicate SKU first
        final existingItems = await remoteDataSource.getAllInventoryItems();
        final duplicateSku = existingItems.any((existingItem) =>
        existingItem.sku.toLowerCase() == item.sku.toLowerCase());

        if (duplicateSku) {
          return Left(DuplicateSkuFailure('SKU ${item.sku} already exists'));
        }

        final itemModel = InventoryItemModel.fromEntity(item);
        final createdItem = await remoteDataSource.createInventoryItem(itemModel);
        await localDataSource.cacheInventoryItem(createdItem);

        InventoryItem newItem = createdItem.toEntity();

        // ✅ If serial tracking is enabled and initial serials provided, add them
        if (item.isSerialTracked && item.serialNumbers.isNotEmpty) {
          final serialsResult = await addSerialNumbers(newItem.id, item.serialNumbers);
          final serials = serialsResult.fold(
                (failure) => <SerialNumber>[],
                (serialNumbers) => serialNumbers,
          );
          newItem = newItem.copyWith(serialNumbers: serials);
        }

        return Right(newItem);
      } catch (e) {
        return Left(ServerFailure('Failed to create inventory item: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot create items offline.'));
    }
  }

  // ✅ ENHANCED - Update inventory item (preserves serial numbers)
  @override
  Future<Either<Failure, InventoryItem>> updateInventoryItem(InventoryItem item) async {
    if (await networkInfo.isConnected) {
      try {
        final itemModel = InventoryItemModel.fromEntity(item);
        final updatedItem = await remoteDataSource.updateInventoryItem(itemModel);
        await localDataSource.cacheInventoryItem(updatedItem);

        InventoryItem newItem = updatedItem.toEntity();

        // ✅ Reload serial numbers after update
        if (newItem.isSerialTracked) {
          final serialsResult = await getSerialNumbers(newItem.id);
          final serials = serialsResult.fold(
                (failure) => <SerialNumber>[],
                (serialNumbers) => serialNumbers,
          );
          newItem = newItem.copyWith(serialNumbers: serials);
        }

        return Right(newItem);
      } catch (e) {
        return Left(ServerFailure('Failed to update inventory item: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot update items offline.'));
    }
  }

  // ✅ ENHANCED - Delete inventory item (cascades to serial numbers)
  @override
  Future<Either<Failure, void>> deleteInventoryItem(String id) async {
    if (await networkInfo.isConnected) {
      try {
        // Delete all associated serial numbers first
        await remoteDataSource.deleteAllSerialNumbers(id);

        // Then delete the item
        await remoteDataSource.deleteInventoryItem(id);
        await localDataSource.removeCachedInventoryItem(id);

        return Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to delete inventory item: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot delete items offline.'));
    }
  }

  // ✅ NEW - Serial Number Management Methods

  /// Add serial numbers to an inventory item
  @override
  Future<Either<Failure, List<SerialNumber>>> addSerialNumbers(
      String itemId,
      List<SerialNumber> serialNumbers,
      ) async {
    if (await networkInfo.isConnected) {
      try {
        final addedSerials = await remoteDataSource.addSerialNumbers(itemId, serialNumbers);
        // Cache the serial numbers locally
        await localDataSource.cacheSerialNumbers(itemId, addedSerials);
        return Right(addedSerials);
      } catch (e) {
        return Left(ServerFailure('Failed to add serial numbers: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot add serial numbers offline.'));
    }
  }

  /// Get all serial numbers for an inventory item
  @override
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbers(String itemId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSerials = await remoteDataSource.getSerialNumbers(itemId);
        await localDataSource.cacheSerialNumbers(itemId, remoteSerials);
        return Right(remoteSerials);
      } catch (e) {
        // Fallback to cached data
        try {
          final cachedSerials = await localDataSource.getCachedSerialNumbers(itemId);
          return Right(cachedSerials);
        } catch (cacheError) {
          return Left(ServerFailure('Failed to get serial numbers: $e'));
        }
      }
    } else {
      try {
        final cachedSerials = await localDataSource.getCachedSerialNumbers(itemId);
        return Right(cachedSerials);
      } catch (e) {
        return Left(CacheFailure('Failed to get cached serial numbers: $e'));
      }
    }
  }

  /// Update a serial number's status
  @override
  Future<Either<Failure, SerialNumber>> updateSerialStatus(
      String serialId,
      SerialStatus newStatus, {
        String? notes,
      }) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedSerial = await remoteDataSource.updateSerialStatus(
          serialId,
          newStatus,
          notes: notes,
        );
        // Update local cache
        await localDataSource.cacheSerialNumber(updatedSerial);
        return Right(updatedSerial);
      } catch (e) {
        return Left(ServerFailure('Failed to update serial status: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot update serial status offline.'));
    }
  }

  /// Delete a serial number
  @override
  Future<Either<Failure, void>> deleteSerialNumber(String serialId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSerialNumber(serialId);
        await localDataSource.removeCachedSerialNumber(serialId);
        return Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to delete serial number: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot delete serial number offline.'));
    }
  }

  /// Get serial numbers by status across all items
  @override
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbersByStatus(
      SerialStatus status,
      ) async {
    if (await networkInfo.isConnected) {
      try {
        final serials = await remoteDataSource.getSerialNumbersByStatus(status);
        return Right(serials);
      } catch (e) {
        return Left(ServerFailure('Failed to get serial numbers by status: $e'));
      }
    } else {
      try {
        final cachedSerials = await localDataSource.getAllCachedSerialNumbers();
        final filteredSerials = cachedSerials.where((s) => s.status == status).toList();
        return Right(filteredSerials);
      } catch (e) {
        return Left(CacheFailure('Failed to get cached serial numbers by status: $e'));
      }
    }
  }

  /// Check if a serial number exists
  @override
  Future<Either<Failure, bool>> serialNumberExists(
      String serialNumber, {
        String? excludeId,
      }) async {
    try {
      if (await networkInfo.isConnected) {
        final exists = await remoteDataSource.serialNumberExists(serialNumber, excludeId: excludeId);
        return Right(exists);
      } else {
        final cachedSerials = await localDataSource.getAllCachedSerialNumbers();
        final exists = cachedSerials.any((s) =>
        s.serialNumber.toLowerCase() == serialNumber.toLowerCase() &&
            (excludeId == null || s.id != excludeId)
        );
        return Right(exists);
      }
    } catch (e) {
      return Left(ServerFailure('Failed to check serial number existence: $e'));
    }
  }

  /// Bulk update serial number statuses
  @override
  Future<Either<Failure, List<SerialNumber>>> bulkUpdateSerialStatus(
      List<String> serialIds,
      SerialStatus newStatus, {
        String? notes,
      }) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedSerials = await remoteDataSource.bulkUpdateSerialStatus(
          serialIds,
          newStatus,
          notes: notes,
        );

        // Update local cache
        for (final serial in updatedSerials) {
          await localDataSource.cacheSerialNumber(serial);
        }

        return Right(updatedSerials);
      } catch (e) {
        return Left(ServerFailure('Failed to bulk update serial statuses: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot update serial statuses offline.'));
    }
  }

  // ✅ NEW - ADD MISSING METHODS FROM INTERFACE

  /// Get serial numbers that require attention (damaged, recalled, etc.)
  @override
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbersRequiringAttention() async {
    if (await networkInfo.isConnected) {
      try {
        final serials = await remoteDataSource.getSerialNumbersRequiringAttention();
        return Right(serials);
      } catch (e) {
        return Left(ServerFailure('Failed to get serial numbers requiring attention: $e'));
      }
    } else {
      try {
        final cachedSerials = await localDataSource.getAllCachedSerialNumbers();
        final attentionSerials = cachedSerials.where((s) =>
        s.status == SerialStatus.damaged || s.status == SerialStatus.recalled
        ).toList();
        return Right(attentionSerials);
      } catch (e) {
        return Left(CacheFailure('Failed to get cached serial numbers requiring attention: $e'));
      }
    }
  }

  /// Get serial number history/audit trail for an item
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSerialNumberHistory(String itemId) async {
    if (await networkInfo.isConnected) {
      try {
        // This would typically query a separate audit/history table
        // For now, we'll return basic serial information as history
        final serialsResult = await getSerialNumbers(itemId);
        return serialsResult.fold(
              (failure) => Left(failure),
              (serialNumbers) {
            final history = serialNumbers.map((serial) => {
              'id': serial.id,
              'serial_number': serial.serialNumber,
              'status': serial.status.name,
              'status_display': serial.status.displayName,
              'notes': serial.notes,
              'created_at': serial.createdAt.toIso8601String(),
              'updated_at': serial.updatedAt.toIso8601String(),
              'action': 'status_change',
              'item_id': itemId,
            }).toList();
            return Right(history);
          },
        );
      } catch (e) {
        return Left(ServerFailure('Failed to get serial number history: $e'));
      }
    } else {
      try {
        final cachedSerials = await localDataSource.getCachedSerialNumbers(itemId);
        final history = cachedSerials.map((serial) => {
          'id': serial.id,
          'serial_number': serial.serialNumber,
          'status': serial.status.name,
          'status_display': serial.status.displayName,
          'notes': serial.notes,
          'created_at': serial.createdAt.toIso8601String(),
          'updated_at': serial.updatedAt.toIso8601String(),
          'action': 'cached_data',
          'item_id': itemId,
        }).toList();
        return Right(history);
      } catch (e) {
        return Left(CacheFailure('Failed to get cached serial number history: $e'));
      }
    }
  }

  /// Generate serial number utilization report
  @override
  Future<Either<Failure, Map<String, dynamic>>> getSerialNumberUtilizationReport({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final itemsResult = await getAllInventoryItems();
      return itemsResult.fold(
            (failure) => Left(failure),
            (items) {
          // Filter items by category if specified
          List<InventoryItem> filteredItems = items;
          if (categoryId != null) {
            filteredItems = items.where((item) => item.categoryId == categoryId).toList();
          }

          // Filter serial tracked items only
          final serialTrackedItems = filteredItems.where((item) => item.isSerialTracked).toList();

          // Calculate metrics
          final totalItems = serialTrackedItems.length;
          final totalSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.totalSerialCount);
          final availableSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.availableStock);
          final soldSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.soldStock);
          final damagedSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.damagedStock);

          // Calculate utilization rates
          final utilizationRate = totalSerials > 0 ? (soldSerials / totalSerials) * 100 : 0.0;
          final damageRate = totalSerials > 0 ? (damagedSerials / totalSerials) * 100 : 0.0;

          // Category breakdown
          final categoryBreakdown = <String, Map<String, dynamic>>{};
          for (final item in serialTrackedItems) {
            if (!categoryBreakdown.containsKey(item.categoryId)) {
              categoryBreakdown[item.categoryId] = {
                'total_items': 0,
                'total_serials': 0,
                'available_serials': 0,
                'sold_serials': 0,
                'damaged_serials': 0,
              };
            }

            categoryBreakdown[item.categoryId]!['total_items'] =
                (categoryBreakdown[item.categoryId]!['total_items'] as int) + 1;
            categoryBreakdown[item.categoryId]!['total_serials'] =
                (categoryBreakdown[item.categoryId]!['total_serials'] as int) + item.totalSerialCount;
            categoryBreakdown[item.categoryId]!['available_serials'] =
                (categoryBreakdown[item.categoryId]!['available_serials'] as int) + item.availableStock;
            categoryBreakdown[item.categoryId]!['sold_serials'] =
                (categoryBreakdown[item.categoryId]!['sold_serials'] as int) + item.soldStock;
            categoryBreakdown[item.categoryId]!['damaged_serials'] =
                (categoryBreakdown[item.categoryId]!['damaged_serials'] as int) + item.damagedStock;
          }

          // Top items by serial count
          final topItems = serialTrackedItems
              .where((item) => item.totalSerialCount > 0)
              .toList()
            ..sort((a, b) => b.totalSerialCount.compareTo(a.totalSerialCount));

          final topItemsData = topItems.take(10).map((item) => {
            'item_id': item.id,
            'sku': item.sku,
            'name': item.nameEn,
            'total_serials': item.totalSerialCount,
            'available_serials': item.availableStock,
            'utilization_rate': item.totalSerialCount > 0
                ? ((item.soldStock / item.totalSerialCount) * 100).toStringAsFixed(1)
                : '0.0',
          }).toList();

          final report = {
            'report_type': 'serial_number_utilization',
            'generated_at': DateTime.now().toIso8601String(),
            'period': {
              'start_date': startDate?.toIso8601String(),
              'end_date': endDate?.toIso8601String(),
            },
            'filters': {
              'category_id': categoryId,
            },
            'summary': {
              'total_serial_tracked_items': totalItems,
              'total_serial_numbers': totalSerials,
              'available_serials': availableSerials,
              'sold_serials': soldSerials,
              'damaged_serials': damagedSerials,
              'utilization_rate_percent': utilizationRate.toStringAsFixed(2),
              'damage_rate_percent': damageRate.toStringAsFixed(2),
            },
            'category_breakdown': categoryBreakdown,
            'top_items_by_serial_count': topItemsData,
          };

          return Right(report);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to generate serial number utilization report: $e'));
    }
  }

  // ✅ EXISTING METHODS (Enhanced with Serial Number Awareness)

  @override
  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final searchResults = await remoteDataSource.searchInventoryItems(query);

        // Load serial numbers for serial-tracked items in search results
        List<InventoryItem> items = [];
        for (final model in searchResults) {
          InventoryItem item = model.toEntity();

          if (item.isSerialTracked) {
            final serialsResult = await getSerialNumbers(item.id);
            final serials = serialsResult.fold(
                  (failure) => <SerialNumber>[],
                  (serialNumbers) => serialNumbers,
            );
            item = item.copyWith(serialNumbers: serials);
          }

          items.add(item);
        }

        return Right(items);
      } catch (e) {
        // Fallback to local search
        return _searchCachedItems(query);
      }
    } else {
      return _searchCachedItems(query);
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> filterInventoryItems(Map<String, dynamic> filters) async {
    if (await networkInfo.isConnected) {
      try {
        final filteredItems = await remoteDataSource.filterInventoryItems(filters);

        // Load serial numbers for filtered items
        List<InventoryItem> items = [];
        for (final model in filteredItems) {
          InventoryItem item = model.toEntity();

          if (item.isSerialTracked) {
            final serialsResult = await getSerialNumbers(item.id);
            final serials = serialsResult.fold(
                  (failure) => <SerialNumber>[],
                  (serialNumbers) => serialNumbers,
            );
            item = item.copyWith(serialNumbers: serials);
          }

          items.add(item);
        }

        return Right(items);
      } catch (e) {
        // Fallback to local filtering
        return _filterCachedItems(filters);
      }
    } else {
      return _filterCachedItems(filters);
    }
  }

  // ✅ ENHANCED - Low stock check considers serial tracking
  @override
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems() async {
    try {
      final allItemsResult = await getAllInventoryItems();
      return allItemsResult.fold(
            (failure) => Left(failure),
            (items) {
          final lowStockItems = items.where((item) => item.needsRestock).toList();
          return Right(lowStockItems);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get low stock items: $e'));
    }
  }

  // ✅ ENHANCED - Watch inventory items with serial numbers
  @override
  Stream<List<InventoryItem>> watchInventoryItems() async* {
    try {
      // Initial load
      final result = await getAllInventoryItems();
      yield result.fold(
            (failure) => <InventoryItem>[],
            (items) => items,
      );

      // Periodic updates every 30 seconds
      yield* Stream.periodic(Duration(seconds: 30), (_) async {
        final updatedResult = await getAllInventoryItems();
        return updatedResult.fold(
              (failure) => <InventoryItem>[],
              (items) => items,
        );
      }).asyncMap((future) => future);
    } catch (e) {
      yield [];
    }
  }

  // ✅ PRIVATE HELPER METHODS

  Future<Either<Failure, List<InventoryItem>>> _searchCachedItems(String query) async {
    try {
      final cachedItems = await localDataSource.getCachedInventoryItems();
      final queryLower = query.toLowerCase();

      final filteredModels = cachedItems.where((item) {
        return item.nameEn.toLowerCase().contains(queryLower) ||
            item.nameAr.toLowerCase().contains(queryLower) ||
            item.sku.toLowerCase().contains(queryLower) ||
            item.subcategory.toLowerCase().contains(queryLower);
      }).toList();

      // Load serial numbers for filtered items
      List<InventoryItem> items = [];
      for (final model in filteredModels) {
        InventoryItem item = model.toEntity();

        if (item.isSerialTracked) {
          final serialsResult = await getSerialNumbers(item.id);
          final serials = serialsResult.fold(
                (failure) => <SerialNumber>[],
                (serialNumbers) => serialNumbers,
          );
          item = item.copyWith(serialNumbers: serials);
        }

        items.add(item);
      }

      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to search cached inventory items: $e'));
    }
  }

  Future<Either<Failure, List<InventoryItem>>> _filterCachedItems(Map<String, dynamic> filters) async {
    try {
      final cachedItems = await localDataSource.getCachedInventoryItems();
      List<InventoryItemModel> filteredItems = List.from(cachedItems);

      // Apply all existing filters
      if (filters.containsKey('category_id') && filters['category_id'] != null) {
        filteredItems = filteredItems
            .where((item) => item.categoryId == filters['category_id'])
            .toList();
      }

      if (filters.containsKey('low_stock') && filters['low_stock'] == true) {
        filteredItems = filteredItems
            .where((item) => item.stockQuantity <= item.minStockLevel)
            .toList();
      }

      if (filters.containsKey('min_price') && filters['min_price'] != null) {
        final minPrice = filters['min_price'] as double;
        filteredItems = filteredItems
            .where((item) => (item.unitPrice ?? 0.0) >= minPrice)
            .toList();
      }

      if (filters.containsKey('max_price') && filters['max_price'] != null) {
        final maxPrice = filters['max_price'] as double;
        filteredItems = filteredItems
            .where((item) => (item.unitPrice ?? 0.0) <= maxPrice)
            .toList();
      }

      if (filters.containsKey('subcategory') && filters['subcategory'] != null) {
        filteredItems = filteredItems
            .where((item) => item.subcategory.toLowerCase().contains(
            filters['subcategory'].toString().toLowerCase()))
            .toList();
      }

      // ✅ NEW - Filter by serial tracking status
      if (filters.containsKey('serial_tracked')) {
        final isSerialTracked = filters['serial_tracked'] as bool;
        filteredItems = filteredItems
            .where((item) => item.isSerialTracked == isSerialTracked)
            .toList();
      }

      // ✅ ENHANCED - Stock status filter considers serial tracking
      if (filters.containsKey('stock_status')) {
        switch (filters['stock_status']) {
          case 'in_stock':
            filteredItems = filteredItems
                .where((item) {
              if (item.isSerialTracked) {
                // Would need to load serials to check available count
                return item.stockQuantity > item.minStockLevel;
              }
              return item.stockQuantity > item.minStockLevel;
            })
                .toList();
            break;
          case 'low_stock':
            filteredItems = filteredItems
                .where((item) {
              if (item.isSerialTracked) {
                return item.stockQuantity <= item.minStockLevel && item.stockQuantity > 0;
              }
              return item.stockQuantity <= item.minStockLevel && item.stockQuantity > 0;
            })
                .toList();
            break;
          case 'out_of_stock':
            filteredItems = filteredItems
                .where((item) => item.stockQuantity == 0)
                .toList();
            break;
        }
      }

      if (filters.containsKey('start_date') && filters['start_date'] != null) {
        final startDate = DateTime.parse(filters['start_date']);
        filteredItems = filteredItems
            .where((item) => item.createdAt.isAfter(startDate) ||
            item.createdAt.isAtSameMomentAs(startDate))
            .toList();
      }

      if (filters.containsKey('end_date') && filters['end_date'] != null) {
        final endDate = DateTime.parse(filters['end_date']);
        filteredItems = filteredItems
            .where((item) => item.createdAt.isBefore(endDate) ||
            item.createdAt.isAtSameMomentAs(endDate))
            .toList();
      }

      // Load serial numbers for filtered items
      List<InventoryItem> items = [];
      for (final model in filteredItems) {
        InventoryItem item = model.toEntity();

        if (item.isSerialTracked) {
          final serialsResult = await getSerialNumbers(item.id);
          final serials = serialsResult.fold(
                (failure) => <SerialNumber>[],
                (serialNumbers) => serialNumbers,
          );
          item = item.copyWith(serialNumbers: serials);
        }

        items.add(item);
      }

      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to filter cached inventory items: $e'));
    }
  }

  // ✅ ENHANCED UTILITY METHODS

  /// Helper method to sync offline changes when connection is restored
  @override
  Future<Either<Failure, void>> syncOfflineChanges() async {
    if (await networkInfo.isConnected) {
      try {
        // Get all cached items and sync with remote
        final cachedItems = await localDataSource.getCachedInventoryItems();

        // This would typically involve checking for items marked as "dirty" or "pending sync"
        // For now, we'll just refresh the cache with latest remote data
        final remoteItems = await remoteDataSource.getAllInventoryItems();
        await localDataSource.cacheInventoryItems(remoteItems);

        // Also sync serial numbers
        for (final item in remoteItems) {
          if (item.isSerialTracked) {
            try {
              final remoteSerials = await remoteDataSource.getSerialNumbers(item.id);
              await localDataSource.cacheSerialNumbers(item.id, remoteSerials);
            } catch (e) {
              // Continue with other items if one fails
              print('Failed to sync serials for item ${item.id}: $e');
            }
          }
        }

        return Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to sync offline changes: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection for sync'));
    }
  }

  /// Get comprehensive inventory statistics including serial tracking
  @override
  Future<Either<Failure, Map<String, dynamic>>> getInventoryStats() async {
    try {
      final itemsResult = await getAllInventoryItems();
      return itemsResult.fold(
            (failure) => Left(failure),
            (items) {
          final totalValue = items.fold<double>(
            0.0,
                (sum, item) => sum + item.totalValue,
          );

          final itemsWithPrice = items.where((item) => item.unitPrice != null).toList();
          final averagePrice = itemsWithPrice.isNotEmpty
              ? itemsWithPrice.fold<double>(0.0, (sum, item) => sum + (item.unitPrice ?? 0.0)) / itemsWithPrice.length
              : 0.0;

          // ✅ NEW - Serial tracking statistics
          final serialTrackedItems = items.where((item) => item.isSerialTracked).toList();
          final totalSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.totalSerialCount);
          final availableSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.availableStock);
          final soldSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.soldStock);

          final stats = {
            'total_items': items.length,
            'total_value': totalValue,
            'low_stock_count': items.where((item) => item.needsRestock).length,
            'out_of_stock_count': items.where((item) =>
            item.isSerialTracked ? item.availableStock == 0 : item.stockQuantity == 0
            ).length,
            'categories_count': items.map((item) => item.categoryId).toSet().length,
            'average_price': averagePrice,
            'items_with_price': itemsWithPrice.length,
            'items_without_price': items.length - itemsWithPrice.length,
            // ✅ NEW - Serial tracking stats
            'serial_tracked_items': serialTrackedItems.length,
            'total_serial_numbers': totalSerials,
            'available_serial_numbers': availableSerials,
            'sold_serial_numbers': soldSerials,
            'serial_utilization_rate': totalSerials > 0 ? (soldSerials / totalSerials) * 100 : 0,
          };
          return Right(stats);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get inventory statistics: $e'));
    }
  }

  /// Check if SKU exists (unchanged)
  @override
  Future<Either<Failure, bool>> skuExists(String sku, {String? excludeId}) async {
    try {
      final itemsResult = await getAllInventoryItems();
      return itemsResult.fold(
            (failure) => Left(failure),
            (items) {
          final exists = items.any((item) =>
          item.sku.toLowerCase() == sku.toLowerCase() &&
              (excludeId == null || item.id != excludeId));
          return Right(exists);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to check SKU existence: $e'));
    }
  }
}
