// data/models/inventory_item_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/inventory_item.dart';

part 'inventory_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class InventoryItemModel {
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

  const InventoryItemModel({
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
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$InventoryItemModelToJson(this);

  // ✅ UPDATED - Convert to domain entity (serial numbers loaded separately by repository)
  InventoryItem toEntity() {
    return InventoryItem(
      id: id,
      sku: sku,
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      categoryId: categoryId,
      subcategory: subcategory,
      stockQuantity: stockQuantity,
      unitPrice: unitPrice,
      minStockLevel: minStockLevel,
      dimensions: dimensions,
      imageProperties: imageProperties,
      imageUrl: imageUrl,
      imageFileName: imageFileName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      comment: comment,
      // ✅ NEW - Serial tracking fields
      isSerialTracked: isSerialTracked,
      serialNumberPrefix: serialNumberPrefix,
      serialNumberLength: serialNumberLength,
      serialFormat: serialFormat,
      serialNumbers: [], // Serial numbers are loaded separately by the repository
    );
  }

  // ✅ UPDATED - Create from domain entity
  factory InventoryItemModel.fromEntity(InventoryItem entity) {
    return InventoryItemModel(
      id: entity.id,
      sku: entity.sku,
      nameEn: entity.nameEn,
      nameAr: entity.nameAr,
      descriptionEn: entity.descriptionEn,
      descriptionAr: entity.descriptionAr,
      categoryId: entity.categoryId,
      subcategory: entity.subcategory,
      stockQuantity: entity.stockQuantity,
      unitPrice: entity.unitPrice,
      minStockLevel: entity.minStockLevel,
      dimensions: entity.dimensions,
      imageProperties: entity.imageProperties,
      imageUrl: entity.imageUrl,
      imageFileName: entity.imageFileName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      comment: entity.comment,
      // ✅ NEW - Serial tracking fields
      isSerialTracked: entity.isSerialTracked,
      serialNumberPrefix: entity.serialNumberPrefix,
      serialNumberLength: entity.serialNumberLength,
      serialFormat: entity.serialFormat,
      // Note: serialNumbers are not included in the model - they're managed separately
    );
  }

  // ✅ UPDATED - Convert from Supabase response with serial tracking support
  factory InventoryItemModel.fromSupabase(Map<String, dynamic> data) {
    return InventoryItemModel(
      id: data['id'],
      sku: data['sku'],
      nameEn: data['name_en'],
      nameAr: data['name_ar'] ?? '',
      descriptionEn: data['description_en'],
      descriptionAr: data['description_ar'],
      categoryId: data['category_id'],
      subcategory: data['subcategory'] ?? '',
      stockQuantity: data['stock_quantity'],
      unitPrice: data['unit_price']?.toDouble(),
      minStockLevel: data['min_stock_level'],
      imageUrl: data['image_url'],
      imageFileName: data['image_filename'],
      dimensions: _createDimensionsFromData(data['dimensions'] ?? {}),
      imageProperties: _createImagePropertiesFromData(data['image_properties'] ?? {}),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      comment: data['comment'],
      // ✅ NEW - Serial tracking fields from Supabase
      isSerialTracked: data['is_serial_tracked'] ?? false,
      serialNumberPrefix: data['serial_number_prefix'],
      serialNumberLength: data['serial_number_length'],
      serialFormat: _parseSerialFormat(data['serial_format']),
    );
  }

  // ✅ UPDATED - Convert to Supabase format with serial tracking fields
  Map<String, dynamic> toSupabase() {
    return {
      'sku': sku,
      'name_en': nameEn,
      'name_ar': nameAr,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'category_id': categoryId,
      'subcategory': subcategory,
      'stock_quantity': stockQuantity,
      'unit_price': unitPrice,
      'min_stock_level': minStockLevel,
      'dimensions': dimensions.toJson(),
      'image_properties': imageProperties.toJson(),
      'image_url': imageUrl,
      'image_filename': imageFileName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'comment': comment,
      // ✅ NEW - Serial tracking fields for Supabase
      'is_serial_tracked': isSerialTracked,
      'serial_number_prefix': serialNumberPrefix,
      'serial_number_length': serialNumberLength,
      'serial_format': serialFormat.name,
    };
  }

  // ✅ EXISTING - Helper methods (unchanged)
  static ProductDimensions _createDimensionsFromData(Map<String, dynamic> data) {
    return ProductDimensions(
      width: data['width'] != null ? (data['width'] as num).toDouble() : null,
      height: data['height'] != null ? (data['height'] as num).toDouble() : null,
      depth: data['depth']?.toString(),
      unit: data['unit'] as String?,
    );
  }

  static ImageProperties _createImagePropertiesFromData(Map<String, dynamic> data) {
    return ImageProperties(
      pixelWidth: data['pixel_width'] != null ? (data['pixel_width'] as num).toInt() : null,
      pixelHeight: data['pixel_height'] != null ? (data['pixel_height'] as num).toInt() : null,
      otherSp: data['other_sp']?.toString(),
      colorSpace: data['color_space'] as String? ?? 'RGB',
    );
  }

  // ✅ NEW - Helper method to parse serial format from database
  static SerialNumberFormat _parseSerialFormat(String? formatString) {
    if (formatString == null) return SerialNumberFormat.numeric;

    try {
      return SerialNumberFormat.values.firstWhere(
            (format) => format.name == formatString.toLowerCase(),
        orElse: () => SerialNumberFormat.numeric,
      );
    } catch (e) {
      print('⚠️ MODEL: Unknown serial format: $formatString, defaulting to numeric');
      return SerialNumberFormat.numeric;
    }
  }

  // ✅ NEW - Helper methods for serial tracking

  /// Check if this model represents a serial-tracked item
  bool get hasSerialTracking => isSerialTracked;

  /// Get the expected serial number format example
  String get serialFormatExample {
    final prefix = serialNumberPrefix ?? '';
    final length = serialNumberLength ?? 6;
    final numberLength = length - prefix.length;

    switch (serialFormat) {
      case SerialNumberFormat.numeric:
        return '$prefix${'001'.padLeft(numberLength.clamp(1, 10), '0')}';
      case SerialNumberFormat.alphanumeric:
        return '${prefix}ABC${'001'.padLeft((numberLength - 3).clamp(1, 7), '0')}';
      case SerialNumberFormat.custom:
        return '${prefix}CUSTOM';
    }
  }

  /// Validate a serial number format for this item
  bool isValidSerialFormat(String serialNumber) {
    if (!isSerialTracked) return true; // Non-tracked items don't need validation

    // Check prefix
    if (serialNumberPrefix != null && serialNumberPrefix!.isNotEmpty) {
      if (!serialNumber.startsWith(serialNumberPrefix!)) {
        return false;
      }
    }

    // Check length
    if (serialNumberLength != null) {
      if (serialNumber.length != serialNumberLength!) {
        return false;
      }
    }

    // Check format
    switch (serialFormat) {
      case SerialNumberFormat.numeric:
        final numberPart = serialNumberPrefix != null
            ? serialNumber.substring(serialNumberPrefix!.length)
            : serialNumber;
        return RegExp(r'^\d+$').hasMatch(numberPart);

      case SerialNumberFormat.alphanumeric:
        return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(serialNumber);

      case SerialNumberFormat.custom:
        return true; // Custom validation would be implemented here
    }
  }

  // ✅ NEW - Copy with method for model updates
  InventoryItemModel copyWith({
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
    // Serial tracking fields
    bool? isSerialTracked,
    String? serialNumberPrefix,
    int? serialNumberLength,
    SerialNumberFormat? serialFormat,
  }) {
    return InventoryItemModel(
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
    );
  }

  // ✅ NEW - Equality and hash code (for proper comparison)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItemModel &&
        other.id == id &&
        other.sku == sku &&
        other.nameEn == nameEn &&
        other.nameAr == nameAr &&
        other.descriptionEn == descriptionEn &&
        other.descriptionAr == descriptionAr &&
        other.categoryId == categoryId &&
        other.subcategory == subcategory &&
        other.stockQuantity == stockQuantity &&
        other.unitPrice == unitPrice &&
        other.minStockLevel == minStockLevel &&
        other.dimensions == dimensions &&
        other.imageProperties == imageProperties &&
        other.imageUrl == imageUrl &&
        other.imageFileName == imageFileName &&
        other.comment == comment &&
        // Serial tracking fields
        other.isSerialTracked == isSerialTracked &&
        other.serialNumberPrefix == serialNumberPrefix &&
        other.serialNumberLength == serialNumberLength &&
        other.serialFormat == serialFormat;
  }

  @override
  int get hashCode {
    return Object.hash(
      id, sku, nameEn, nameAr, descriptionEn, descriptionAr,
      categoryId, subcategory, stockQuantity, unitPrice, minStockLevel,
      dimensions, imageProperties, imageUrl, imageFileName, comment,
      // Serial tracking fields
      isSerialTracked, serialNumberPrefix, serialNumberLength, serialFormat,
    );
  }

  @override
  String toString() {
    return 'InventoryItemModel{'
        'id: $id, '
        'sku: $sku, '
        'nameEn: $nameEn, '
        'isSerialTracked: $isSerialTracked, '
        'serialFormat: ${serialFormat.name}'
        '}';
  }
}

