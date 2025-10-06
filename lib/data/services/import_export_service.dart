// data/services/import_export_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories.dart' as get_categories_usecase;
import '../../core/usecases/usecase.dart';

class ImportExportService {
  static const double _BARCODE_LABEL_FONT_SIZE = 10.0;
  static const double _BARCODE_WIDTH = 180.0;
  static const double _BARCODE_HEIGHT = 60.0;

  // ✅ SINGLE LABEL PAGE DIMENSIONS - Optimized for GK420t
  static const double _LABEL_WIDTH = 288.0;   // 102mm (4" label)
  static const double _LABEL_HEIGHT = 216.0;  // 76mm (3" label)
  static pw.Font? _arabicFont;
  static pw.Font? _arabicFontBold;
  final get_categories_usecase.GetCategories _getCategories;

  ImportExportService({
    required get_categories_usecase.GetCategories getCategories,
  }) : _getCategories = getCategories;
  Future<void> _initializeFonts() async {
    if (_arabicFont == null || _arabicFontBold == null) {
      try {
        // Load Arabic fonts from assets
        final regularFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
        final boldFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');

        _arabicFont = pw.Font.ttf(regularFontData);
        _arabicFontBold = pw.Font.ttf(boldFontData);

        print('✅ Arabic fonts loaded successfully');
      } catch (e) {
        print('⚠️ Warning: Failed to load Arabic fonts: $e');
        // Fallback to default fonts
        _arabicFont = null;
        _arabicFontBold = null;
      }
    }
  }

  // ✅ HELPER - Create text style with Arabic font support
  pw.TextStyle _createTextStyle({
    required double fontSize,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? PdfColors.black,
      font: isBold ? _arabicFontBold : _arabicFont,
      fontFallback: [
        if (_arabicFont != null) _arabicFont!,
        if (_arabicFontBold != null) _arabicFontBold!,
      ],
    );
  }
  // ✅ CSV Import - No changes needed
  Future<List<InventoryItem>?> importFromCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      String csvContent;

