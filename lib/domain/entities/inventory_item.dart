// domain/entities/inventory_item.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inventory_item.g.dart';

@JsonSerializable(explicitToJson: true) // ✅ ADD THIS for nested objects
class InventoryItem extends Equatable {
  final String id;
  final String sku;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;    // ✅ Already present - perfect!
  final String? descriptionAr;    // ✅ Already present - perfect!
  final String categoryId;
  final String subcategory;
  final int stockQuantity;
  final double? unitPrice;
  final int minStockLevel;
  final ProductDimensions dimensions;
  final ImageProperties imageProperties;
  final String? imageUrl;
  final String? imageFileName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? comment;          // ✅ Already present - perfect!

  const InventoryItem({
    required this.id,
    required this.sku,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
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
    this.comment,
  });

  // ✅ ADD JSON serialization methods
  factory InventoryItem.fromJson(Map<String, dynamic> json) => _$InventoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);

  // Your existing getters
  bool get isLowStock => stockQuantity <= minStockLevel;
  double get totalValue => (unitPrice ?? 0.0) * stockQuantity;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPrice => unitPrice != null && unitPrice! > 0;

  String get displayPrice => unitPrice != null
      ? '\$${unitPrice!.toStringAsFixed(2)}'
      : 'Price not set';

  // ✅ UPDATED - QR Code data with new fields
  Map<String, dynamic> get qrCodeData => {
    'id': id,
    'sku': sku,
    'name': nameEn,
    'nameAr': nameAr,
    'descriptionEn': descriptionEn ?? '',      // ✅ NEW
    'descriptionAr': descriptionAr ?? '',      // ✅ NEW
    'price': unitPrice?.toString() ?? '',
    'category': categoryId,
    'subcategory': subcategory,
    'stock': stockQuantity.toString(),
    'comment': comment ?? '',                  // ✅ NEW
    'imageUrl': imageUrl ?? '',
    'dimensions': dimensions.dimensionsText,
  };

  @override
  List<Object?> get props => [
    id, sku, nameEn, nameAr, descriptionEn, descriptionAr,
    categoryId, subcategory, stockQuantity, unitPrice,
    minStockLevel, dimensions, imageProperties, imageUrl,
    imageFileName, createdAt, updatedAt, comment,
  ];
}

@JsonSerializable()
class ProductDimensions extends Equatable {
  final double width;
  final double height;
  final String? otherSp;
  final String? unit;

  const ProductDimensions({
    required this.width,
    required this.height,
    this.otherSp,
    this.unit = 'mm',
  });

  double get volume => width * height;
  String get displayUnit => unit ?? 'units';
  bool get hasOtherSp => otherSp != null && otherSp!.trim().isNotEmpty; // ✅ NEW helper

  String get dimensionsText {
    String baseText = '${width}×${height}';

    if (hasOtherSp) {
      baseText += ' × ${otherSp!}';
    }

    baseText += ' $displayUnit';
    return baseText;
  }

  factory ProductDimensions.fromJson(Map<String, dynamic> json) =>
      _$ProductDimensionsFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDimensionsToJson(this);

  @override
  List<Object?> get props => [width, height, otherSp, unit];
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
