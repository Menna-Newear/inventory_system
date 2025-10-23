// ✅ data/services/serial_number_cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/inventory_item.dart';

class SerialNumberCacheService {
  final SharedPreferences _prefs;
  static const String _serialCountPrefix = 'serial_count_';
  static const String _serialStatusPrefix = 'serial_status_';
  static const String _lastFetchPrefix = 'serial_fetch_';
  static const Duration _cacheDuration = Duration(minutes: 5);

  SerialNumberCacheService(this._prefs);

  // ✅ Cache serial count for an item (lightweight)
  Future<void> cacheSerialCount(String itemId, int total, int available) async {
    final data = {
      'total': total,
      'available': available,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString('$_serialCountPrefix$itemId', jsonEncode(data));
  }

  // ✅ Get cached serial count
  Map<String, int>? getCachedSerialCount(String itemId) {
    final cached = _prefs.getString('$_serialCountPrefix$itemId');
    if (cached == null) return null;

    try {
      final data = jsonDecode(cached);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        return null; // Expired
      }

      return {
        'total': data['total'] as int,
        'available': data['available'] as int,
      };
    } catch (e) {
      return null;
    }
  }

  // ✅ Cache full serial numbers (only when needed)
  Future<void> cacheSerialNumbers(String itemId, List<SerialNumber> serials) async {
    final data = {
      'serials': serials.map((s) => {
        'id': s.id,
        'serial_number': s.serialNumber,
        'status': s.status.toString(),
      }).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString('$_serialStatusPrefix$itemId', jsonEncode(data));
  }

  // ✅ Get cached serial numbers
  List<SerialNumber>? getCachedSerialNumbers(String itemId) {
    final cached = _prefs.getString('$_serialStatusPrefix$itemId');
    if (cached == null) return null;

    try {
      final data = jsonDecode(cached);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);

      // Check if cache is still valid (shorter duration for full list)
      if (DateTime.now().difference(timestamp) > Duration(minutes: 2)) {
        return null; // Expired
      }

      return (data['serials'] as List).map((s) => SerialNumber(
        id: s['id'],
        itemId: itemId,
        serialNumber: s['serial_number'],
        status: _parseStatus(s['status']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
    } catch (e) {
      return null;
    }
  }

  // ✅ Invalidate cache when data changes
  Future<void> invalidateCache(String itemId) async {
    await _prefs.remove('$_serialCountPrefix$itemId');
    await _prefs.remove('$_serialStatusPrefix$itemId');
    await _prefs.remove('$_lastFetchPrefix$itemId');
    print('🗑️ CACHE: Invalidated cache for item: $itemId');
  }

  // ✅ Clear all serial caches
  Future<void> clearAllCaches() async {
    final keys = _prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_serialCountPrefix) ||
          key.startsWith(_serialStatusPrefix) ||
          key.startsWith(_lastFetchPrefix)) {
        await _prefs.remove(key);
      }
    }
    print('🗑️ CACHE: Cleared all serial caches');
  }

  SerialStatus _parseStatus(String status) {
    return SerialStatus.values.firstWhere(
          (s) => s.toString() == status,
      orElse: () => SerialStatus.available,
    );
  }
}
