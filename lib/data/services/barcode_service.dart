// data/services/barcode_service.dart
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import '../../domain/entities/inventory_item.dart';

class BarcodeService {

  /// Generate appropriate barcode data based on symbology type
  String generateBarcodeData(InventoryItem item, dynamic symbology) {
    switch (symbology.runtimeType) {
      case EAN13:
        return _generateEAN13(item.sku);
      case EAN8:
        return _generateEAN8(item.sku);
      case UPCA:
        return _generateUPCA(item.sku);
      case UPCE:
        return _generateUPCE(item.sku);
      case Code128:
        return item.sku; // Code128 can handle alphanumeric
      case Code39:
        return item.sku.toUpperCase(); // Code39 typically uppercase
      case Code93:
        return item.sku;
      case Codabar:
        return _generateCodabar(item.sku);
      case QRCode:
        return _generateQRData(item); // Full item data for QR
      case DataMatrix:
        return _generateDataMatrix(item);
      default:
        return item.sku;
    }
  }

  /// Get appropriate height for barcode display based on symbology type
  double getBarcodeHeight(dynamic symbology) {
    // 2D barcodes (square codes) need more height
    if (symbology is QRCode || symbology is DataMatrix) {
      return 180.0;
    }

    // 1D linear barcodes need less height
    return 80.0;
  }

  /// Generate EAN-13 format (13 digits)
  String _generateEAN13(String sku) {
    // Convert SKU to 12 digits, calculate check digit
    String baseNumber = sku.replaceAll(RegExp(r'[^0-9]'), '').padRight(12, '0');
    if (baseNumber.length > 12) {
      baseNumber = baseNumber.substring(0, 12);
    }

    int checkDigit = _calculateEAN13CheckDigit(baseNumber);
    return baseNumber + checkDigit.toString();
  }

  /// Generate EAN-8 format (8 digits)
  String _generateEAN8(String sku) {
    String baseNumber = sku.replaceAll(RegExp(r'[^0-9]'), '').padRight(7, '0');
    if (baseNumber.length > 7) {
      baseNumber = baseNumber.substring(0, 7);
    }

    int checkDigit = _calculateEAN8CheckDigit(baseNumber);
    return baseNumber + checkDigit.toString();
  }

  /// Generate UPC-A format (12 digits)
  String _generateUPCA(String sku) {
    String baseNumber = sku.replaceAll(RegExp(r'[^0-9]'), '').padRight(11, '0');
    if (baseNumber.length > 11) {
      baseNumber = baseNumber.substring(0, 11);
    }

    int checkDigit = _calculateUPCACheckDigit(baseNumber);
    return baseNumber + checkDigit.toString();
  }

  /// Generate UPC-E format (6-8 digits)
  String _generateUPCE(String sku) {
    String number = sku.replaceAll(RegExp(r'[^0-9]'), '').padRight(6, '0');
    if (number.length > 6) {
      number = number.substring(0, 6);
    }
    return '0' + number; // UPC-E typically starts with 0
  }

  /// Generate Codabar format
  String _generateCodabar(String sku) {
    // Codabar uses start/stop characters A, B, C, D
    String cleanSku = sku.replaceAll(RegExp(r'[^0-9\-\$\:\.\+\/]'), '');
    return 'A' + cleanSku + 'A';
  }

  /// Generate QR code data (comprehensive item info)
  String _generateQRData(InventoryItem item) {
    return '''
Item: ${item.nameEn}
SKU: ${item.sku}
Price: \$${item.unitPrice?.toStringAsFixed(2) ?? 'N/A'}
Stock: ${item.stockQuantity}
Category: ${item.categoryId}
Updated: ${item.updatedAt.toIso8601String()}
'''.trim();
  }

  /// Generate Data Matrix data
  String _generateDataMatrix(InventoryItem item) {
    return '${item.sku}|${item.nameEn}|${item.stockQuantity}';
  }

  // Check digit calculation methods
  int _calculateEAN13CheckDigit(String code) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(code[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    return (10 - (sum % 10)) % 10;
  }

  int _calculateEAN8CheckDigit(String code) {
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      int digit = int.parse(code[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    return (10 - (sum % 10)) % 10;
  }

  int _calculateUPCACheckDigit(String code) {
    int sum = 0;
    for (int i = 0; i < 11; i++) {
      int digit = int.parse(code[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    return (10 - (sum % 10)) % 10;
  }
}
