// data/models/inventory_item_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_item.dart';

part 'inventory_item_model.g.dart';

@JsonSerializable()
class InventoryItemModel {
  final String id;
  final String sku;
  @JsonKey(name: 'name_en')
  final String nameEn;
  @JsonKey(name: 'name_ar')
  final String nameAr;
  @JsonKey(name: 'category_id')
  final String categoryId;
  final String subcategory;
  @JsonKey(name: 'stock_quantity')
  final int stockQuantity;
  @JsonKey(name: 'unit_price')
  final double? unitPrice;
  @JsonKey(name: 'min_stock_level')
  final int minStockLevel;
  final ProductDimensions dimensions;
  @JsonKey(name: 'image_properties')
  final ImageProperties imageProperties;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'image_file_name')
  final String? imageFileName;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const InventoryItemModel({
    required this.id,
    required this.sku,
    required this.nameEn,
    required this.nameAr,
    required this.categoryId,
    required this.subcategory,
    required this.stockQuantity,
    this.unitPrice,
    required this.minStockLevel,
    required this.dimensions,
    required this.imageProperties,
    this.imageUrl,
    this.imageFileName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemModelToJson(this);

  // Convert to domain entity
  InventoryItem toEntity() {
    return InventoryItem(
      id: id,
      sku: sku,
      nameEn: nameEn,
      nameAr: nameAr,
      categoryId: categoryId,
      subcategory: subcategory,
      stockQuantity: stockQuantity,
      unitPrice: unitPrice,
      minStockLevel: minStockLevel,
      dimensions: dimensions,
      imageProperties: imageProperties,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Create from domain entity
  factory InventoryItemModel.fromEntity(InventoryItem entity) {
    return InventoryItemModel(
      id: entity.id,
      sku: entity.sku,
      nameEn: entity.nameEn,
      nameAr: entity.nameAr,
      categoryId: entity.categoryId,
      subcategory: entity.subcategory,
      stockQuantity: entity.stockQuantity,
      unitPrice: entity.unitPrice,
      minStockLevel: entity.minStockLevel,
      dimensions: entity.dimensions,
      imageProperties: entity.imageProperties,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Convert from Supabase response
  factory InventoryItemModel.fromSupabase(Map<String, dynamic> data) {
    return InventoryItemModel(
      id: data['id'],
      sku: data['sku'],
      nameEn: data['name_en'],
      nameAr: data['name_ar'] ?? '',
      categoryId: data['category_id'],
      subcategory: data['subcategory'] ?? '',
      stockQuantity: data['stock_quantity'],
      unitPrice: data['unit_price'].toDouble(),
      minStockLevel: data['min_stock_level'],
      dimensions: ProductDimensions.fromJson(data['dimensions'] ?? {}),
      imageProperties: ImageProperties.fromJson(data['image_properties'] ?? {}),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'sku': sku,
      'name_en': nameEn,
      'name_ar': nameAr,
      'category_id': categoryId,
      'subcategory': subcategory,
      'stock_quantity': stockQuantity,
      'unit_price': unitPrice,
      'min_stock_level': minStockLevel,
      'dimensions': dimensions.toJson(),
      'image_properties': imageProperties.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
