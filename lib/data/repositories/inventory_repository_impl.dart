// ✅ data/repositories/inventory_repository_impl.dart (WITH SMART CACHING)
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../models/inventory_item_model.dart';
import '../services/serial_number_cache_service.dart'; // ✅ ADD

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;
  final InventoryLocalDataSource localDataSource;
  final SerialNumberCacheService cacheService; // ✅ ADD
  final NetworkInfo networkInfo;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.cacheService, // ✅ ADD
    required this.networkInfo,
  });

  // ✅ Stock Management Service compatibility
  Future<Either<Failure, List<InventoryItem>>> getInventoryItems() async {
    print('🔄 INVENTORY REPO: getInventoryItems() called by stock management service');
    return getAllInventoryItems();
  }

  // ✅ ENHANCED - Get all inventory items with smart caching
// ✅ FIXED getAllInventoryItems() method - Replace lines 28-70 with this:

  @override
  Future<Either<Failure, List<InventoryItem>>> getAllInventoryItems() async {
    if (await networkInfo.isConnected) {
      try {
        print('🔄 INVENTORY REPO: Fetching fresh inventory items from remote');
        final remoteItems = await remoteDataSource.getAllInventoryItems();
        print('✅ INVENTORY REPO: Got ${remoteItems.length} items from remote');

        await localDataSource.cacheInventoryItems(remoteItems);
        print('💾 INVENTORY REPO: Cached ${remoteItems.length} items locally');

        List<InventoryItem> items = [];
        for (final model in remoteItems) {
          InventoryItem item = model.toEntity();

          if (item.isSerialTracked) {
            // ✅ ALWAYS load serials for serial-tracked items
            print('🔄 Loading serials for ${item.sku}...');
            final serialsResult = await getSerialNumbers(item.id);
            final serials = serialsResult.fold(
                  (failure) {
                print('⚠️ Failed to load serials for ${item.sku}: ${failure.message}');
                return <SerialNumber>[];
              },
                  (serialNumbers) {
                print('✅ Loaded ${serialNumbers.length} serials for ${item.sku}');
                return serialNumbers;
              },
            );
            // ✅ CRITICAL: Actually assign the serials to the item
            item = item.copyWith(serialNumbers: serials);
          }

          items.add(item);
        }

        print('✅ INVENTORY REPO: Returning ${items.length} items with serials loaded');
        return Right(items);
      } catch (e) {
        print('❌ INVENTORY REPO: Remote fetch failed, trying cache: $e');
        return _loadFromCache();
      }
    } else {
      return _loadFromCache();
    }
  }

  // ✅ Helper method to load from cache
  Future<Either<Failure, List<InventoryItem>>> _loadFromCache() async {
    try {
      final cachedItems = await localDataSource.getCachedInventoryItems();
      List<InventoryItem> items = [];

      for (final model in cachedItems) {
        InventoryItem item = model.toEntity();

        if (item.isSerialTracked) {
          final cachedSerials = cacheService.getCachedSerialNumbers(item.id);
          if (cachedSerials != null) {
            item = item.copyWith(serialNumbers: cachedSerials);
          }
        }

        items.add(item);
      }

      print('📦 INVENTORY REPO: Using ${items.length} cached items');
      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to load cached inventory items: $e'));
    }
  }

  // ✅ Get single inventory item with caching
  @override
  Future<Either<Failure, InventoryItem>> getInventoryItem(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItem = await remoteDataSource.getInventoryItem(id);
        await localDataSource.cacheInventoryItem(remoteItem);

        InventoryItem item = remoteItem.toEntity();

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
        return _loadSingleItemFromCache(id);
      }
    } else {
      return _loadSingleItemFromCache(id);
    }
  }

  Future<Either<Failure, InventoryItem>> _loadSingleItemFromCache(String id) async {
    try {
      final cachedItem = await localDataSource.getCachedInventoryItem(id);
      if (cachedItem != null) {
        InventoryItem item = cachedItem.toEntity();

        if (item.isSerialTracked) {
          final cachedSerials = cacheService.getCachedSerialNumbers(item.id);
          if (cachedSerials != null) {
            item = item.copyWith(serialNumbers: cachedSerials);
          }
        }

        return Right(item);
      } else {
        return Left(ItemNotFoundFailure('Item with ID $id not found'));
      }
    } catch (e) {
      return Left(CacheFailure('Failed to load cached item: $e'));
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> createInventoryItem(InventoryItem item) async {
    if (await networkInfo.isConnected) {
      try {
        final existingItems = await remoteDataSource.getAllInventoryItems();
        final duplicateSku = existingItems.any((existingItem) =>
        existingItem.sku.toLowerCase() == item.sku.toLowerCase());

        if (duplicateSku) {
          return Left(DuplicateSkuFailure('SKU ${item.sku} already exists'));
        }

        print('🔄 INVENTORY REPO: Creating new item ${item.nameEn}');

        final itemModel = InventoryItemModel.fromEntity(item);
        final createdItem = await remoteDataSource.createInventoryItem(itemModel);

        // ✅ Don't clear all cache - BLoC will add item to state
        // await localDataSource.clearCache(); // ❌ REMOVE THIS

        await localDataSource.cacheInventoryItem(createdItem);
        print('💾 INVENTORY REPO: New item cached');

        InventoryItem newItem = createdItem.toEntity();

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

  // ✅ Update inventory item with cache invalidation
  @override
  Future<Either<Failure, InventoryItem>> updateInventoryItem(InventoryItem item) async {
    if (await networkInfo.isConnected) {
      try {
        print('🔄 INVENTORY REPO: Updating item ${item.nameEn} (Stock: ${item.stockQuantity})');

        final itemModel = InventoryItemModel.fromEntity(item);
        final updatedItem = await remoteDataSource.updateInventoryItem(itemModel);

        print('✅ INVENTORY REPO: Database update successful');

        // ✅ Invalidate cache for this item
        await cacheService.invalidateCache(item.id);
        print('🗑️ INVENTORY REPO: Invalidated cache for item: ${item.id}');

       // await localDataSource.clearCache();
        await localDataSource.cacheInventoryItem(updatedItem);
        print('💾 INVENTORY REPO: Updated item cached');

        InventoryItem newItem = updatedItem.toEntity();

        if (newItem.isSerialTracked) {
          final serialsResult = await getSerialNumbers(newItem.id);
          final serials = serialsResult.fold(
                (failure) => <SerialNumber>[],
                (serialNumbers) => serialNumbers,
          );
          newItem = newItem.copyWith(serialNumbers: serials);
        }

        print('✅ INVENTORY REPO: Item ${item.nameEn} update complete');
        return Right(newItem);
      } catch (e) {
        print('❌ INVENTORY REPO: Update failed: $e');
        return Left(ServerFailure('Failed to update inventory item: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot update items offline.'));
    }
  }

  // ✅ Delete inventory item with cache invalidation
  @override
  Future<Either<Failure, void>> deleteInventoryItem(String id) async {
    if (await networkInfo.isConnected) {
      try {
        print('🔄 INVENTORY REPO: Deleting item $id');

        // ✅ Invalidate serial cache before deletion
        await cacheService.invalidateCache(id);

        await remoteDataSource.deleteAllSerialNumbers(id);
        await remoteDataSource.deleteInventoryItem(id);

        await localDataSource.clearCache();
        print('🗑️ INVENTORY REPO: Cache cleared after deleting item');

        await localDataSource.removeCachedInventoryItem(id);

        return Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to delete inventory item: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot delete items offline.'));
    }
  }

  // ✅ SERIAL NUMBER METHODS WITH SMART CACHING

  @override
  Future<Either<Failure, List<SerialNumber>>> addSerialNumbers(
      String itemId,
      List<SerialNumber> serialNumbers,
      ) async {
    if (await networkInfo.isConnected) {
      try {
        print('🔄 SERIAL REPO: Adding ${serialNumbers.length} serials to item: $itemId');
        final addedSerials = await remoteDataSource.addSerialNumbers(itemId, serialNumbers);

        // ✅ Cache the serials immediately
        await cacheService.cacheSerialNumbers(itemId, addedSerials);

        // ✅ Update count cache
        final available = addedSerials.where((s) => s.status == SerialStatus.available).length;
        await cacheService.cacheSerialCount(itemId, addedSerials.length, available);

        await localDataSource.cacheSerialNumbers(itemId, addedSerials);
        print('✅ SERIAL REPO: Added and cached ${addedSerials.length} serials');

        return Right(addedSerials);
      } catch (e) {
        return Left(ServerFailure('Failed to add serial numbers: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot add serial numbers offline.'));
    }
  }

  @override
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbers(String itemId) async {
    // ✅ Try cache first
    final cached = cacheService.getCachedSerialNumbers(itemId);
    if (cached != null) {
      print('✅ CACHE HIT: Serial numbers for item: $itemId (${cached.length} serials)');
      return Right(cached);
    }

    if (await networkInfo.isConnected) {
      try {
        print('🟡 REMOTE: Fetching serial numbers for item: $itemId');
        final remoteSerials = await remoteDataSource.getSerialNumbers(itemId);
        print('🟢 REMOTE: Found ${remoteSerials.length} serial numbers');

        // ✅ Cache the results
        await cacheService.cacheSerialNumbers(itemId, remoteSerials);

        // ✅ Cache the count
        final available = remoteSerials.where((s) => s.status == SerialStatus.available).length;
        await cacheService.cacheSerialCount(itemId, remoteSerials.length, available);

        await localDataSource.cacheSerialNumbers(itemId, remoteSerials);

        return Right(remoteSerials);
      } catch (e) {
        return _loadSerialsFromCache(itemId);
      }
    } else {
      return _loadSerialsFromCache(itemId);
    }
  }

  Future<Either<Failure, List<SerialNumber>>> _loadSerialsFromCache(String itemId) async {
    try {
      final cachedSerials = await localDataSource.getCachedSerialNumbers(itemId);
      return Right(cachedSerials);
    } catch (e) {
      return Left(CacheFailure('Failed to get cached serial numbers: $e'));
    }
  }

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

        // ✅ Invalidate cache for the item (we'd need itemId here)
        // For now, invalidate all serial caches or pass itemId
        print('✅ SERIAL REPO: Updated serial status');

        await localDataSource.cacheSerialNumber(updatedSerial);
        return Right(updatedSerial);
      } catch (e) {
        return Left(ServerFailure('Failed to update serial status: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot update serial status offline.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSerialNumber(String serialId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSerialNumber(serialId);
        await localDataSource.removeCachedSerialNumber(serialId);

        // ✅ Note: Should invalidate item cache here
        print('✅ SERIAL REPO: Deleted serial number');

        return Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to delete serial number: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot delete serial number offline.'));
    }
  }

  @override
  Future<Either<Failure, List<SerialNumber>>> bulkUpdateSerialStatus(
      List<String> serialIds,
      SerialStatus newStatus, {
        String? notes,
      }) async {
    if (await networkInfo.isConnected) {
      try {
        print('🔄 SERIAL REPO: Bulk updating ${serialIds.length} serials');
        final updatedSerials = await remoteDataSource.bulkUpdateSerialStatus(
          serialIds,
          newStatus,
          notes: notes,
        );

        // ✅ Update cache for each serial
        for (final serial in updatedSerials) {
          await localDataSource.cacheSerialNumber(serial);
          // Invalidate item cache
          await cacheService.invalidateCache(serial.itemId);
        }

        print('✅ SERIAL REPO: Bulk update complete and cache invalidated');
        return Right(updatedSerials);
      } catch (e) {
        return Left(ServerFailure('Failed to bulk update serial statuses: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot update serial statuses offline.'));
    }
  }

  // ✅ All other existing methods remain the same...
  // (getSerialNumbersByStatus, serialNumberExists, getSerialNumbersRequiringAttention, etc.)

  @override
  Future<Either<Failure, List<SerialNumber>>> getSerialNumbersByStatus(
      SerialStatus status) async {
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

  @override
  Future<Either<Failure, bool>> serialNumberExists(
      String serialNumber, {String? excludeId}) async {
    try {
      if (await networkInfo.isConnected) {
        final exists = await remoteDataSource.serialNumberExists(serialNumber, excludeId: excludeId);
        return Right(exists);
      } else {
        final cachedSerials = await localDataSource.getAllCachedSerialNumbers();
        final exists = cachedSerials.any((s) =>
        s.serialNumber.toLowerCase() == serialNumber.toLowerCase() &&
            (excludeId == null || s.id != excludeId));
        return Right(exists);
      }
    } catch (e) {
      return Left(ServerFailure('Failed to check serial number existence: $e'));
    }
  }

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
        final attentionSerials = cachedSerials
            .where((s) => s.status == SerialStatus.damaged || s.status == SerialStatus.recalled)
            .toList();
        return Right(attentionSerials);
      } catch (e) {
        return Left(CacheFailure('Failed to get cached serial numbers requiring attention: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSerialNumberHistory(String itemId) async {
    if (await networkInfo.isConnected) {
      try {
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

  // Continue with all your other existing methods (getSerialNumberUtilizationReport, searchInventoryItems, etc.)
  // They remain exactly the same...

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
          List<InventoryItem> filteredItems = items;
          if (categoryId != null) {
            filteredItems = items.where((item) => item.categoryId == categoryId).toList();
          }

          final serialTrackedItems = filteredItems.where((item) => item.isSerialTracked).toList();

          final totalItems = serialTrackedItems.length;
          final totalSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.totalSerialCount);
          final availableSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.availableStock);
          final soldSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.soldStock);
          final damagedSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.damagedStock);

          final utilizationRate = totalSerials > 0 ? (soldSerials / totalSerials) * 100 : 0.0;
          final damageRate = totalSerials > 0 ? (damagedSerials / totalSerials) * 100 : 0.0;

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

  @override
  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final searchResults = await remoteDataSource.searchInventoryItems(query);

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
        return _filterCachedItems(filters);
      }
    } else {
      return _filterCachedItems(filters);
    }
  }

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

  @override
  Stream<List<InventoryItem>> watchInventoryItems() async* {
    try {
      final result = await getAllInventoryItems();
      yield result.fold(
            (failure) => <InventoryItem>[],
            (items) => items,
      );

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

      List<InventoryItem> items = [];
      for (final model in filteredModels) {
        InventoryItem item = model.toEntity();

        if (item.isSerialTracked) {
          final cachedSerials = cacheService.getCachedSerialNumbers(item.id);
          if (cachedSerials != null) {
            item = item.copyWith(serialNumbers: cachedSerials);
          }
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

      if (filters.containsKey('category_id') && filters['category_id'] != null) {
        filteredItems = filteredItems.where((item) => item.categoryId == filters['category_id']).toList();
      }

      if (filters.containsKey('low_stock') && filters['low_stock'] == true) {
        filteredItems = filteredItems.where((item) => item.stockQuantity <= item.minStockLevel).toList();
      }

      if (filters.containsKey('min_price') && filters['min_price'] != null) {
        final minPrice = filters['min_price'] as double;
        filteredItems = filteredItems.where((item) => (item.unitPrice ?? 0.0) >= minPrice).toList();
      }

      if (filters.containsKey('max_price') && filters['max_price'] != null) {
        final maxPrice = filters['max_price'] as double;
        filteredItems = filteredItems.where((item) => (item.unitPrice ?? 0.0) <= maxPrice).toList();
      }

      if (filters.containsKey('subcategory') && filters['subcategory'] != null) {
        filteredItems = filteredItems
            .where((item) =>
            item.subcategory.toLowerCase().contains(filters['subcategory'].toString().toLowerCase()))
            .toList();
      }

      if (filters.containsKey('serial_tracked')) {
        final isSerialTracked = filters['serial_tracked'] as bool;
        filteredItems = filteredItems.where((item) => item.isSerialTracked == isSerialTracked).toList();
      }

      List<InventoryItem> items = [];
      for (final model in filteredItems) {
        InventoryItem item = model.toEntity();

        if (item.isSerialTracked) {
          final cachedSerials = cacheService.getCachedSerialNumbers(item.id);
          if (cachedSerials != null) {
            item = item.copyWith(serialNumbers: cachedSerials);
          }
        }

        items.add(item);
      }

      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to filter cached inventory items: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncOfflineChanges() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItems = await remoteDataSource.getAllInventoryItems();
        await localDataSource.cacheInventoryItems(remoteItems);

        // ✅ Clear all serial caches on sync
        await cacheService.clearAllCaches();
        print('🗑️ INVENTORY REPO: Cleared all serial caches during sync');

        for (final item in remoteItems) {
          if (item.isSerialTracked) {
            try {
              final remoteSerials = await remoteDataSource.getSerialNumbers(item.id);
              await localDataSource.cacheSerialNumbers(item.id, remoteSerials);

              // ✅ Cache in new service too
              await cacheService.cacheSerialNumbers(item.id, remoteSerials);
              final available = remoteSerials.where((s) => s.status == SerialStatus.available).length;
              await cacheService.cacheSerialCount(item.id, remoteSerials.length, available);
            } catch (e) {
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

  @override
  Future<Either<Failure, Map<String, dynamic>>> getInventoryStats() async {
    try {
      final itemsResult = await getAllInventoryItems();
      return itemsResult.fold(
            (failure) => Left(failure),
            (items) {
          final totalValue = items.fold<double>(0.0, (sum, item) => sum + item.totalValue);

          final itemsWithPrice = items.where((item) => item.unitPrice != null).toList();
          final averagePrice = itemsWithPrice.isNotEmpty
              ? itemsWithPrice.fold<double>(0.0, (sum, item) => sum + (item.unitPrice ?? 0.0)) /
              itemsWithPrice.length
              : 0.0;

          final serialTrackedItems = items.where((item) => item.isSerialTracked).toList();
          final totalSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.totalSerialCount);
          final availableSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.availableStock);
          final soldSerials = serialTrackedItems.fold<int>(0, (sum, item) => sum + item.soldStock);

          final stats = {
            'total_items': items.length,
            'total_value': totalValue,
            'low_stock_count': items.where((item) => item.needsRestock).length,
            'out_of_stock_count': items
                .where((item) => item.isSerialTracked ? item.availableStock == 0 : item.stockQuantity == 0)
                .length,
            'categories_count': items.map((item) => item.categoryId).toSet().length,
            'average_price': averagePrice,
            'items_with_price': itemsWithPrice.length,
            'items_without_price': items.length - itemsWithPrice.length,
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

  @override
  Future<Either<Failure, bool>> skuExists(String sku, {String? excludeId}) async {
    try {
      final itemsResult = await getAllInventoryItems();
      return itemsResult.fold(
            (failure) => Left(failure),
            (items) {
          final exists = items.any((item) =>
          item.sku.toLowerCase() == sku.toLowerCase() && (excludeId == null || item.id != excludeId));
          return Right(exists);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to check SKU existence: $e'));
    }
  }
}