// ✅ NEW - Extension for debugging and development
extension InventoryItemModelDebug on InventoryItemModel {
  /// Get detailed debug information
  Map<String, dynamic> get debugInfo {
    return {
      'basic_info': {
        'id': id,
        'sku': sku,
        'name_en': nameEn,
        'name_ar': nameAr,
        'category_id': categoryId,
        'stock_quantity': stockQuantity,
      },
      'serial_tracking': {
        'is_serial_tracked': isSerialTracked,
        'serial_prefix': serialNumberPrefix,
        'serial_length': serialNumberLength,
        'serial_format': serialFormat.name,
        'format_example': serialFormatExample,
      },
      'pricing': {
        'unit_price': unitPrice,
        'total_value': (unitPrice ?? 0.0) * stockQuantity,
        'has_price': unitPrice != null,
      },
      'dimensions': dimensions.toJson(),
      'image_properties': imageProperties.toJson(),
      'timestamps': {
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      },
    };
  }

  /// Validate model data integrity
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) errors.add('ID cannot be empty');
    if (sku.isEmpty) errors.add('SKU cannot be empty');
    if (nameEn.isEmpty) errors.add('English name cannot be empty');
    if (categoryId.isEmpty) errors.add('Category ID cannot be empty');
    if (stockQuantity < 0) errors.add('Stock quantity cannot be negative');
    if (minStockLevel < 0) errors.add('Min stock level cannot be negative');

    if (unitPrice != null && unitPrice! < 0) {
      errors.add('Unit price cannot be negative');
    }

    // Serial tracking validation
    if (isSerialTracked) {
      if (serialNumberLength != null && serialNumberLength! < 1) {
        errors.add('Serial number length must be at least 1');
      }

      if (serialNumberPrefix != null && serialNumberLength != null) {
        if (serialNumberPrefix!.length >= serialNumberLength!) {
          errors.add('Serial prefix length must be less than total length');
        }
      }
    }

    return errors;
  }
}
