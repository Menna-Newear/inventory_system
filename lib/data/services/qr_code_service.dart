// data/services/enhanced_qr_code_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../domain/entities/inventory_item.dart';

class EnhancedQrCodeService {
  // Generate QR code data for inventory item
  String generateQrData(InventoryItem item) {
    final qrData = {
      'type': 'inventory_item',
      'id': item.id,
      'sku': item.sku,
      'name': item.nameEn,
      'nameAr': item.nameAr,
      'price': item.unitPrice?.toString() ?? '0',
      'category': item.categoryId,
      'stock': item.stockQuantity.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    return jsonEncode(qrData);
  }

  // Generate beautiful rounded QR code
  Widget generateRoundedQrCode(
      InventoryItem item, {
        double size = 200.0,
        Color foregroundColor = Colors.black,
        Color backgroundColor = Colors.white,
      }) {
    return PrettyQrView.data(
      data: generateQrData(item),
      decoration: PrettyQrDecoration(
        shape: PrettyQrSmoothSymbol(
          color: foregroundColor,
        ),
        background: backgroundColor,
      ),
    );
  }

  // Generate QR code with custom shapes
  Widget generateCustomShapeQrCode(
      InventoryItem item, {
        double size = 200.0,
        Color foregroundColor = Colors.black,
        Color backgroundColor = Colors.white,
        QrCodeShape shape = QrCodeShape.rounded,
      }) {
    PrettyQrDecoration decoration;

    switch (shape) {
      case QrCodeShape.rounded:
        decoration = PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(color: foregroundColor),
          background: backgroundColor,
        );
        break;
      case QrCodeShape.circles:
        decoration = PrettyQrDecoration(
          shape: PrettyQrRoundedSymbol(color: foregroundColor),
          background: backgroundColor,
        );
        break;
      case QrCodeShape.squares:
        decoration =PrettyQrDecoration(
          shape: PrettyQrSquaresSymbol(color: foregroundColor),
          background: backgroundColor,
        );
        break;
      case QrCodeShape.mixed:
        decoration = PrettyQrDecoration(
          shape: PrettyQrCustomShape(
            PrettyQrSquaresSymbol(color: foregroundColor),
            finderPattern: PrettyQrSmoothSymbol(color: foregroundColor),
            alignmentPatterns: PrettyQrDotsSymbol(color: foregroundColor),
          ),
          background: backgroundColor,
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      child: PrettyQrView.data(
        data: generateQrData(item),
        decoration: decoration,
      ),
    );
  }

  // Generate gradient QR code
  Widget generateGradientQrCode(
      InventoryItem item, {
        double size = 200.0,
        List<Color> gradientColors = const [Colors.blue, Colors.purple],
        Color backgroundColor = Colors.white,
      }) {
    return Container(
      width: size,
      height: size,
      child: PrettyQrView.data(
        data: generateQrData(item),
        decoration: PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(
            color: gradientColors.first,
          ),
          background: backgroundColor,
        ),
      ),
    );
  }

  // Generate QR code with logo/image in center
  Widget generateQrCodeWithLogo(
      InventoryItem item, {
        double size = 200.0,
        Widget? centerImage,
        Color foregroundColor = Colors.black,
        Color backgroundColor = Colors.white,
      }) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PrettyQrView.data(
            data: generateQrData(item),
            decoration: PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(color: foregroundColor),
              background: backgroundColor,
            ),
          ),
          if (centerImage != null) ...[
            Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: centerImage,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Generate themed QR code based on stock status
  Widget generateStatusThemedQrCode(
      InventoryItem item, {
        double size = 200.0,
      }) {
    Color primaryColor;
    Color secondaryColor;

    if (item.stockQuantity == 0) {
      primaryColor = Colors.red.shade700;
      secondaryColor = Colors.red.shade100;
    } else if (item.isLowStock) {
      primaryColor = Colors.orange.shade700;
      secondaryColor = Colors.orange.shade100;
    } else {
      primaryColor = Colors.green.shade700;
      secondaryColor = Colors.green.shade100;
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: PrettyQrView.data(
        data: generateQrData(item),
        decoration: PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(color: primaryColor),
          background: Colors.white,
        ),
      ),
    );
  }
}

enum QrCodeShape {
  rounded,
  circles,
  squares,
  mixed,
}
