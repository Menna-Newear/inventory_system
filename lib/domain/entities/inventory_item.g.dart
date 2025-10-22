// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    InventoryItem(
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
      serialNumbers:
          (json['serial_numbers'] as List<dynamic>?)
              ?.map((e) => SerialNumber.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$InventoryItemToJson(InventoryItem instance) =>
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
      'serial_numbers': instance.serialNumbers.map((e) => e.toJson()).toList(),
    };

const _$SerialNumberFormatEnumMap = {
  SerialNumberFormat.numeric: 'numeric',
  SerialNumberFormat.alphanumeric: 'alphanumeric',
  SerialNumberFormat.custom: 'custom',
};

SerialNumber _$SerialNumberFromJson(Map<String, dynamic> json) => SerialNumber(
  id: json['id'] as String,
  itemId: json['item_id'] as String,
  serialNumber: json['serial_number'] as String,
  status: $enumDecode(_$SerialStatusEnumMap, json['status']),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SerialNumberToJson(SerialNumber instance) =>
    <String, dynamic>{
      'id': instance.id,
      'item_id': instance.itemId,
      'serial_number': instance.serialNumber,
      'status': _$SerialStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$SerialStatusEnumMap = {
  SerialStatus.available: 'available',
  SerialStatus.reserved: 'reserved',
  SerialStatus.sold: 'sold',
  SerialStatus.rented: 'rented',
  SerialStatus.damaged: 'damaged',
  SerialStatus.returned: 'returned',
  SerialStatus.recalled: 'recalled',
};

ProductDimensions _$ProductDimensionsFromJson(Map<String, dynamic> json) =>
    ProductDimensions(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      depth: json['depth'] as String?,
      unit: json['unit'] as String? ?? 'mm',
    );

Map<String, dynamic> _$ProductDimensionsToJson(ProductDimensions instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'depth': instance.depth,
      'unit': instance.unit,
    };

ImageProperties _$ImagePropertiesFromJson(Map<String, dynamic> json) =>
    ImageProperties(
      pixelWidth: (json['pixel_width'] as num?)?.toInt(),
      pixelHeight: (json['pixel_height'] as num?)?.toInt(),
      otherSp: json['other_sp'] as String?,
      colorSpace: json['color_space'] as String,
    );

Map<String, dynamic> _$ImagePropertiesToJson(ImageProperties instance) =>
    <String, dynamic>{
      'pixel_width': instance.pixelWidth,
      'pixel_height': instance.pixelHeight,
      'other_sp': instance.otherSp,
      'color_space': instance.colorSpace,
    };
