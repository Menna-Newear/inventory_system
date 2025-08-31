// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDimensions _$ProductDimensionsFromJson(Map<String, dynamic> json) =>
    ProductDimensions(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      unit: json['unit'] as String,
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
