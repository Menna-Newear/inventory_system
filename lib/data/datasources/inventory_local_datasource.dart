// data/datasources/inventory_local_datasource.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_item_model.dart';
import '../../domain/entities/inventory_item.dart';

abstract class InventoryLocalDataSource {
  // ✅ EXISTING - Inventory Item Caching
  Future<List<InventoryItemModel>> getCachedInventoryItems();
  Future<void> cacheInventoryItems(List<InventoryItemModel> items);
  Future<InventoryItemModel?> getCachedInventoryItem(String id);
  Future<void> cacheInventoryItem(InventoryItemModel item);
  Future<void> removeCachedInventoryItem(String id);
  Future<void> clearCache();

  // ✅ NEW - Serial Number Caching
  Future<List<SerialNumber>> getCachedSerialNumbers(String itemId);
  Future<void> cacheSerialNumbers(String itemId, List<SerialNumber> serialNumbers);
  Future<List<SerialNumber>> getAllCachedSerialNumbers();
  Future<void> cacheSerialNumber(SerialNumber serialNumber);
  Future<void> removeCachedSerialNumber(String serialId);
  Future<void> clearSerialCache({String? itemId});
}

// ✅ CACHE KEYS CONSTANTS
const CACHED_INVENTORY_ITEMS = 'CACHED_INVENTORY_ITEMS';
const CACHED_SERIAL_NUMBERS = 'CACHED_SERIAL_NUMBERS';
const CACHE_EXPIRY = 'CACHE_EXPIRY';
const SERIAL_CACHE_EXPIRY = 'SERIAL_CACHE_EXPIRY';

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final SharedPreferences sharedPreferences;

  InventoryLocalDataSourceImpl({required this.sharedPreferences});

  // ✅ EXISTING METHODS - Enhanced with better error handling

  @override
  Future<List<InventoryItemModel>> getCachedInventoryItems() async {
    try {
      // Check if cache is expired
      final expiryTime = sharedPreferences.getInt(CACHE_EXPIRY);
      if (expiryTime != null && DateTime.now().millisecondsSinceEpoch > expiryTime) {
        print('🟡 LOCAL: Inventory cache expired, clearing...');
        await clearCache();
        return [];
      }

      final jsonString = sharedPreferences.getString(CACHED_INVENTORY_ITEMS);
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        final items = jsonList
            .map((json) => InventoryItemModel.fromJson(json))
            .toList();

        print('🟢 LOCAL: Retrieved ${items.length} cached inventory items');
        return items;
      }

      print('🟡 LOCAL: No cached inventory items found');
      return [];
    } catch (e) {
      print('❌ LOCAL: Failed to get cached inventory items: $e');
      throw CacheException('Failed to get cached inventory items: $e');
    }
  }

  @override
  Future<void> cacheInventoryItems(List<InventoryItemModel> items) async {
    try {
      final jsonString = jsonEncode(items.map((item) => item.toJson()).toList());
      await sharedPreferences.setString(CACHED_INVENTORY_ITEMS, jsonString);

      // Set cache expiry to 1 hour from now
      final expiryTime = DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch;
      await sharedPreferences.setInt(CACHE_EXPIRY, expiryTime);

      print('🟢 LOCAL: Cached ${items.length} inventory items');
    } catch (e) {
      print('❌ LOCAL: Failed to cache inventory items: $e');
      throw CacheException('Failed to cache inventory items: $e');
    }
  }

  @override
  Future<InventoryItemModel?> getCachedInventoryItem(String id) async {
    try {
      final items = await getCachedInventoryItems();
      for (final item in items) {
        if (item.id == id) {
          print('🟢 LOCAL: Found cached inventory item: $id');
          return item;
        }
      }

      print('🟡 LOCAL: Inventory item not found in cache: $id');
      return null;
    } catch (e) {
      print('❌ LOCAL: Failed to get cached inventory item: $e');
      throw CacheException('Failed to get cached inventory item: $e');
    }
  }

  @override
  Future<void> cacheInventoryItem(InventoryItemModel item) async {
    try {
      final items = await getCachedInventoryItems();

      // Remove existing item with same ID
      items.removeWhere((cachedItem) => cachedItem.id == item.id);

      // Add new item
      items.add(item);

      await cacheInventoryItems(items);
      print('🟢 LOCAL: Cached single inventory item: ${item.id}');
    } catch (e) {
      print('❌ LOCAL: Failed to cache inventory item: $e');
      throw CacheException('Failed to cache inventory item: $e');
    }
  }

  @override
  Future<void> removeCachedInventoryItem(String id) async {
    try {
      final items = await getCachedInventoryItems();
      final initialCount = items.length;
      items.removeWhere((item) => item.id == id);

      if (items.length < initialCount) {
        await cacheInventoryItems(items);
        // Also remove associated serial numbers
        await clearSerialCache(itemId: id);
        print('🟢 LOCAL: Removed cached inventory item and serials: $id');
      } else {
        print('🟡 LOCAL: Inventory item not found for removal: $id');
      }
    } catch (e) {
      print('❌ LOCAL: Failed to remove cached inventory item: $e');
      throw CacheException('Failed to remove cached inventory item: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(CACHED_INVENTORY_ITEMS);
      await sharedPreferences.remove(CACHE_EXPIRY);
      await clearSerialCache(); // Clear all serial caches too
      print('🟢 LOCAL: Cleared all inventory cache');
    } catch (e) {
      print('❌ LOCAL: Failed to clear cache: $e');
      throw CacheException('Failed to clear cache: $e');
    }
  }

  // ✅ NEW - SERIAL NUMBER CACHING METHODS

  @override
  Future<List<SerialNumber>> getCachedSerialNumbers(String itemId) async {
    try {
      // Check if serial cache is expired
      final expiryTime = sharedPreferences.getInt('${SERIAL_CACHE_EXPIRY}_$itemId');
      if (expiryTime != null && DateTime.now().millisecondsSinceEpoch > expiryTime) {
        print('🟡 LOCAL: Serial cache expired for item: $itemId, clearing...');
        await clearSerialCache(itemId: itemId);
        return [];
      }

      final jsonString = sharedPreferences.getString('${CACHED_SERIAL_NUMBERS}_$itemId');
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        final serials = jsonList
            .map((json) => SerialNumber.fromJson(json))
            .toList();

        print('🟢 LOCAL: Retrieved ${serials.length} cached serial numbers for item: $itemId');
        return serials;
      }

      print('🟡 LOCAL: No cached serial numbers found for item: $itemId');
      return [];
    } catch (e) {
      print('❌ LOCAL: Failed to get cached serial numbers for item $itemId: $e');
      throw CacheException('Failed to get cached serial numbers: $e');
    }
  }

  @override
  Future<void> cacheSerialNumbers(String itemId, List<SerialNumber> serialNumbers) async {
    try {
      final jsonString = jsonEncode(serialNumbers.map((serial) => serial.toJson()).toList());
      await sharedPreferences.setString('${CACHED_SERIAL_NUMBERS}_$itemId', jsonString);

      // Set serial cache expiry to 30 minutes from now (shorter than inventory cache)
      final expiryTime = DateTime.now().add(Duration(minutes: 30)).millisecondsSinceEpoch;
      await sharedPreferences.setInt('${SERIAL_CACHE_EXPIRY}_$itemId', expiryTime);

      print('🟢 LOCAL: Cached ${serialNumbers.length} serial numbers for item: $itemId');
    } catch (e) {
      print('❌ LOCAL: Failed to cache serial numbers for item $itemId: $e');
      throw CacheException('Failed to cache serial numbers: $e');
    }
  }

  @override
  Future<List<SerialNumber>> getAllCachedSerialNumbers() async {
    try {
      final allSerials = <SerialNumber>[];
      final keys = sharedPreferences.getKeys()
          .where((key) => key.startsWith(CACHED_SERIAL_NUMBERS))
          .toList();

      print('🟡 LOCAL: Found ${keys.length} serial cache keys');

      for (final key in keys) {
        try {
          final itemId = key.replaceFirst('${CACHED_SERIAL_NUMBERS}_', '');
          final serials = await getCachedSerialNumbers(itemId);
          allSerials.addAll(serials);
        } catch (e) {
          print('⚠️ LOCAL: Failed to load serials from key $key: $e');
          // Continue with other keys
        }
      }

      print('🟢 LOCAL: Retrieved ${allSerials.length} total cached serial numbers');
      return allSerials;
    } catch (e) {
      print('❌ LOCAL: Failed to get all cached serial numbers: $e');
      throw CacheException('Failed to get all cached serial numbers: $e');
    }
  }

  @override
  Future<void> cacheSerialNumber(SerialNumber serialNumber) async {
    try {
      final serials = await getCachedSerialNumbers(serialNumber.itemId);
      final existingIndex = serials.indexWhere((s) => s.id == serialNumber.id);

      if (existingIndex != -1) {
        serials[existingIndex] = serialNumber;
        print('🟢 LOCAL: Updated cached serial number: ${serialNumber.serialNumber}');
      } else {
        serials.add(serialNumber);
        print('🟢 LOCAL: Added cached serial number: ${serialNumber.serialNumber}');
      }

      await cacheSerialNumbers(serialNumber.itemId, serials);
    } catch (e) {
      print('❌ LOCAL: Failed to cache serial number: $e');
      throw CacheException('Failed to cache serial number: $e');
    }
  }

  @override
  Future<void> removeCachedSerialNumber(String serialId) async {
    try {
      // First, find which item this serial belongs to
      final allSerials = await getAllCachedSerialNumbers();
      final serialToRemove = allSerials.firstWhere(
            (s) => s.id == serialId,
        orElse: () => throw CacheException('Serial number not found: $serialId'),
      );

      // Get current serials for the item
      final itemSerials = await getCachedSerialNumbers(serialToRemove.itemId);
      final initialCount = itemSerials.length;

      // Remove the specific serial
      itemSerials.removeWhere((s) => s.id == serialId);

      if (itemSerials.length < initialCount) {
        await cacheSerialNumbers(serialToRemove.itemId, itemSerials);
        print('🟢 LOCAL: Removed cached serial number: $serialId');
      } else {
        print('🟡 LOCAL: Serial number not found for removal: $serialId');
      }
    } catch (e) {
      print('❌ LOCAL: Failed to remove cached serial number: $e');
      throw CacheException('Failed to remove cached serial number: $e');
    }
  }

  @override
  Future<void> clearSerialCache({String? itemId}) async {
    try {
      if (itemId != null) {
        // Clear cache for specific item
        await sharedPreferences.remove('${CACHED_SERIAL_NUMBERS}_$itemId');
        await sharedPreferences.remove('${SERIAL_CACHE_EXPIRY}_$itemId');
        print('🟢 LOCAL: Cleared serial cache for item: $itemId');
      } else {
        // Clear all serial caches
        final keys = sharedPreferences.getKeys()
            .where((key) => key.startsWith(CACHED_SERIAL_NUMBERS) || key.startsWith(SERIAL_CACHE_EXPIRY))
            .toList();

        for (final key in keys) {
          await sharedPreferences.remove(key);
        }

        print('🟢 LOCAL: Cleared all serial caches (${keys.length} keys)');
      }
    } catch (e) {
      print('❌ LOCAL: Failed to clear serial cache: $e');
      throw CacheException('Failed to clear serial cache: $e');
    }
  }

  // ✅ NEW - ADVANCED CACHE MANAGEMENT

  /// Get cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final inventoryItems = await getCachedInventoryItems();
      final allSerials = await getAllCachedSerialNumbers();

      // Count serial numbers per item
      final serialsByItem = <String, int>{};
      for (final serial in allSerials) {
        serialsByItem[serial.itemId] = (serialsByItem[serial.itemId] ?? 0) + 1;
      }

      // Check cache expiry times
      final inventoryExpiry = sharedPreferences.getInt(CACHE_EXPIRY);
      final now = DateTime.now().millisecondsSinceEpoch;

      final stats = {
        'cached_inventory_items': inventoryItems.length,
        'cached_serial_numbers': allSerials.length,
        'items_with_serials': serialsByItem.length,
        'inventory_cache_expired': inventoryExpiry != null ? now > inventoryExpiry : true,
        'inventory_cache_expires_in_minutes': inventoryExpiry != null
            ? ((inventoryExpiry - now) / 1000 / 60).round()
            : 0,
        'cache_size_breakdown': serialsByItem,
        'last_updated': DateTime.now().toIso8601String(),
      };

      print('🔍 LOCAL: Cache stats: $stats');
      return stats;
    } catch (e) {
      print('❌ LOCAL: Failed to get cache stats: $e');
      throw CacheException('Failed to get cache stats: $e');
    }
  }

  /// Optimize cache by removing expired entries
  Future<void> optimizeCache() async {
    try {
      print('🟡 LOCAL: Starting cache optimization...');

      int removedItems = 0;
      int removedSerials = 0;

      // Check and remove expired inventory cache
      final inventoryExpiry = sharedPreferences.getInt(CACHE_EXPIRY);
      if (inventoryExpiry != null && DateTime.now().millisecondsSinceEpoch > inventoryExpiry) {
        await sharedPreferences.remove(CACHED_INVENTORY_ITEMS);
        await sharedPreferences.remove(CACHE_EXPIRY);
        removedItems = (await getCachedInventoryItems()).length;
      }

      // Check and remove expired serial caches
      final serialKeys = sharedPreferences.getKeys()
          .where((key) => key.startsWith(SERIAL_CACHE_EXPIRY))
          .toList();

      for (final expiryKey in serialKeys) {
        final expiryTime = sharedPreferences.getInt(expiryKey);
        if (expiryTime != null && DateTime.now().millisecondsSinceEpoch > expiryTime) {
          final itemId = expiryKey.replaceFirst('${SERIAL_CACHE_EXPIRY}_', '');
          final serialCount = (await getCachedSerialNumbers(itemId)).length;

          await sharedPreferences.remove(expiryKey);
          await sharedPreferences.remove('${CACHED_SERIAL_NUMBERS}_$itemId');

          removedSerials += serialCount;
        }
      }

      print('🟢 LOCAL: Cache optimization complete - Removed $removedItems items, $removedSerials serials');
    } catch (e) {
      print('❌ LOCAL: Cache optimization failed: $e');
      throw CacheException('Cache optimization failed: $e');
    }
  }

  /// Check if cache is healthy and within size limits
  Future<bool> isCacheHealthy() async {
    try {
      final stats = await getCacheStats();

      // Define health criteria
      const maxInventoryItems = 1000;
      const maxSerialNumbers = 5000;

      final isHealthy =
          stats['cached_inventory_items'] <= maxInventoryItems &&
              stats['cached_serial_numbers'] <= maxSerialNumbers;

      print('🔍 LOCAL: Cache health check: ${isHealthy ? 'HEALTHY' : 'UNHEALTHY'}');

      if (!isHealthy) {
        print('⚠️ LOCAL: Cache limits exceeded - Consider optimization');
      }

      return isHealthy;
    } catch (e) {
      print('❌ LOCAL: Cache health check failed: $e');
      return false;
    }
  }
}

// ✅ ENHANCED EXCEPTION CLASS
class CacheException implements Exception {
  final String message;
  final String? code;
  final DateTime timestamp;

  CacheException(this.message, {this.code})
      : timestamp = DateTime.now();

  @override
  String toString() {
    return 'CacheException${code != null ? ' ($code)' : ''}: $message';
  }
}
