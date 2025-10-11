// data/datasources/inventory_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item_model.dart';
import '../../core/constants/supabase_constants.dart';
import '../../domain/entities/inventory_item.dart';

abstract class InventoryRemoteDataSource {
  // ✅ EXISTING - Core Inventory Operations
  Future<List<InventoryItemModel>> getAllInventoryItems();
  Future<InventoryItemModel> getInventoryItem(String id);
  Future<InventoryItemModel> createInventoryItem(InventoryItemModel item);
  Future<InventoryItemModel> updateInventoryItem(InventoryItemModel item);
  Future<void> deleteInventoryItem(String id);
  Future<List<InventoryItemModel>> searchInventoryItems(String query);
  Future<List<InventoryItemModel>> filterInventoryItems(Map<String, dynamic> filters);

  // ✅ NEW - Serial Number Operations
  Future<List<SerialNumber>> addSerialNumbers(String itemId, List<SerialNumber> serialNumbers);
  Future<List<SerialNumber>> getSerialNumbers(String itemId);
  Future<SerialNumber> updateSerialStatus(String serialId, SerialStatus newStatus, {String? notes});
  Future<void> deleteSerialNumber(String serialId);
  Future<void> deleteAllSerialNumbers(String itemId);
  Future<List<SerialNumber>> getSerialNumbersByStatus(SerialStatus status);
  Future<bool> serialNumberExists(String serialNumber, {String? excludeId});
  Future<List<SerialNumber>> bulkUpdateSerialStatus(List<String> serialIds, SerialStatus newStatus, {String? notes});
  Future<List<SerialNumber>> getSerialNumbersRequiringAttention();

}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final SupabaseClient supabase;

  InventoryRemoteDataSourceImpl({required this.supabase});

  // ✅ EXISTING METHODS - Enhanced with debug logging

  @override
  Future<List<InventoryItemModel>> getAllInventoryItems() async {
    try {
      final response = await supabase
          .from(SupabaseConstants.inventoryTable)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => InventoryItemModel.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inventory items: $e');
    }
  }

  @override
  Future<InventoryItemModel> getInventoryItem(String id) async {
    try {
      final response = await supabase
          .from(SupabaseConstants.inventoryTable)
          .select()
          .eq('id', id)
          .single();

      return InventoryItemModel.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to fetch inventory item: $e');
    }
  }

  @override
  Future<InventoryItemModel> createInventoryItem(InventoryItemModel item) async {
    try {
      final response = await supabase
          .from(SupabaseConstants.inventoryTable)
          .insert(item.toSupabase())
          .select()
          .single();

      return InventoryItemModel.fromSupabase(response);
    } catch (e) {
      throw Exception('Failed to create inventory item: $e');
    }
  }

  @override
  Future<InventoryItemModel> updateInventoryItem(InventoryItemModel item) async {
    try {
      print('🟡 REMOTE: Starting update for item: ${item.id}');
      print('🟡 REMOTE: Item data being sent to Supabase:');
      final dataToSend = item.toSupabase();
      print('🟡 REMOTE: descriptionEn: ${dataToSend['description_en']}');
      print('🟡 REMOTE: descriptionAr: ${dataToSend['description_ar']}');
      print('🟡 REMOTE: comment: ${dataToSend['comment']}');
      print('🟡 REMOTE: is_serial_tracked: ${dataToSend['is_serial_tracked']}');
      print('🟡 REMOTE: serial_number_prefix: ${dataToSend['serial_number_prefix']}');
      print('🟡 REMOTE: Full data: $dataToSend');

      final response = await supabase
          .from(SupabaseConstants.inventoryTable)
          .update(item.toSupabase())
          .eq('id', item.id)
          .select()
          .single();

      print('🟢 REMOTE: Database response received:');
      print('🟢 REMOTE: Response descriptionEn: ${response['description_en']}');
      print('🟢 REMOTE: Response descriptionAr: ${response['description_ar']}');
      print('🟢 REMOTE: Response comment: ${response['comment']}');
      print('🟢 REMOTE: Response is_serial_tracked: ${response['is_serial_tracked']}');
      print('🟢 REMOTE: Full response: $response');

      final resultModel = InventoryItemModel.fromSupabase(response);
      print('🟢 REMOTE: Converted model descriptionEn: ${resultModel.descriptionEn}');
      print('🟢 REMOTE: Converted model descriptionAr: ${resultModel.descriptionAr}');
      print('🟢 REMOTE: Converted model comment: ${resultModel.comment}');
      print('🟢 REMOTE: Converted model isSerialTracked: ${resultModel.isSerialTracked}');

      return resultModel;
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    try {
      await supabase
          .from(SupabaseConstants.inventoryTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }

  @override
  Future<List<InventoryItemModel>> searchInventoryItems(String query) async {
    try {
      final response = await supabase
          .from(SupabaseConstants.inventoryTable)
          .select()
          .or('name_en.ilike.%$query%,name_ar.ilike.%$query%,sku.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => InventoryItemModel.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inventory items: $e');
    }
  }

  @override
  Future<List<InventoryItemModel>> filterInventoryItems(Map<String, dynamic> filters) async {
    try {
      var query = supabase.from(SupabaseConstants.inventoryTable).select();

      // Apply existing filters
      if (filters['category_id'] != null) {
        query = query.eq('category_id', filters['category_id']);
      }

      if (filters['low_stock'] == true) {
        query = query.filter('stock_quantity', 'lte', filters['min_stock_level'] ?? 0);
      }

      if (filters['min_price'] != null) {
        query = query.gte('unit_price', filters['min_price']);
      }

      if (filters['max_price'] != null) {
        query = query.lte('unit_price', filters['max_price']);
      }

      // ✅ NEW - Serial tracking filter
      if (filters['serial_tracked'] != null) {
        query = query.eq('is_serial_tracked', filters['serial_tracked']);
      }

      // ✅ NEW - Subcategory filter
      if (filters['subcategory'] != null) {
        query = query.ilike('subcategory', '%${filters['subcategory']}%');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((item) => InventoryItemModel.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to filter inventory items: $e');
    }
  }

  // ✅ NEW - SERIAL NUMBER OPERATIONS

  @override
  Future<List<SerialNumber>> addSerialNumbers(String itemId, List<SerialNumber> serialNumbers) async {
    try {
      print('🟡 REMOTE: Adding ${serialNumbers.length} serial numbers for item: $itemId');

      final serialData = serialNumbers.map((serial) => {
        'item_id': itemId,
        'serial_number': serial.serialNumber,
        'status': serial.status.name,
        'notes': serial.notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();

      print('🟡 REMOTE: Serial data to insert: $serialData');

      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .insert(serialData)
          .select();

      print('🟢 REMOTE: Successfully added ${response.length} serial numbers');

      return (response as List).map((json) => SerialNumber.fromJson(json)).toList();
    } catch (e) {
      print('❌ REMOTE: Failed to add serial numbers: $e');
      throw Exception('Failed to add serial numbers: $e');
    }
  }

  @override
  Future<List<SerialNumber>> getSerialNumbers(String itemId) async {
    try {
      print('🟡 REMOTE: Fetching serial numbers for item: $itemId');

      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .select()
          .eq('item_id', itemId)
          .order('created_at', ascending: false);

      print('🟢 REMOTE: Found ${response.length} serial numbers for item: $itemId');

      return (response as List).map((json) => SerialNumber.fromJson(json)).toList();
    } catch (e) {
      print('❌ REMOTE: Failed to get serial numbers: $e');
      throw Exception('Failed to get serial numbers: $e');
    }
  }

  @override
  Future<SerialNumber> updateSerialStatus(
      String serialId,
      SerialStatus newStatus, {
        String? notes,
      }) async {
    try {
      print('🟡 REMOTE: Updating serial $serialId to status: ${newStatus.name}');

      final updateData = {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      print('🟡 REMOTE: Update data: $updateData');

      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .update(updateData)
          .eq('id', serialId)
          .select()
          .single();

      print('🟢 REMOTE: Successfully updated serial status');

      return SerialNumber.fromJson(response);
    } catch (e) {
      print('❌ REMOTE: Failed to update serial status: $e');
      throw Exception('Failed to update serial status: $e');
    }
  }

  @override
  Future<void> deleteSerialNumber(String serialId) async {
    try {
      print('🟡 REMOTE: Deleting serial number: $serialId');

      await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .delete()
          .eq('id', serialId);

      print('🟢 REMOTE: Successfully deleted serial number');
    } catch (e) {
      print('❌ REMOTE: Failed to delete serial number: $e');
      throw Exception('Failed to delete serial number: $e');
    }
  }

  @override
  Future<void> deleteAllSerialNumbers(String itemId) async {
    try {
      print('🟡 REMOTE: Deleting all serial numbers for item: $itemId');

      await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .delete()
          .eq('item_id', itemId);

      print('🟢 REMOTE: Successfully deleted all serial numbers for item');
    } catch (e) {
      print('❌ REMOTE: Failed to delete all serial numbers: $e');
      throw Exception('Failed to delete all serial numbers: $e');
    }
  }

  @override
  Future<List<SerialNumber>> getSerialNumbersByStatus(SerialStatus status) async {
    try {
      print('🟡 REMOTE: Fetching serial numbers with status: ${status.name}');

      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .select()
          .eq('status', status.name)
          .order('created_at', ascending: false);

      print('🟢 REMOTE: Found ${response.length} serial numbers with status: ${status.name}');

      return (response as List).map((json) => SerialNumber.fromJson(json)).toList();
    } catch (e) {
      print('❌ REMOTE: Failed to get serial numbers by status: $e');
      throw Exception('Failed to get serial numbers by status: $e');
    }
  }

  @override
  Future<bool> serialNumberExists(String serialNumber, {String? excludeId}) async {
    try {
      print('🟡 REMOTE: Checking if serial number exists: $serialNumber');

      var query = supabase
          .from(SupabaseConstants.serialNumbersTable)
          .select('id')
          .eq('serial_number', serialNumber);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      final exists = (response as List).isNotEmpty;

      print('🟢 REMOTE: Serial number $serialNumber exists: $exists');

      return exists;
    } catch (e) {
      print('❌ REMOTE: Failed to check serial number existence: $e');
      throw Exception('Failed to check serial number existence: $e');
    }
  }

  @override
  Future<List<SerialNumber>> bulkUpdateSerialStatus(
      List<String> serialIds,
      SerialStatus newStatus, {
        String? notes,
      }) async {
    try {
      print('🟡 REMOTE: Bulk updating ${serialIds.length} serial numbers to status: ${newStatus.name}');

      final updateData = {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      print('🟡 REMOTE: Bulk update data: $updateData');
      print('🟡 REMOTE: Serial IDs: $serialIds');

      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .update(updateData)
          .inFilter('id', serialIds)  // ✅ CHANGED from .in('id', serialIds)
          .select();

      print('🟢 REMOTE: Successfully bulk updated ${response.length} serial numbers');

      return (response as List).map((json) => SerialNumber.fromJson(json)).toList();
    } catch (e) {
      print('❌ REMOTE: Failed to bulk update serial statuses: $e');
      throw Exception('Failed to bulk update serial statuses: $e');
    }
  }

  // ✅ NEW - ADVANCED SERIAL NUMBER QUERIES

  /// Get serial numbers that require attention (damaged, recalled, etc.)
  Future<List<SerialNumber>> getSerialNumbersRequiringAttention() async {
    try {
      print('🟡 REMOTE: Fetching serial numbers requiring attention');

      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .select()
          .inFilter('status', ['damaged', 'recalled'])  // ✅ CHANGED from .in('status', [...])
          .order('updated_at', ascending: false);

      print('🟢 REMOTE: Found ${response.length} serial numbers requiring attention');

      return (response as List).map((json) => SerialNumber.fromJson(json)).toList();
    } catch (e) {
      print('❌ REMOTE: Failed to get serial numbers requiring attention: $e');
      throw Exception('Failed to get serial numbers requiring attention: $e');
    }
  }

  /// Get serial number statistics for reporting
  Future<Map<String, dynamic>> getSerialNumberStats() async {
    try {
      print('🟡 REMOTE: Fetching serial number statistics');

      // Get counts by status
      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .select('status')
          .order('status');

      final statusCounts = <String, int>{};
      for (final row in response) {
        final status = row['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      final stats = {
        'total_serials': response.length,
        'status_breakdown': statusCounts,
        'last_updated': DateTime.now().toIso8601String(),
      };

      print('🟢 REMOTE: Serial number stats: $stats');

      return stats;
    } catch (e) {
      print('❌ REMOTE: Failed to get serial number stats: $e');
      throw Exception('Failed to get serial number stats: $e');
    }
  }

  /// Search serial numbers across all items
  Future<List<SerialNumber>> searchSerialNumbers(String query) async {
    try {
      print('🟡 REMOTE: Searching serial numbers with query: $query');

      final response = await supabase
          .from(SupabaseConstants.serialNumbersTable)
          .select()
          .ilike('serial_number', '%$query%')
          .order('created_at', ascending: false);

      print('🟢 REMOTE: Found ${response.length} serial numbers matching query');

      return (response as List).map((json) => SerialNumber.fromJson(json)).toList();
    } catch (e) {
      print('❌ REMOTE: Failed to search serial numbers: $e');
      throw Exception('Failed to search serial numbers: $e');
    }
  }
}
