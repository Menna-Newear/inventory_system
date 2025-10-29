// ✅ domain/entities/inventory_item.dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inventory_item.g.dart';

@JsonSerializable(explicitToJson: true)
class InventoryItem extends Equatable {
  final String id;
  final String sku;
  @JsonKey(name: 'name_en')
  final String nameEn;
  @JsonKey(name: 'name_ar')
  final String nameAr;
  @JsonKey(name: 'description_en')
  final String? descriptionEn;
  @JsonKey(name: 'description_ar')
  final String? descriptionAr;
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
  @JsonKey(name: 'image_filename')
  final String? imageFileName;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final String? comment;

  @JsonKey(name: 'is_serial_tracked', defaultValue: false)
  final bool isSerialTracked;
  @JsonKey(name: 'serial_number_prefix')
  final String? serialNumberPrefix;
  @JsonKey(name: 'serial_number_length')
  final int? serialNumberLength;
  @JsonKey(name: 'serial_format', defaultValue: SerialNumberFormat.numeric)
  final SerialNumberFormat serialFormat;
  @JsonKey(name: 'serial_numbers', defaultValue: [])
  final List<SerialNumber> serialNumbers;

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
    this.isSerialTracked = false,
    this.serialNumberPrefix,
    this.serialNumberLength,
    this.serialFormat = SerialNumberFormat.numeric,
    this.serialNumbers = const [],
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);

  // ✅ ORIGINAL GETTERS
  bool get isLowStock => stockQuantity <= minStockLevel;
  double get totalValue => (unitPrice ?? 0.0) * stockQuantity;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPrice => unitPrice != null && unitPrice! > 0;

  String get displayPrice => unitPrice != null
      ? '\$${unitPrice!.toStringAsFixed(2)}'
      : 'Price not set';

  // ✅ FIXED: Smart availableStock - handles when serials aren't loaded
  int get availableStock {
    if (!isSerialTracked) {
      return stockQuantity;
    }

    // ✅ If serials aren't loaded (empty list), return stockQuantity as fallback
    if (serialNumbers.isEmpty) {
      return stockQuantity;
    }

    // If serials are loaded, count available ones
    return serialNumbers
        .where((s) => s.status == SerialStatus.available)
        .length;
  }

  // ✅ FIXED: Other stock properties with null safety
  int get reservedStock {
    if (!isSerialTracked || serialNumbers.isEmpty) return 0;
    return serialNumbers
        .where((s) => s.status == SerialStatus.reserved)
        .length;
  }

  int get soldStock {
    if (!isSerialTracked || serialNumbers.isEmpty) return 0;
    return serialNumbers
        .where((s) => s.status == SerialStatus.sold)
        .length;
  }

  int get damagedStock {
    if (!isSerialTracked || serialNumbers.isEmpty) return 0;
    return serialNumbers
        .where((s) => s.status == SerialStatus.damaged)
        .length;
  }

  int get totalSerialCount => serialNumbers.length;

  // ✅ FIXED: Smart effectiveStockQuantity
  int get effectiveStockQuantity {
    if (isSerialTracked) {
      // If serials aren't loaded, use stockQuantity
      if (serialNumbers.isEmpty) {
        return stockQuantity;
      }
      return availableStock;
    }
    return stockQuantity;
  }

  // ✅ FIXED: Smart needsRestock - handles when serials aren't loaded
  bool get needsRestock {
    if (isSerialTracked) {
      // If serials aren't loaded (empty list), use stockQuantity as fallback
      if (serialNumbers.isEmpty) {
        return stockQuantity <= minStockLevel;
      }
      // If serials are loaded, check availableStock
      return availableStock <= minStockLevel;
    }
    // For non-serial items, always use stockQuantity
    return stockQuantity <= minStockLevel;
  }

  // ✅ Generate barcode data with optional serial number
  String getBarcodeData({String? serialNumber}) {
    if (serialNumber != null && isSerialTracked) {
      return '$sku-$serialNumber';
    }
    return sku;
  }

  // ✅ Generate next serial number
  String generateNextSerialNumber() {
    if (!isSerialTracked) {
      throw Exception('Item is not serial tracked');
    }

    String prefix = serialNumberPrefix ?? '';
    int length = serialNumberLength ?? 6;

    int maxNumber = 0;
    for (final serial in serialNumbers) {
      String numberPart = serial.serialNumber;

      if (prefix.isNotEmpty && numberPart.startsWith(prefix)) {
        numberPart = numberPart.substring(prefix.length);
      }

      int currentNumber = 0;
      switch (serialFormat) {
        case SerialNumberFormat.numeric:
          currentNumber = int.tryParse(numberPart) ?? 0;
          break;
        case SerialNumberFormat.alphanumeric:
          final match = RegExp(r'\d+').firstMatch(numberPart);
          if (match != null) {
            currentNumber = int.tryParse(match.group(0)!) ?? 0;
          }
          break;
        case SerialNumberFormat.custom:
          final match = RegExp(r'\d+').firstMatch(numberPart);
          if (match != null) {
            currentNumber = int.tryParse(match.group(0)!) ?? 0;
          }
          break;
      }

      if (currentNumber > maxNumber) {
        maxNumber = currentNumber;
      }
    }

    int nextNumber = maxNumber + 1;

    String formattedNumber;
    switch (serialFormat) {
      case SerialNumberFormat.numeric:
        formattedNumber = nextNumber.toString().padLeft(length - prefix.length, '0');
        break;
      case SerialNumberFormat.alphanumeric:
        formattedNumber = nextNumber.toString().padLeft(length - prefix.length, '0');
        break;
      case SerialNumberFormat.custom:
        formattedNumber = nextNumber.toString().padLeft(length - prefix.length, '0');
        break;
    }

    return '$prefix$formattedNumber';
  }

  // ✅ Get available serial numbers
  List<SerialNumber> getAvailableSerials() {
    return serialNumbers.where((s) => s.status == SerialStatus.available).toList();
  }

  // ✅ Get serial numbers by status
  List<SerialNumber> getSerialsByStatus(SerialStatus status) {
    return serialNumbers.where((s) => s.status == status).toList();
  }

  // ✅ Enhanced QR Code data
  Map<String, dynamic> get qrCodeData => {
    'id': id,
    'sku': sku,
    'name': nameEn,
    'nameAr': nameAr,
    'descriptionEn': descriptionEn ?? '',
    'descriptionAr': descriptionAr ?? '',
    'price': unitPrice?.toString() ?? '',
    'category': categoryId,
    'subcategory': subcategory,
    'stock': effectiveStockQuantity.toString(),
    'comment': comment ?? '',
    'imageUrl': imageUrl ?? '',
    'dimensions': dimensions.dimensionsText,
    'isSerialTracked': isSerialTracked.toString(),
    'serialPrefix': serialNumberPrefix ?? '',
    'availableSerials': availableStock.toString(),
    'totalSerials': totalSerialCount.toString(),
  };

  // ✅ Copy with method
  InventoryItem copyWith({
    String? id,
    String? sku,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? categoryId,
    String? subcategory,
    int? stockQuantity,
    double? unitPrice,
    int? minStockLevel,
    ProductDimensions? dimensions,
    ImageProperties? imageProperties,
    String? imageUrl,
    String? imageFileName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? comment,
    bool? isSerialTracked,
    String? serialNumberPrefix,
    int? serialNumberLength,
    SerialNumberFormat? serialFormat,
    List<SerialNumber>? serialNumbers,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      dimensions: dimensions ?? this.dimensions,
      imageProperties: imageProperties ?? this.imageProperties,
      imageUrl: imageUrl ?? this.imageUrl,
      imageFileName: imageFileName ?? this.imageFileName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comment: comment ?? this.comment,
      isSerialTracked: isSerialTracked ?? this.isSerialTracked,
      serialNumberPrefix: serialNumberPrefix ?? this.serialNumberPrefix,
      serialNumberLength: serialNumberLength ?? this.serialNumberLength,
      serialFormat: serialFormat ?? this.serialFormat,
      serialNumbers: serialNumbers ?? this.serialNumbers,
    );
  }

  @override
  List<Object?> get props => [
    id, sku, nameEn, nameAr, descriptionEn, descriptionAr,
    categoryId, subcategory, stockQuantity, unitPrice, minStockLevel,
    dimensions, imageProperties, imageUrl, imageFileName, createdAt, updatedAt, comment,
    isSerialTracked, serialNumberPrefix, serialNumberLength, serialFormat, serialNumbers,
  ];

  @override
  String toString() {
    return 'InventoryItem{id: $id, sku: $sku, nameEn: $nameEn, '
        'stockQuantity: $stockQuantity, isSerialTracked: $isSerialTracked, '
        'serialCount: ${serialNumbers.length}}';
  }
}

