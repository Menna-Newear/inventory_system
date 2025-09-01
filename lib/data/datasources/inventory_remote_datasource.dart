// data/datasources/inventory_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item_model.dart';
import '../../core/constants/supabase_constants.dart';

abstract class InventoryRemoteDataSource {
  Future<List<InventoryItemModel>> getAllInventoryItems();

  Future<InventoryItemModel> getInventoryItem(String id);

  Future<InventoryItemModel> createInventoryItem(InventoryItemModel item);

  Future<InventoryItemModel> updateInventoryItem(InventoryItemModel item);

  Future<void> deleteInventoryItem(String id);

  Future<List<InventoryItemModel>> searchInventoryItems(String query);

  Future<List<InventoryItemModel>> filterInventoryItems(
    Map<String, dynamic> filters,
  );
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final SupabaseClient supabase;

  InventoryRemoteDataSourceImpl({required this.supabase});

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
  Future<InventoryItemModel> createInventoryItem(
    InventoryItemModel item,
  ) async {
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
  Future<InventoryItemModel> updateInventoryItem(
    InventoryItemModel item,
  ) async {
    try {
      print('🟡 REMOTE: Starting update for item: ${item.id}');
      print('🟡 REMOTE: Item data being sent to Supabase:');
      final dataToSend = item.toSupabase();
      print('🟡 REMOTE: descriptionEn: ${dataToSend['description_en']}');
      print('🟡 REMOTE: descriptionAr: ${dataToSend['description_ar']}');
      print('🟡 REMOTE: comment: ${dataToSend['comment']}');
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
      print('🟢 REMOTE: Full response: $response');

      final resultModel = InventoryItemModel.fromSupabase(response);
      print(
        '🟢 REMOTE: Converted model descriptionEn: ${resultModel.descriptionEn}',
      );
      print(
        '🟢 REMOTE: Converted model descriptionAr: ${resultModel.descriptionAr}',
      );
      print('🟢 REMOTE: Converted model comment: ${resultModel.comment}');

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
          .or(
            'name_en.ilike.%$query%,name_ar.ilike.%$query%,sku.ilike.%$query%',
          )
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => InventoryItemModel.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inventory items: $e');
    }
  }

  @override
  Future<List<InventoryItemModel>> filterInventoryItems(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = supabase.from(SupabaseConstants.inventoryTable).select();

      // Apply filters
      if (filters['category_id'] != null) {
        query = query.eq('category_id', filters['category_id']);
      }

      if (filters['low_stock'] == true) {
        query = query.filter(
          'stock_quantity',
          'lte',
          filters['min_stock_level'] ?? 0,
        );
      }

      if (filters['min_price'] != null) {
        query = query.gte('unit_price', filters['min_price']);
      }

      if (filters['max_price'] != null) {
        query = query.lte('unit_price', filters['max_price']);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((item) => InventoryItemModel.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to filter inventory items: $e');
    }
  }
}