      if (file.bytes != null) {
        csvContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        final fileObj = File(file.path!);
        csvContent = await fileObj.readAsString();
      } else {
        throw Exception('Unable to read the selected file');
      }

      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvContent);

      if (csvData.isEmpty || csvData.length < 2) {
        throw Exception('CSV file must contain at least a header row and one data row');
      }

      final List<InventoryItem> items = [];
      for (int i = 1; i < csvData.length; i++) {
        try {
          final row = csvData[i];
          if (row.isNotEmpty && _isValidRow(row)) {
            final item = _createItemFromCsvRow(row, i + 1);
            items.add(item);
          }
        } catch (e) {
          print('⚠️ Warning: Skipping invalid row ${i + 1}: $e');
          continue;
        }
      }

      if (items.isEmpty) {
        throw Exception('No valid data rows found in the CSV file');
      }

      return items;
    } catch (e) {
      throw Exception('CSV import failed: ${e.toString()}');
    }
  }

  // ✅ CSV Export with category names
  Future<String> exportToCSV(List<InventoryItem> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No items to export');
      }

      final categoryMap = await _getCategoryMap();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'inventory_export_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      // ✅ DEBUG - Print Arabic text to check data integrity
      print('🔍 Sample Arabic data check:');
      if (items.isNotEmpty && items.first.nameAr.isNotEmpty) {
        print('First item Arabic name: "${items.first.nameAr}"');
        print('Arabic name length: ${items.first.nameAr.length}');
      }

      final List<List<dynamic>> csvData = [
        [
          'SKU',
          'Name (English)',
          'Name (Arabic)', // اسم المنتج بالعربية
          'Description (English)',
          'Description (Arabic)', // الوصف بالعربية
          'Category Name', // اسم الفئة
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
        ...items.map(
              (item) => [
            item.sku ?? '',
            item.nameEn ?? '',
            item.nameAr ?? '', // ✅ CRITICAL - Ensure Arabic text is preserved
            item.descriptionEn ?? '',
            item.descriptionAr ?? '',
            categoryMap[item.categoryId] ?? 'Unknown Category',
            item.subcategory ?? '',
            item.stockQuantity,
            item.unitPrice?.toString() ?? '',
            item.minStockLevel,
            item.dimensions.width?.toString() ?? '',
            item.dimensions.height?.toString() ?? '',
            item.dimensions.depth ?? '',
            item.dimensions.unit ?? '',
            item.imageProperties.pixelWidth?.toString() ?? '',
            item.imageProperties.pixelHeight?.toString() ?? '',
            item.imageProperties.otherSp ?? '',
            item.imageProperties.colorSpace ?? '',
            item.comment ?? '',
            item.createdAt.toIso8601String(),
            item.updatedAt.toIso8601String(),
          ],
        ),
      ];

      // ✅ FIXED - Proper UTF-8 with BOM encoding for Arabic text
      final csvString = const ListToCsvConverter().convert(csvData);

      // ✅ DEBUG - Print CSV content to verify Arabic text
      print('🔍 CSV content sample (first 500 chars):');
      print(csvString.substring(0, csvString.length > 500 ? 500 : csvString.length));

      final file = File(filePath);

      // ✅ METHOD 1 - UTF-8 with BOM (Byte Order Mark) for Excel compatibility
      const utf8Bom = [0xEF, 0xBB, 0xBF]; // UTF-8 BOM bytes
      final utf8Bytes = utf8.encode(csvString); // Properly encode to UTF-8
      final finalBytes = Uint8List.fromList([...utf8Bom, ...utf8Bytes]);

      await file.writeAsBytes(finalBytes);

      print('✅ CSV file saved with UTF-8 BOM encoding: $filePath');
      return filePath;

    } catch (e) {
      print('❌ CSV export failed: ${e.toString()}');
      throw Exception('CSV export failed: ${e.toString()}');
    }
  }
  // ✅ PDF Export with category names (table format)
  Future<String> exportToPDF(List<InventoryItem> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No items to export');
      }
      await _initializeFonts();
      final categoryMap = await _getCategoryMap();
      final pdf = pw.Document();
      const itemsPerPage = 25;
      final chunks = _chunkList(items, itemsPerPage);

      for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return [
                _buildPdfHeader(
                  'Inventory Report',
                  chunkIndex + 1,
                  chunks.length,
                  items.length,
                ),
                pw.SizedBox(height: 15),
                _buildInventoryTable(chunks[chunkIndex], categoryMap),
              ];
            },
          ),
        );
      }

      return await _savePdfFile(pdf, 'inventory_report');
    } catch (e) {
      throw Exception('PDF export failed: ${e.toString()}');
    }
  }

  // ✅ UPDATED - PDF Export with barcodes - ONE LABEL PER PAGE
  Future<String> exportToPDFWithBarcodes(List<InventoryItem> items) async {
    try {
      if (items.isEmpty) {
        throw Exception('No items to export');
      }
      await _initializeFonts();

      final categoryMap = await _getCategoryMap();
      final pdf = pw.Document();

      // ✅ CRITICAL CHANGE - One item per page
      for (int i = 0; i < items.length; i++) {
        pdf.addPage(
          pw.Page(
            // ✅ SINGLE LABEL PAGE FORMAT - Perfect for GK420t
            pageFormat: PdfPageFormat(
              _LABEL_WIDTH,  // 102mm width
              _LABEL_HEIGHT, // 76mm height
              marginLeft: 8,
              marginTop: 8,
              marginRight: 8,
              marginBottom: 8,
            ),
            build: (pw.Context context) {
              return pw.Container(
                width: double.infinity,
                height: double.infinity,
                child: _buildSingleLabel(items[i], categoryMap),
              );
            },
          ),
        );
      }

      return await _savePdfFile(pdf, 'barcode_labels_single');
    } catch (e) {
      throw Exception('PDF barcode export failed: ${e.toString()}');
    }
  }

  // ✅ NEW - Build single optimized label for GK420t
  pw.Widget _buildSingleLabel(InventoryItem item, Map<String, String> categoryMap) {
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          // ✅ CATEGORY INFO SECTION - Top of label
          pw.Container(
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Category: ${categoryMap[item.categoryId] ?? 'Unknown'}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                  overflow: pw.TextOverflow.visible,
                ),
                if (item.subcategory.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Sub: ${item.subcategory}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                    overflow: pw.TextOverflow.visible,
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 6),

          // ✅ PRODUCT NAME SECTION - Main content
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // English name - MAIN PRODUCT NAME
                  pw.Container(
                    width: double.infinity,
                    child: pw.Text(
                      item.nameEn,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                      maxLines: null, // ✅ Allow unlimited lines
                      softWrap: true,
                      overflow: pw.TextOverflow.visible,
                    ),
                  ),

                ],
              ),
            ),
          ),

          // ✅ SKU SECTION
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'SKU: ${item.sku}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),

          // ✅ BARCODE SECTION - CENTER OF LABEL
          pw.Expanded(
            flex: 4,
            child: pw.Center(
              child: pw.Container(
                width: _BARCODE_WIDTH,
                height: _BARCODE_HEIGHT + 15,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: item.sku,
                  drawText: true,
                  textStyle: pw.TextStyle(
                    fontSize: _BARCODE_LABEL_FONT_SIZE,
                    fontWeight: pw.FontWeight.normal,
                  ),
                  width: _BARCODE_WIDTH,
                  height: _BARCODE_HEIGHT,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ✅ Get category map using correct NoParams
  Future<Map<String, String>> _getCategoryMap() async {
    try {
      final result = await _getCategories( NoParams());
      return result.fold(
            (failure) {
          print('⚠️ Warning: Failed to load categories: ${failure.toString()}');
          return <String, String>{};
        },
            (categories) {
          return {for (var category in categories) category.id: category.name};
        },
      );
    } catch (e) {
      print('⚠️ Warning: Error creating category map: $e');
      return <String, String>{};
    }
  }

  // ✅ Build PDF header
  pw.Widget _buildPdfHeader(String title, int currentPage, int totalPages, int totalItems) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Page $currentPage of $totalPages',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                'Total Items: $totalItems',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Build inventory table with category names
  pw.Widget _buildInventoryTable(List<InventoryItem> items, Map<String, String> categoryMap) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: pw.FixedColumnWidth(70),
        1: pw.FlexColumnWidth(3),
        2: pw.FixedColumnWidth(60),
        3: pw.FixedColumnWidth(70),
        4: pw.FixedColumnWidth(90),
        5: pw.FlexColumnWidth(2),
        6: pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('SKU', isHeader: true),
            _buildTableCell('Name', isHeader: true),
            _buildTableCell('Stock', isHeader: true),
            _buildTableCell('Price', isHeader: true),
            _buildTableCell('Dimensions', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Total Value', isHeader: true),
          ],
        ),
        ...items.map(
              (item) => pw.TableRow(
            children: [
              _buildTableCell(item.sku),
              _buildTableCell(_truncateText(item.nameEn, 30)),
              _buildTableCell(item.stockQuantity.toString()),
              _buildTableCell(_formatPrice(item.unitPrice)),
              _buildTableCell(_formatDimensions(item.dimensions)),
              _buildTableCell(_truncateText(
                categoryMap[item.categoryId] ?? 'Unknown',
                15,
              )),
              _buildTableCell(_formatPrice(item.totalValue)),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ HELPER METHODS
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
        ),
        maxLines: isHeader ? 1 : 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return 'N/A';
    return '\$${price.toStringAsFixed(2)}';
  }

  String _formatDimensions(ProductDimensions dims) {
    final parts = <String>[];
    if (dims.width != null) parts.add(dims.width.toString());
    if (dims.height != null) parts.add(dims.height.toString());
    if (dims.hasDepth) parts.add(dims.depth!);
    if (parts.isEmpty) return 'N/A';
    return '${parts.join('×')} ${dims.displayUnit}';
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  bool _isValidRow(List<dynamic> row) {
    return row.isNotEmpty && row[0] != null && row[0].toString().trim().isNotEmpty;
  }

  Future<String> _savePdfFile(pw.Document pdf, String baseName) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${baseName}_$timestamp.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return filePath;
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final List<List<T>> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      final end = i + chunkSize > list.length ? list.length : i + chunkSize;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  InventoryItem _createItemFromCsvRow(List<dynamic> row, int rowNumber) {
    try {
      return InventoryItem(
        id: '',
        sku: _safeGetString(row, 0, 'SKU'),
        nameEn: _safeGetString(row, 1, 'Name (English)'),
        nameAr: _safeGetString(row, 2, 'Name (Arabic)', defaultValue: ''),
        descriptionEn: _safeGetOptionalString(row, 3),
        descriptionAr: _safeGetOptionalString(row, 4),
        categoryId: _safeGetString(row, 5, 'Category ID'),
        subcategory: _safeGetString(row, 6, 'Subcategory'),
        stockQuantity: _safeGetInt(row, 7, 'Stock Quantity'),
        unitPrice: _safeGetOptionalDouble(row, 8),
        minStockLevel: _safeGetInt(row, 9, 'Min Stock Level'),
        dimensions: ProductDimensions(
          width: _safeGetOptionalDouble(row, 10),
          height: _safeGetOptionalDouble(row, 11),
          depth: _safeGetOptionalString(row, 12),
          unit: _safeGetOptionalString(row, 13) ?? 'mm',
        ),
        imageProperties: ImageProperties(
          pixelWidth: _safeGetOptionalInt(row, 14),
          pixelHeight: _safeGetOptionalInt(row, 15),
          otherSp: _safeGetOptionalString(row, 16),
          colorSpace: _safeGetOptionalString(row, 17) ?? 'RGB',
        ),
        comment: _safeGetOptionalString(row, 18),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Row $rowNumber parsing error: $e');
    }
  }

  String _safeGetString(List<dynamic> row, int index, String fieldName, {String? defaultValue}) {
    if (index >= row.length) {
      if (defaultValue != null) return defaultValue;
      throw Exception('Missing required field: $fieldName');
    }
    final value = row[index]?.toString().trim() ?? '';
    if (value.isEmpty && defaultValue == null) {
      throw Exception('Empty required field: $fieldName');
    }
    return value.isEmpty ? (defaultValue ?? '') : value;
  }

  String? _safeGetOptionalString(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final value = row[index]?.toString().trim();
    return (value?.isEmpty ?? true) ? null : value;
  }

  int _safeGetInt(List<dynamic> row, int index, String fieldName) {
    if (index >= row.length) {
      throw Exception('Missing required field: $fieldName');
    }
    final value = int.tryParse(row[index]?.toString() ?? '');
    if (value == null) {
      throw Exception('Invalid integer for field: $fieldName');
    }
    return value;
  }

  int? _safeGetOptionalInt(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    return int.tryParse(row[index]?.toString() ?? '');
  }

  double? _safeGetOptionalDouble(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    return double.tryParse(row[index]?.toString() ?? '');
  }
}
