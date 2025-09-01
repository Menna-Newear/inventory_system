// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) =>
    InventoryItem(
      id: json['id'] as String,
      sku: json['sku'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      descriptionEn: json['descriptionEn'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      categoryId: json['categoryId'] as String,
      subcategory: json['subcategory'] as String,
      stockQuantity: (json['stockQuantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      minStockLevel: (json['minStockLevel'] as num).toInt(),
      dimensions: ProductDimensions.fromJson(
        json['dimensions'] as Map<String, dynamic>,
      ),
      imageProperties: ImageProperties.fromJson(
        json['imageProperties'] as Map<String, dynamic>,
      ),
      imageUrl: json['imageUrl'] as String?,
      imageFileName: json['imageFileName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$InventoryItemToJson(InventoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'nameEn': instance.nameEn,
      'nameAr': instance.nameAr,
      'descriptionEn': instance.descriptionEn,
      'descriptionAr': instance.descriptionAr,
      'categoryId': instance.categoryId,
      'subcategory': instance.subcategory,
      'stockQuantity': instance.stockQuantity,
      'unitPrice': instance.unitPrice,
      'minStockLevel': instance.minStockLevel,
      'dimensions': instance.dimensions.toJson(),
      'imageProperties': instance.imageProperties.toJson(),
      'imageUrl': instance.imageUrl,
      'imageFileName': instance.imageFileName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'comment': instance.comment,
    };

ProductDimensions _$ProductDimensionsFromJson(Map<String, dynamic> json) =>
    ProductDimensions(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      otherSp: json['otherSp'] as String?,
      unit: json['unit'] as String? ?? 'mm',
    );

Map<String, dynamic> _$ProductDimensionsToJson(ProductDimensions instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'otherSp': instance.otherSp,
      'unit': instance.unit,
    };

ImageProperties _$ImagePropertiesFromJson(Map<String, dynamic> json) =>
    ImageProperties(
      pixelWidth: (json['pixel_width'] as num).toInt(),
      pixelHeight: (json['pixel_height'] as num).toInt(),
      dpi: (json['dpi'] as num).toInt(),
      colorSpace: json['color_space'] as String,
    );

Map<String, dynamic> _$ImagePropertiesToJson(ImageProperties instance) =>
    <String, dynamic>{
      'pixel_width': instance.pixelWidth,
      'pixel_height': instance.pixelHeight,
      'dpi': instance.dpi,
      'color_space': instance.colorSpace,
    };