@JsonSerializable()
class SerialNumber extends Equatable {
  final String id;
  @JsonKey(name: 'item_id')
  final String itemId;
  @JsonKey(name: 'serial_number')
  final String serialNumber;
  final SerialStatus status;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const SerialNumber({
    required this.id,
    required this.itemId,
    required this.serialNumber,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String getBarcodeData(String sku) => '$sku-$serialNumber';
  bool get isAvailable => status == SerialStatus.available;

  SerialNumber copyWith({
    String? id,
    String? itemId,
    String? serialNumber,
    SerialStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SerialNumber(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      serialNumber: serialNumber ?? this.serialNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SerialNumber.fromJson(Map<String, dynamic> json) =>
      _$SerialNumberFromJson(json);

  Map<String, dynamic> toJson() => _$SerialNumberToJson(this);

  @override
  List<Object?> get props => [id, itemId, serialNumber, status, notes, createdAt, updatedAt];

  @override
  String toString() => 'SerialNumber{serialNumber: $serialNumber, status: ${status.name}}';
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

  double get volume {
    if (width == null || height == null) {
      return 0.0;
    }

    if (depth != null && depth!.trim().isNotEmpty) {
      try {
        final depthValue = double.tryParse(depth!);
        if (depthValue != null) {
          return width! * height! * depthValue;
        }
      } catch (_) {}
    }
    return width! * height!;
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

@JsonEnum()
enum SerialNumberFormat {
  @JsonValue('numeric')
  numeric,
  @JsonValue('alphanumeric')
  alphanumeric,
  @JsonValue('custom')
  custom,
}

@JsonEnum()
enum SerialStatus {
  @JsonValue('available')
  available,
  @JsonValue('reserved')
  reserved,
  @JsonValue('sold')
  sold,
  @JsonValue('rented')
  rented,
  @JsonValue('damaged')
  damaged,
  @JsonValue('returned')
  returned,
  @JsonValue('recalled')
  recalled,
}

extension SerialStatusExtension on SerialStatus {
  String get displayName {
    switch (this) {
      case SerialStatus.available:
        return 'Available';
      case SerialStatus.reserved:
        return 'Reserved';
      case SerialStatus.sold:
        return 'Sold';
      case SerialStatus.rented:
        return 'Rented';
      case SerialStatus.damaged:
        return 'Damaged';
      case SerialStatus.returned:
        return 'Returned';
      case SerialStatus.recalled:
        return 'Recalled';
    }
  }

  bool get isActive => this == SerialStatus.available || this == SerialStatus.reserved;
  bool get isInactive => !isActive;
}

extension SerialNumberFormatExtension on SerialNumberFormat {
  String get displayName {
    switch (this) {
      case SerialNumberFormat.numeric:
        return 'Numeric (123456)';
      case SerialNumberFormat.alphanumeric:
        return 'Alphanumeric (ABC123)';
      case SerialNumberFormat.custom:
        return 'Custom Format';
    }
  }

  String get example {
    switch (this) {
      case SerialNumberFormat.numeric:
        return '001234';
      case SerialNumberFormat.alphanumeric:
        return 'ABC123';
      case SerialNumberFormat.custom:
        return 'Custom';
    }
  }
}
