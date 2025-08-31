// data/datasources/inventory_local_datasource.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_item_model.dart';

abstract class InventoryLocalDataSource {
  Future<List<InventoryItemModel>> getCachedInventoryItems();
  Future<void> cacheInventoryItems(List<InventoryItemModel> items);
  Future<InventoryItemModel?> getCachedInventoryItem(String id);
  Future<void> cacheInventoryItem(InventoryItemModel item);
  Future<void> removeCachedInventoryItem(String id);
  Future<void> clearCache();
}

const CACHED_INVENTORY_ITEMS = 'CACHED_INVENTORY_ITEMS';
const CACHE_EXPIRY = 'CACHE_EXPIRY';

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final SharedPreferences sharedPreferences;

  InventoryLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<InventoryItemModel>> getCachedInventoryItems() async {
    try {
      // Check if cache is expired
      final expiryTime = sharedPreferences.getInt(CACHE_EXPIRY);
      if (expiryTime != null && DateTime.now().millisecondsSinceEpoch > expiryTime) {
        await clearCache();
        return [];
      }

      final jsonString = sharedPreferences.getString(CACHED_INVENTORY_ITEMS);
      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList
            .map((json) => InventoryItemModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
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
    } catch (e) {
      throw CacheException('Failed to cache inventory items: $e');
    }
  }

  @override
  Future<InventoryItemModel?> getCachedInventoryItem(String id) async {
    try {
      final items = await getCachedInventoryItems();
      for (final item in items) {
        if (item.id == id) {
          return item;
        }
      }
      return null;
    } catch (e) {
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
    } catch (e) {
      throw CacheException('Failed to cache inventory item: $e');
    }
  }

  @override
  Future<void> removeCachedInventoryItem(String id) async {
    try {
      final items = await getCachedInventoryItems();
      items.removeWhere((item) => item.id == id);
      await cacheInventoryItems(items);
    } catch (e) {
      throw CacheException('Failed to remove cached inventory item: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(CACHED_INVENTORY_ITEMS);
      await sharedPreferences.remove(CACHE_EXPIRY);
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
