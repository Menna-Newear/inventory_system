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
  final String? descriptionEn; // ✅ Already present - perfect!
  final String? descriptionAr; // ✅ Already present - perfect!
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
  final String? comment; // ✅ Already present - perfect!

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
  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);

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
    'descriptionEn': descriptionEn ?? '', // ✅ NEW
    'descriptionAr': descriptionAr ?? '', // ✅ NEW
    'price': unitPrice?.toString() ?? '',
    'category': categoryId,
    'subcategory': subcategory,
    'stock': stockQuantity.toString(),
    'comment': comment ?? '', // ✅ NEW
    'imageUrl': imageUrl ?? '',
    'dimensions': dimensions.dimensionsText,
  };

  @override
  List<Object?> get props => [
    id,
    sku,
    nameEn,
    nameAr,
    descriptionEn,
    descriptionAr,
    categoryId,
    subcategory,
    stockQuantity,
    unitPrice,
    minStockLevel,
    dimensions,
    imageProperties,
    imageUrl,
    imageFileName,
    createdAt,
    updatedAt,
    comment,
  ];
}

@JsonSerializable()
class ProductDimensions extends Equatable {
  final double? width;
  final double? height;
  final String? depth;
  final String? unit;

  const ProductDimensions({
     this.width,
     this.height,
    this.depth,
    this.unit = 'mm',
  });


  // ✅ UPDATED - Volume calculation with null safety
  double get volume {
    if (width == null || height == null) {
      return 0.0; // Can't calculate without both width and height
    }

    if (depth != null && depth!.trim().isNotEmpty) {
      try {
        final depthValue = double.tryParse(depth!);
        if (depthValue != null) {
          return width! * height! * depthValue;
        }
      } catch (_) {
        // If depth is not a number, return area only
      }
    }
    return width! * height!; // Return area
  }
  String get displayUnit => unit ?? 'units';
  bool get hasWidth => width != null;
  bool get hasHeight => height != null;
  bool get hasDimensions => width != null && height != null;
  bool get hasDepth => depth != null && depth!.trim().isNotEmpty;

  String get dimensionsText {
    if (!hasDimensions) {
      return 'No dimensions set';
    }

    String baseText = '${width}×${height}';

    if (hasDepth) {
      baseText += ' × ${depth!}';
    }

    baseText += ' $displayUnit';
    return baseText;
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
  final int? pixelWidth;

  @JsonKey(name: 'pixel_height')
  final int? pixelHeight;
  @JsonKey(name: 'other_sp')
  final String? otherSp;

  @JsonKey(name: 'color_space')
  final String colorSpace;

  const ImageProperties({
     this.pixelWidth,
     this.pixelHeight,
    this.otherSp,
    required this.colorSpace,
  });
  bool get hasPixelWidth => pixelWidth != null;
  bool get hasPixelHeight => pixelHeight != null;
  bool get hasPixelDimensions => pixelWidth != null && pixelHeight != null;
  bool get hasOtherSp => otherSp != null && otherSp!.trim().isNotEmpty;

  String get imagePropertiesText {
    final parts = <String>[];

    if (hasPixelDimensions) {
      parts.add('${pixelWidth}×${pixelHeight} pixels');
    }

    if (hasOtherSp) {
      parts.add(otherSp!);
    }

    parts.add(colorSpace);

    return parts.isEmpty ? 'No image properties' : parts.join(' • ');
  }
  factory ImageProperties.fromJson(Map<String, dynamic> json) =>
      _$ImagePropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$ImagePropertiesToJson(this);

  @override
  List<Object?> get props => [pixelWidth, pixelHeight, otherSp, colorSpace];
}
