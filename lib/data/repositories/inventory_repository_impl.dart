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

  @override
  Future<Either<Failure, List<InventoryItem>>> getAllInventoryItems() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItems = await remoteDataSource.getAllInventoryItems();
        await localDataSource.cacheInventoryItems(remoteItems);
        // Convert models to entities
        return Right(remoteItems.map((model) => model.toEntity()).toList());
      } catch (e) {
        // Fallback to cached data
        try {
          final cachedItems = await localDataSource.getCachedInventoryItems();
          return Right(cachedItems.map((model) => model.toEntity()).toList());
        } catch (cacheError) {
          return Left(ServerFailure('Failed to load inventory items: $e'));
        }
      }
    } else {
      try {
        final cachedItems = await localDataSource.getCachedInventoryItems();
        if (cachedItems.isNotEmpty) {
          return Right(cachedItems.map((model) => model.toEntity()).toList());
        } else {
          return Left(CacheFailure('No cached data available'));
        }
      } catch (e) {
        return Left(CacheFailure('Failed to load cached inventory items: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> getInventoryItem(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItem = await remoteDataSource.getInventoryItem(id);
        await localDataSource.cacheInventoryItem(remoteItem);
        return Right(remoteItem.toEntity());
      } catch (e) {
        // Fallback to cached data
        try {
          final cachedItem = await localDataSource.getCachedInventoryItem(id);
          if (cachedItem != null) {
            return Right(cachedItem.toEntity());
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
          return Right(cachedItem.toEntity());
        } else {
          return Left(CacheFailure('Item with ID $id not found in cache'));
        }
      } catch (e) {
        return Left(CacheFailure('Failed to load cached inventory item: $e'));
      }
    }
  }

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
        return Right(createdItem.toEntity());
      } catch (e) {
        return Left(ServerFailure('Failed to create inventory item: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot create items offline.'));
    }
  }

  @override
  Future<Either<Failure, InventoryItem>> updateInventoryItem(InventoryItem item) async {
    if (await networkInfo.isConnected) {
      try {
        final itemModel = InventoryItemModel.fromEntity(item);
        final updatedItem = await remoteDataSource.updateInventoryItem(itemModel);
        await localDataSource.cacheInventoryItem(updatedItem);
        return Right(updatedItem.toEntity());
      } catch (e) {
        return Left(ServerFailure('Failed to update inventory item: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection. Cannot update items offline.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInventoryItem(String id) async {
    if (await networkInfo.isConnected) {
      try {
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

  @override
  Future<Either<Failure, List<InventoryItem>>> searchInventoryItems(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final searchResults = await remoteDataSource.searchInventoryItems(query);
        return Right(searchResults.map((model) => model.toEntity()).toList());
      } catch (e) {
        // Fallback to local search
        return _searchCachedItems(query);
      }
    } else {
      return _searchCachedItems(query);
    }
  }

  Future<Either<Failure, List<InventoryItem>>> _searchCachedItems(String query) async {
    try {
      final cachedItems = await localDataSource.getCachedInventoryItems();
      final queryLower = query.toLowerCase();

      final filteredItems = cachedItems.where((item) {
        return item.nameEn.toLowerCase().contains(queryLower) ||
            item.nameAr.toLowerCase().contains(queryLower) ||
            item.sku.toLowerCase().contains(queryLower) ||
            item.subcategory.toLowerCase().contains(queryLower);
      }).toList();

      return Right(filteredItems.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to search cached inventory items: $e'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> filterInventoryItems(Map<String, dynamic> filters) async {
    if (await networkInfo.isConnected) {
      try {
        final filteredItems = await remoteDataSource.filterInventoryItems(filters);
        return Right(filteredItems.map((model) => model.toEntity()).toList());
      } catch (e) {
        // Fallback to local filtering
        return _filterCachedItems(filters);
      }
    } else {
      return _filterCachedItems(filters);
    }
  }

  Future<Either<Failure, List<InventoryItem>>> _filterCachedItems(Map<String, dynamic> filters) async {
    try {
      final cachedItems = await localDataSource.getCachedInventoryItems();
      List<InventoryItemModel> filteredItems = List.from(cachedItems);

      // Filter by category
      if (filters.containsKey('category_id') && filters['category_id'] != null) {
        filteredItems = filteredItems
            .where((item) => item.categoryId == filters['category_id'])
            .toList();
      }

      // Filter by low stock
      if (filters.containsKey('low_stock') && filters['low_stock'] == true) {
        filteredItems = filteredItems
            .where((item) => item.stockQuantity <= item.minStockLevel)
            .toList();
      }

      // Filter by minimum price
      if (filters.containsKey('min_price') && filters['min_price'] != null) {
        final minPrice = filters['min_price'] as double;
        filteredItems = filteredItems
            .where((item) => (item.unitPrice ?? 0.0) >= minPrice)
            .toList();
      }

      // Filter by maximum price
      if (filters.containsKey('max_price') && filters['max_price'] != null) {
        final maxPrice = filters['max_price'] as double;
        filteredItems = filteredItems
            .where((item) => (item.unitPrice ?? 0.0) <= maxPrice)
            .toList();
      }

      // Filter by subcategory
      if (filters.containsKey('subcategory') && filters['subcategory'] != null) {
        filteredItems = filteredItems
            .where((item) => item.subcategory.toLowerCase().contains(
            filters['subcategory'].toString().toLowerCase()))
            .toList();
      }

      // Filter by stock status
      if (filters.containsKey('stock_status')) {
        switch (filters['stock_status']) {
          case 'in_stock':
            filteredItems = filteredItems
                .where((item) => item.stockQuantity > item.minStockLevel)
                .toList();
            break;
          case 'low_stock':
            filteredItems = filteredItems
                .where((item) => item.stockQuantity <= item.minStockLevel && item.stockQuantity > 0)
                .toList();
            break;
          case 'out_of_stock':
            filteredItems = filteredItems
                .where((item) => item.stockQuantity == 0)
                .toList();
            break;
        }
      }

      // Filter by date range
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

      return Right(filteredItems.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to filter cached inventory items: $e'));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItem>>> getLowStockItems() async {
    try {
      final allItemsResult = await getAllInventoryItems();
      return allItemsResult.fold(
            (failure) => Left(failure),
            (items) {
          final lowStockItems = items.where((item) => item.isLowStock).toList();
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

  // Helper method to sync offline changes when connection is restored
  Future<Either<Failure, void>> syncOfflineChanges() async {
    if (await networkInfo.isConnected) {
      try {
        // Get all cached items and sync with remote
        final cachedItems = await localDataSource.getCachedInventoryItems();

        // This would typically involve checking for items marked as "dirty" or "pending sync"
        // For now, we'll just refresh the cache with latest remote data
        final remoteItems = await remoteDataSource.getAllInventoryItems();
        await localDataSource.cacheInventoryItems(remoteItems);

        return Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to sync offline changes: $e'));
      }
    } else {
      return Left(NetworkFailure('No internet connection for sync'));
    }
  }

  // Method to get inventory statistics
  Future<Either<Failure, Map<String, dynamic>>> getInventoryStats() async {
    try {
      final itemsResult = await getAllInventoryItems();
      return itemsResult.fold(
            (failure) => Left(failure),
            (items) {
              final totalValue = items.fold<double>(
                0.0,
                    (sum, item) => sum + (item.totalValue), // totalValue already handles null
              );
              final itemsWithPrice = items.where((item) => item.unitPrice != null).toList();
              final averagePrice = itemsWithPrice.isNotEmpty
                  ? itemsWithPrice.fold<double>(0.0, (sum, item) => sum + (item.unitPrice ?? 0.0)) / itemsWithPrice.length
                  : 0.0;
          final stats = {
            'total_items': items.length,
            'total_value': totalValue,
            'low_stock_count': items.where((item) => item.isLowStock).length,
            'out_of_stock_count': items.where((item) => item.stockQuantity == 0).length,
            'categories_count': items.map((item) => item.categoryId).toSet().length,
            'average_price': averagePrice,
            'items_with_price': itemsWithPrice.length,
            'items_without_price': items.length - itemsWithPrice.length
          };
          return Right(stats);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get inventory statistics: $e'));
    }
  }

  // Method to check if SKU exists
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
