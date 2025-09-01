// domain/entities/inventory_item.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inventory_item.g.dart'; // Add this line

// Keep InventoryItem as a simple entity (no json_serializable)
class InventoryItem extends Equatable {
  final String id;
  final String sku;
  final String nameEn;
  final String nameAr;
  final String categoryId;
  final String subcategory;
  final int stockQuantity;
  final double? unitPrice;
  final int minStockLevel;
  final ProductDimensions dimensions;
  final ImageProperties imageProperties;
  final String? imageUrl; // New field for item image
  final String? imageFileName; // New field for image metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
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


  bool get isLowStock => stockQuantity <= minStockLevel;
  double get totalValue => (unitPrice ?? 0.0) * stockQuantity;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPrice => unitPrice != null && unitPrice! > 0;

  String get displayPrice => unitPrice != null
      ? '\$${unitPrice!.toStringAsFixed(2)}'
      : 'Price not set';


  Map<String, dynamic> get qrCodeData => {
    'id': id,
    'sku': sku,
    'name': nameEn,
    'nameAr': nameAr,
    'price': unitPrice?.toString() ?? '',
    'category': categoryId,
    'stock': stockQuantity.toString(),
  };

  @override
  List<Object?> get props => [
    id, sku, nameEn, nameAr, categoryId, subcategory,
    stockQuantity, unitPrice, minStockLevel, dimensions,
    imageProperties, imageUrl, imageFileName, createdAt, updatedAt,
  ];
}

@JsonSerializable()
class ProductDimensions extends Equatable {
  final double width;
  final double height;
  final double? depth;
  final String? unit;

  const ProductDimensions({
    required this.width,
    required this.height,
     this.depth,
     this.unit='mm',
  });
  double get volume => depth != null ? width * height * depth! : 0.0;
  String get displayUnit => unit ?? 'units';
  bool get hasDepth => depth != null && depth! > 0;

  String get dimensionsText {
    if (hasDepth) {
      return '${width}×${height}×${depth!} $displayUnit';
    } else {
      return '${width}×${height} $displayUnit';
    }
  }
  factory ProductDimensions.fromJson(Map<String, dynamic> json) =>
      _$ProductDimensionsFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDimensionsToJson(this);

  @override
  List<Object?> get props => [width, height, depth, unit];
}

@JsonSerializable()
class ImageProperties extends Equatable {
  @JsonKey(name: 'pixel_width')
  final int pixelWidth;

  @JsonKey(name: 'pixel_height')
  final int pixelHeight;

  final int dpi;

  @JsonKey(name: 'color_space')
  final String colorSpace;

  const ImageProperties({
    required this.pixelWidth,
    required this.pixelHeight,
    required this.dpi,
    required this.colorSpace,
  });

  factory ImageProperties.fromJson(Map<String, dynamic> json) =>
      _$ImagePropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$ImagePropertiesToJson(this);

  @override
  List<Object?> get props => [pixelWidth, pixelHeight, dpi, colorSpace];
}
