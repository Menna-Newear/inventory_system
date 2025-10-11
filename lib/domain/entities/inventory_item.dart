// domain/entities/inventory_item.dart
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

  // ✅ NEW - Serial Number Tracking Fields
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
    // ✅ NEW - Serial tracking fields with defaults
    this.isSerialTracked = false,
    this.serialNumberPrefix,
    this.serialNumberLength,
    this.serialFormat = SerialNumberFormat.numeric,
    this.serialNumbers = const [],
  });

  // ✅ JSON serialization methods
  factory InventoryItem.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemToJson(this);

  // ✅ EXISTING - Your original getters
  bool get isLowStock => stockQuantity <= minStockLevel;
  double get totalValue => (unitPrice ?? 0.0) * stockQuantity;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPrice => unitPrice != null && unitPrice! > 0;

  String get displayPrice => unitPrice != null
      ? '\$${unitPrice!.toStringAsFixed(2)}'
      : 'Price not set';

  // ✅ NEW - Serial number calculated properties
  int get availableStock => serialNumbers.where((s) => s.status == SerialStatus.available).length;
  int get reservedStock => serialNumbers.where((s) => s.status == SerialStatus.reserved).length;
  int get soldStock => serialNumbers.where((s) => s.status == SerialStatus.sold).length;
  int get damagedStock => serialNumbers.where((s) => s.status == SerialStatus.damaged).length;
  int get totalSerialCount => serialNumbers.length;

  // ✅ NEW - Get effective stock quantity
  int get effectiveStockQuantity {
    if (isSerialTracked) {
      return availableStock; // For serialized items, use available serial count
    }
    return stockQuantity; // For regular items, use stock quantity
  }

  // ✅ NEW - Enhanced low stock check for serial tracked items
  bool get needsRestock {
    if (isSerialTracked) {
      return availableStock <= minStockLevel;
    }
    return stockQuantity <= minStockLevel;
  }

  // ✅ NEW - Generate barcode data with optional serial number
  String getBarcodeData({String? serialNumber}) {
    if (serialNumber != null && isSerialTracked) {
      return '$sku-$serialNumber'; // Combined format: SKU-SERIAL
    }
    return sku; // Standard SKU-only barcode
  }

  // ✅ NEW - Generate next serial number
  String generateNextSerialNumber() {
    if (!isSerialTracked) {
      throw Exception('Item is not serial tracked');
    }

    String prefix = serialNumberPrefix ?? '';
    int length = serialNumberLength ?? 6;

    // Find the highest existing serial number
    int maxNumber = 0;
    for (final serial in serialNumbers) {
      String numberPart = serial.serialNumber;

      // Remove prefix if it exists
      if (prefix.isNotEmpty && numberPart.startsWith(prefix)) {
        numberPart = numberPart.substring(prefix.length);
      }

      // Extract numeric part based on format
      int currentNumber = 0;
      switch (serialFormat) {
        case SerialNumberFormat.numeric:
          currentNumber = int.tryParse(numberPart) ?? 0;
          break;
        case SerialNumberFormat.alphanumeric:
        // Extract numeric part from alphanumeric (simple approach)
          final match = RegExp(r'\d+').firstMatch(numberPart);
          if (match != null) {
            currentNumber = int.tryParse(match.group(0)!) ?? 0;
          }
          break;
        case SerialNumberFormat.custom:
        // Custom format - try to extract number
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

    // Generate next number
    int nextNumber = maxNumber + 1;

    // Format according to serial format
    String formattedNumber;
    switch (serialFormat) {
      case SerialNumberFormat.numeric:
        formattedNumber = nextNumber.toString().padLeft(length - prefix.length, '0');
        break;
      case SerialNumberFormat.alphanumeric:
      // Simple alphanumeric: prefix + padded number
        formattedNumber = nextNumber.toString().padLeft(length - prefix.length, '0');
        break;
      case SerialNumberFormat.custom:
      // Custom format - default to numeric for now
        formattedNumber = nextNumber.toString().padLeft(length - prefix.length, '0');
        break;
    }

    return '$prefix$formattedNumber';
  }

  // ✅ NEW - Get available serial numbers
  List<SerialNumber> getAvailableSerials() {
    return serialNumbers.where((s) => s.status == SerialStatus.available).toList();
  }

  // ✅ NEW - Get serial numbers by status
  List<SerialNumber> getSerialsByStatus(SerialStatus status) {
    return serialNumbers.where((s) => s.status == status).toList();
  }

  // ✅ UPDATED - Enhanced QR Code data with new fields and serial support
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
    'stock': effectiveStockQuantity.toString(), // ✅ Uses effective stock
    'comment': comment ?? '',
    'imageUrl': imageUrl ?? '',
    'dimensions': dimensions.dimensionsText,
    // ✅ NEW - Serial tracking info in QR code
    'isSerialTracked': isSerialTracked.toString(),
    'serialPrefix': serialNumberPrefix ?? '',
    'availableSerials': availableStock.toString(),
    'totalSerials': totalSerialCount.toString(),
  };

  // ✅ ENHANCED - Copy with method including serial fields
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
    // ✅ NEW - Serial tracking fields
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
      // Serial tracking fields
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
    // ✅ NEW - Include serial fields in equality check
    isSerialTracked, serialNumberPrefix, serialNumberLength, serialFormat, serialNumbers,
  ];

  @override
  String toString() {
    return 'InventoryItem{id: $id, sku: $sku, nameEn: $nameEn, '
        'stockQuantity: $stockQuantity, isSerialTracked: $isSerialTracked, '
        'serialCount: ${serialNumbers.length}}';
  }
}

// ✅ NEW - SerialNumber Entity
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

  // Generate barcode data combining SKU and serial
  String getBarcodeData(String sku) => '$sku-$serialNumber';

  // Check if serial is available for sale
  bool get isAvailable => status == SerialStatus.available;

  // Copy with method
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

  // ✅ Volume calculation with null safety
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

// ✅ NEW - Enums for Serial Number Management
@JsonEnum()
enum SerialNumberFormat {
  @JsonValue('numeric')
  numeric,        // Pure numbers: 001234, 567890
  @JsonValue('alphanumeric')
  alphanumeric,   // Letters + numbers: ABC123, XYZ789
  @JsonValue('custom')
  custom,         // Custom pattern defined by user
}

@JsonEnum()
enum SerialStatus {
  @JsonValue('available')
  available,      // Available for sale/use
  @JsonValue('reserved')
  reserved,       // Reserved for specific order/customer
  @JsonValue('sold')
  sold,          // Sold to customer
  @JsonValue('damaged')
  damaged,       // Damaged/defective - cannot be sold
  @JsonValue('returned')
  returned,      // Returned by customer
  @JsonValue('recalled')
  recalled,      // Subject to product recall
}

// ✅ EXTENSION - Helper methods for SerialStatus
extension SerialStatusExtension on SerialStatus {
  String get displayName {
    switch (this) {
      case SerialStatus.available:
        return 'Available';
      case SerialStatus.reserved:
        return 'Reserved';
      case SerialStatus.sold:
        return 'Sold';
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

// ✅ EXTENSION - Helper methods for SerialNumberFormat
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
