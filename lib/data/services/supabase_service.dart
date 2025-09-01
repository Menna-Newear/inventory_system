/*
// data/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/inventory_item.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // ✅ UPDATED - Create inventory item with new fields
  Future<void> createInventoryItem(InventoryItem item) async {
    await supabase.from('inventory_items').insert({
      'sku': item.sku,
      'name_en': item.nameEn,
      'name_ar': item.nameAr,
      'description_en': item.descriptionEn,        // ✅ NEW
      'description_ar': item.descriptionAr,        // ✅ NEW
      'category_id': item.categoryId,
      'subcategory': item.subcategory,
      'stock_quantity': item.stockQuantity,
      'unit_price': item.unitPrice,
      'min_stock_level': item.minStockLevel,
      'dimensions': item.dimensions.toJson(),       // ✅ JSON serialized
      'image_properties': item.imageProperties.toJson(), // ✅ JSON serialized
      'image_url': item.imageUrl,
      'image_filename': item.imageFileName,
      'comment': item.comment,                      // ✅ NEW
    });
  }

  // ✅ UPDATED - Fetch inventory items with new fields
  Future<List<InventoryItem>> getInventoryItems() async {
    final response = await supabase
        .from('inventory_items')
        .select()
        .order('created_at', ascending: false);

    return response.map<InventoryItem>((json) {
      // Handle nested JSON objects
      return InventoryItem(
        id: json['id'],
        sku: json['sku'],
        nameEn: json['name_en'] ?? '',
        nameAr: json['name_ar'] ?? '',
        descriptionEn: json['description_en'],      // ✅ NEW - nullable
        descriptionAr: json['description_ar'],      // ✅ NEW - nullable
        categoryId: json['category_id'],
        subcategory: json['subcategory'] ?? '',
        stockQuantity: json['stock_quantity'] ?? 0,
        unitPrice: json['unit_price']?.toDouble(),
        minStockLevel: json['min_stock_level'] ?? 0,
        dimensions: json['dimensions'] != null
            ? ProductDimensions.fromJson(json['dimensions'])
            : ProductDimensions(width: 0, height: 0),
        imageProperties: json['image_properties'] != null
            ? ImageProperties.fromJson(json['image_properties'])
            : ImageProperties(pixelWidth: 0, pixelHeight: 0, dpi: 72, colorSpace: 'RGB'),
        imageUrl: json['image_url'],
        imageFileName: json['image_filename'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        comment: json['comment'],                   // ✅ NEW - nullable
      );
    }).toList();
  }

  // ✅ UPDATED - Update inventory item with new fields
  Future<void> updateInventoryItem(InventoryItem item) async {
    await supabase.from('inventory_items').update({
      'sku': item.sku,
      'name_en': item.nameEn,
      'name_ar': item.nameAr,
      'description_en': item.descriptionEn,        // ✅ NEW
      'description_ar': item.descriptionAr,        // ✅ NEW
      'category_id': item.categoryId,
      'subcategory': item.subcategory,
      'stock_quantity': item.stockQuantity,
      'unit_price': item.unitPrice,
      'min_stock_level': item.minStockLevel,
      'dimensions': item.dimensions.toJson(),
      'image_properties': item.imageProperties.toJson(),
      'image_url': item.imageUrl,
      'image_filename': item.imageFileName,
      'comment': item.comment,                      // ✅ NEW
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);
  }
}
*/
