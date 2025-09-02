// data/services/import_export_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/inventory_item.dart';

class ImportExportService {
  Future<List<InventoryItem>?> importFromCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final input = file.readAsStringSync();
        final fields = const CsvToListConverter().convert(input);

        // Skip header row
        final items = <InventoryItem>[];
        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.length >= 8) {
            // Minimum required fields
            items.add(_createItemFromRow(row));
          }
        }

        return items;
      }
    } catch (e) {
      throw Exception('Error importing CSV: $e');
    }

    return null;
  }

  Future<void> exportToCSV(List<InventoryItem> items) async {
    try {
      final directory = await getDownloadsDirectory();
      final file = File(
        '${directory?.path}/inventory_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      final List<List<dynamic>> csvData = [
        // Header row
        [
          'SKU',
          'Name (English)',
          'Name (Arabic)',
          'Category',
          'Subcategory',
          'Stock Quantity',
          'Unit Price',
          'Min Stock Level',
          'Width',
          'Height',
          'Depth',
          'Unit',
          'Pixel Width',
          'Pixel Height',
          'Other Sp.',
          'Color Space',
          'Comment',
          'Created At',
          'Updated At',
        ],
        // Data rows
        ...items.map(
          (item) => [
            item.sku,
            item.nameEn,
            item.nameAr,
            item.descriptionEn ?? '',
            item.descriptionAr ?? '',
            item.categoryId,
            item.subcategory,
            item.stockQuantity,
            item.unitPrice ?? 'N/A',
            item.minStockLevel,
            item.dimensions.width,
            item.dimensions.height,
            item.dimensions.depth ?? '',
            item.dimensions.unit ?? 'mm',
            item.imageProperties.pixelWidth,
            item.imageProperties.pixelHeight,
            item.imageProperties.otherSp ?? '',
            item.imageProperties.colorSpace,
            item.comment ?? '',
            item.createdAt.toIso8601String(),
            item.updatedAt.toIso8601String(),
          ],
        ),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      print('CSV exported to: ${file.path}');
    } catch (e) {
      throw Exception('Error exporting CSV: $e');
    }
  }

  Future<void> exportToPDF(List<InventoryItem> items) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Inventory Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FixedColumnWidth(80),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FixedColumnWidth(80),
                  3: pw.FixedColumnWidth(80),
                  4: pw.FixedColumnWidth(80),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildPdfCell('SKU', isHeader: true),
                      _buildPdfCell('Name', isHeader: true),
                      _buildPdfCell('Stock', isHeader: true),
                      _buildPdfCell('Price', isHeader: true),
                      _buildPdfCell('Value', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...items.map(
                    (item) => pw.TableRow(
                      children: [
                        _buildPdfCell(item.sku),
                        _buildPdfCell(item.nameEn),
                        _buildPdfCell(item.stockQuantity.toString()),
                        _buildPdfCell(_formatPrice(item.unitPrice)),
                        _buildPdfCell(_formatPrice(item.totalValue)),
                      ],
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final directory = await getDownloadsDirectory();
      final file = File(
        '${directory?.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      print('PDF exported to: ${file.path}');
    } catch (e) {
      throw Exception('Error exporting PDF: $e');
    }
  }

  // ✅ NEW HELPER METHOD - Safe price formatting
  String _formatPrice(double? price) {
    if (price == null) {
      return 'N/A';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  InventoryItem _createItemFromRow(List<dynamic> row) {
    return InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sku: row[0]?.toString() ?? '',
      nameEn: row[1]?.toString() ?? '',
      nameAr: row[2]?.toString() ?? '',
      descriptionEn:
          (row.length > 3 && row[3]?.toString().trim().isNotEmpty == true)
          ? row[3].toString()
          : null,
      // ✅ NEW - Handle description fields
      descriptionAr:
          (row.length > 4 && row[4]?.toString().trim().isNotEmpty == true)
          ? row[4].toString()
          : null,
      // ✅ NEW
      categoryId: row.length > 5 ? (row[5]?.toString() ?? '') : '',
      subcategory: row.length > 6 ? (row[6]?.toString() ?? '') : '',
      stockQuantity: row.length > 7
          ? (int.tryParse(row[7]?.toString() ?? '') ?? 0)
          : 0,
      unitPrice: row.length > 8 && row[8]?.toString().trim().isNotEmpty == true
          ? double.tryParse(row[8].toString())
          : null,
      minStockLevel: row.length > 9
          ? (int.tryParse(row[9]?.toString() ?? '') ?? 0)
          : 0,
      dimensions: ProductDimensions(
        width: row.length > 10
            ? (double.tryParse(row[10]?.toString() ?? '') ?? 0.0)
            : null,
        height: row.length > 11
            ? (double.tryParse(row[11]?.toString() ?? '') ?? 0.0)
            : null,
        depth:
            (row.length > 12 &&
                row[12]?.toString().trim().isNotEmpty == true) // ✅ CHANGED
            ? row[12].toString()
            : null,
        unit: (row.length > 13 && row[13]?.toString().trim().isNotEmpty == true)
            ? row[13].toString()
            : 'mm', // Default unit
      ),
      imageProperties: ImageProperties(
        pixelWidth: row.length > 14 && row[14]?.toString().trim().isNotEmpty == true
            ? int.tryParse(row[14].toString())
            : null,  // ✅ CHANGED - Null if empty
        pixelHeight: row.length > 15 && row[15]?.toString().trim().isNotEmpty == true
            ? int.tryParse(row[15].toString())
            : null,  // ✅ CHANGED - Null if empty
        otherSp:
            (row.length > 16 &&
                row[16]?.toString().trim().isNotEmpty == true) // ✅ CHANGED
            ? row[16].toString()
            : null,
        colorSpace: (row.length > 17 && row[17]?.toString().trim().isNotEmpty == true)
            ? row[17].toString()
            : 'RGB',
            ),
      comment:
          (row.length > 14 && row[14]?.toString().trim().isNotEmpty == true)
          ? row[14].toString()
          : null,
      // ✅ NEW - Handle comment field
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
