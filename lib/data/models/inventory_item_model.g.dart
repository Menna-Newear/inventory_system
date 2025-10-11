// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItemModel _$InventoryItemModelFromJson(Map<String, dynamic> json) =>
    InventoryItemModel(
      id: json['id'] as String,
      sku: json['sku'] as String,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      descriptionEn: json['description_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
      categoryId: json['category_id'] as String,
      subcategory: json['subcategory'] as String,
      stockQuantity: (json['stock_quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      minStockLevel: (json['min_stock_level'] as num).toInt(),
      dimensions: ProductDimensions.fromJson(
        json['dimensions'] as Map<String, dynamic>,
      ),
      imageProperties: ImageProperties.fromJson(
        json['image_properties'] as Map<String, dynamic>,
      ),
      imageUrl: json['image_url'] as String?,
      imageFileName: json['image_filename'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      comment: json['comment'] as String?,
      isSerialTracked: json['is_serial_tracked'] as bool? ?? false,
      serialNumberPrefix: json['serial_number_prefix'] as String?,
      serialNumberLength: (json['serial_number_length'] as num?)?.toInt(),
      serialFormat:
          $enumDecodeNullable(
            _$SerialNumberFormatEnumMap,
            json['serial_format'],
          ) ??
          SerialNumberFormat.numeric,
    );

Map<String, dynamic> _$InventoryItemModelToJson(InventoryItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'name_en': instance.nameEn,
      'name_ar': instance.nameAr,
      'description_en': instance.descriptionEn,
      'description_ar': instance.descriptionAr,
      'category_id': instance.categoryId,
      'subcategory': instance.subcategory,
      'stock_quantity': instance.stockQuantity,
      'unit_price': instance.unitPrice,
      'min_stock_level': instance.minStockLevel,
      'dimensions': instance.dimensions.toJson(),
      'image_properties': instance.imageProperties.toJson(),
      'image_url': instance.imageUrl,
      'image_filename': instance.imageFileName,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'comment': instance.comment,
      'is_serial_tracked': instance.isSerialTracked,
      'serial_number_prefix': instance.serialNumberPrefix,
      'serial_number_length': instance.serialNumberLength,
      'serial_format': _$SerialNumberFormatEnumMap[instance.serialFormat]!,
    };

const _$SerialNumberFormatEnumMap = {
  SerialNumberFormat.numeric: 'numeric',
  SerialNumberFormat.alphanumeric: 'alphanumeric',
  SerialNumberFormat.custom: 'custom',
};
