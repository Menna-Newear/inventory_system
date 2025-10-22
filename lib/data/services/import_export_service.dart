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
import '../../domain/usecases/get_categories.dart' as get_categories_usecase;
import '../../core/usecases/usecase.dart';

class ImportExportService {
  static const double _BARCODE_LABEL_FONT_SIZE = 10.0;
  static const double _BARCODE_WIDTH = 160.0;
  static const double _BARCODE_HEIGHT = 50.0;
  static const double _LABEL_WIDTH = 288.0;   // 102mm (4" label)
  static const double _LABEL_HEIGHT = 216.0;  // 76mm (3" label)

  static pw.Font? _arabicFont;
  static pw.Font? _arabicFontBold;
  static bool _fontInitialized = false;

  final get_categories_usecase.GetCategories _getCategories;

  ImportExportService({
    required get_categories_usecase.GetCategories getCategories,
  }) : _getCategories = getCategories;

  // ✅ Font initialization with fallback
  Future<void> _initializeFonts() async {
    if (_fontInitialized) return;
    _fontInitialized = true;

    try {
      final regularFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');

      _arabicFont = pw.Font.ttf(regularFontData);
      _arabicFontBold = pw.Font.ttf(boldFontData);

      print('✅ Arabic fonts loaded successfully');
    } catch (e) {
      print('⚠️ Warning: Failed to load Arabic fonts: $e');
      _arabicFont = null;
      _arabicFontBold = null;
    }
  }

  // ✅ Create text style with Arabic font support
  pw.TextStyle _createTextStyle({
    required double fontSize,
    bool isBold = false,
    PdfColor? color,
  }) {
    if (_arabicFont != null && _arabicFontBold != null) {
      return pw.TextStyle(
        fontSize: fontSize,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? PdfColors.black,
        font: isBold ? _arabicFontBold : _arabicFont,
        fontFallback: [_arabicFont!, _arabicFontBold!],
      );
    }

    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? PdfColors.black,
    );
  }

  // ✅ ENHANCED - CSV Import with serial number support
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

  // ✅ ENHANCED - CSV Export with serial number support
  Future<String> exportToCSV(List<InventoryItem> items, {bool includeSerialNumbers = false}) async {
    try {
      if (items.isEmpty) {
        throw Exception('No items to export');
      }

      final categoryMap = await _getCategoryMap();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'inventory_export_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      print('🔍 Sample Arabic data check:');
      if (items.isNotEmpty && items.first.nameAr.isNotEmpty) {
        print('First item Arabic name: "${items.first.nameAr}"');
        print('Arabic name length: ${items.first.nameAr.length}');
      }

      final List<List<dynamic>> csvData = [
        [
          'SKU',
          'Name (English)',
          'Name (Arabic)',
          'Description (English)',
          'Description (Arabic)',
          'Category Name',
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
          'Image URL',
          'Image Filename',
          'Comment',
          // ✅ NEW - Serial tracking columns
          'Serial Tracked',
          'Serial Prefix',
          'Serial Length',
          'Serial Format',
          'Available Serials',
          'Total Serials',
          'Serial Numbers List',
          'Created At',
          'Updated At',
        ],
      ];

      // Add data rows
      for (final item in items) {
        final baseRow = [
          item.sku,
          item.nameEn,
          item.nameAr,
          item.descriptionEn ?? '',
          item.descriptionAr ?? '',
          categoryMap[item.categoryId] ?? 'Unknown Category',
          item.subcategory,
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
          item.imageProperties.colorSpace,
          item.imageUrl ?? '',
          item.imageFileName ?? '',
          item.comment ?? '',
          // ✅ NEW - Serial tracking data
          item.isSerialTracked.toString(),
          item.serialNumberPrefix ?? '',
          item.serialNumberLength?.toString() ?? '',
          item.serialFormat.name,
          item.availableStock.toString(),
          item.serialNumbers.length.toString(),
          item.serialNumbers.map((s) => s.serialNumber).join(';'),
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
        ];

        csvData.add(baseRow);

        // ✅ OPTIONAL - Add individual serial numbers as separate rows
        if (includeSerialNumbers && item.isSerialTracked && item.serialNumbers.isNotEmpty) {
          for (final serial in item.serialNumbers) {
            csvData.add([
              '${item.sku}-SERIAL',
              '${item.nameEn} (Serial: ${serial.serialNumber})',
              '', '', '',
              categoryMap[item.categoryId] ?? 'Unknown Category',
              item.subcategory,
              1, // Individual serial quantity = 1
              item.unitPrice?.toString() ?? '',
              '', '', '', '', '', '', '', '', '',
              item.imageUrl ?? '',
              item.imageFileName ?? '',
              serial.notes ?? '',
              'false', // Individual serials are not tracked
              '', '', '',
              serial.status.name,
              '', // Available count for individual serial
              serial.serialNumber,
              serial.createdAt.toIso8601String(),
              serial.updatedAt.toIso8601String(),
            ]);
          }
        }
      }

      final csvString = const ListToCsvConverter().convert(csvData);

      print('🔍 CSV content sample (first 500 chars):');
      print(csvString.substring(0, csvString.length > 500 ? 500 : csvString.length));

      final file = File(filePath);
      const utf8Bom = [0xEF, 0xBB, 0xBF];
      final utf8Bytes = utf8.encode(csvString);
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

  // ✅ ENHANCED - PDF Export with barcodes and serial support
  Future<String> exportToPDFWithBarcodes(
      List<InventoryItem> items, {
        bool includeSerialNumbers = false,
        SerialNumberBarcodeOption barcodeOption = SerialNumberBarcodeOption.combined,
      }) async {
    try {
      if (items.isEmpty) {
        throw Exception('No items to export');
      }
      await _initializeFonts();

      final categoryMap = await _getCategoryMap();
      final pdf = pw.Document();

      print('🔍 DEBUG - Creating PDF with ${items.length} items');
      print('🔍 DEBUG - Include serials: $includeSerialNumbers, Barcode option: ${barcodeOption.name}');

      for (final item in items) {
        if (item.isSerialTracked && includeSerialNumbers && item.serialNumbers.isNotEmpty) {
          // ✅ Generate labels for each serial number
          for (final serial in item.serialNumbers) {
            pdf.addPage(_buildSerialLabel(item, serial, categoryMap, barcodeOption));
          }
        } else {
          // ✅ Standard item label
          pdf.addPage(_buildStandardLabel(item, categoryMap));
        }
      }

      final fileName = includeSerialNumbers ? 'serial_labels' : 'item_labels';
      return await _savePdfFile(pdf, fileName);

    } catch (e) {
      throw Exception('PDF barcode export failed: ${e.toString()}');
    }
  }

  // ✅ NEW - Build serial-specific label
  pw.Page _buildSerialLabel(
      InventoryItem item,
      SerialNumber serial,
      Map<String, String> categoryMap,
      SerialNumberBarcodeOption barcodeOption,
      ) {
    return pw.Page(
      pageFormat: PdfPageFormat(_LABEL_WIDTH, _LABEL_HEIGHT, marginAll: 4),
      build: (pw.Context context) {
        final String barcodeData;
        switch (barcodeOption) {
          case SerialNumberBarcodeOption.skuOnly:
            barcodeData = item.sku;
            break;
          case SerialNumberBarcodeOption.serialOnly:
            barcodeData = serial.serialNumber;
            break;
          case SerialNumberBarcodeOption.combined:
            barcodeData = item.getBarcodeData(serialNumber: serial.serialNumber);
            break;
        }

        return pw.Container(
          width: double.infinity,
          height: double.infinity,
          color: PdfColors.white,
          child: pw.Stack(
            children: [
              // Category info
              pw.Positioned(
                left: 10, top: 10,
                child: pw.Text(
                  'Cat: ${categoryMap[item.categoryId] ?? 'Unknown'}',
                  style: _createTextStyle(fontSize: 9, isBold: true),
                ),
              ),

              // Serial status
              pw.Positioned(
                right: 10, top: 10,
                child: pw.Text(
                  'Status: ${serial.status.displayName}',
                  style: _createTextStyle(fontSize: 8, color: _getStatusColor(serial.status)),
                ),
              ),

              // Product name
              pw.Positioned(
                left: 10, right: 10, top: 35,
                child: pw.Center(
                  child: pw.Text(
                    item.nameEn,
                    style: _createTextStyle(fontSize: 14, isBold: true),
                    textAlign: pw.TextAlign.center, maxLines: 2,
                  ),
                ),
              ),

              // SKU and Serial
              pw.Positioned(
                left: 10, right: 10, top: 80,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SKU: ${item.sku}',
                      style: _createTextStyle(fontSize: 11, isBold: true),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Serial: ${serial.serialNumber}',
                      style: _createTextStyle(fontSize: 12, isBold: true, color: PdfColors.red),
                    ),
                  ],
                ),
              ),

              // ✅ BARCODE - Uses selected data format
              pw.Positioned(
                left: 44, top: 120,
                child: pw.Container(
                  width: 200, height: 60,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: barcodeData,
                    drawText: true,
                    textStyle: _createTextStyle(fontSize: 10, isBold: true),
                    color: PdfColors.black,
                    backgroundColor: PdfColors.white,
                    width: 200, height: 60,
                  ),
                ),
              ),

              // Notes and price
              if (serial.notes != null && serial.notes!.isNotEmpty)
                pw.Positioned(
                  left: 10, bottom: 30,
                  child: pw.Text(
                    'Notes: ${serial.notes}',
                    style: _createTextStyle(fontSize: 8),
                    maxLines: 2,
                  ),
                ),

              if (item.unitPrice != null)
                pw.Positioned(
                  right: 10, bottom: 10,
                  child: pw.Text(
                    item.displayPrice,
                    style: _createTextStyle(fontSize: 9, isBold: true),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ✅ ENHANCED - Build standard label (updated from your original)
  pw.Page _buildStandardLabel(InventoryItem item, Map<String, String> categoryMap) {
    return pw.Page(
      pageFormat: PdfPageFormat(_LABEL_WIDTH, _LABEL_HEIGHT, marginLeft: 8, marginTop: 8, marginRight: 8, marginBottom: 8),
      build: (pw.Context context) {
        return pw.Container(
          width: double.infinity,
          height: double.infinity,
          child: _buildSingleLabel(item, categoryMap),
        );
      },
    );
  }

  // ✅ UPDATED - Enhanced single label with serial tracking awareness
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
          // Category info section
          pw.Container(
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Category: ${categoryMap[item.categoryId] ?? 'Unknown'}',
                  style: _createTextStyle(fontSize: 8, color: PdfColors.grey700, isBold: true),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                  overflow: pw.TextOverflow.visible,
                ),
                if (item.subcategory.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Sub: ${item.subcategory}',
                    style: _createTextStyle(fontSize: 8, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                    overflow: pw.TextOverflow.visible,
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 6),

          // Product name section
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: double.infinity,
                    child: pw.Text(
                      item.nameEn,
                      style: _createTextStyle(fontSize: 12, isBold: true),
                      textAlign: pw.TextAlign.center,
                      maxLines: null,
                      softWrap: true,
                      overflow: pw.TextOverflow.visible,
                    ),
                  ),

                  // ✅ Show Arabic name if available and fonts loaded
                  if (item.nameAr.isNotEmpty && _arabicFont != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Container(
                      width: double.infinity,
                      child: pw.Text(
                        item.nameAr,
                        style: _createTextStyle(fontSize: 10, color: PdfColors.grey700),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl,
                        maxLines: null,
                        softWrap: true,
                        overflow: pw.TextOverflow.visible,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // SKU section
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'SKU: ${item.sku}',
              style: _createTextStyle(fontSize: 10, isBold: true),
              textAlign: pw.TextAlign.center,
            ),
          ),

          // ✅ SERIAL TRACKING INFO (if applicable)
          if (item.isSerialTracked) ...[
            pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                'Serial Tracked: ${item.availableStock}/${item.totalSerialCount} available',
                style: _createTextStyle(fontSize: 8, color: PdfColors.blue),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],

          // Barcode section
          pw.Expanded(
            flex: 4,
            child: pw.Center(
              child: pw.Container(
                width: _BARCODE_WIDTH,
                height: _BARCODE_HEIGHT + 15,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: item.sku, // Standard SKU barcode for non-serialized items
                  drawText: true,
                  textStyle: _createTextStyle(fontSize: _BARCODE_LABEL_FONT_SIZE),
                  width: _BARCODE_WIDTH,
                  height: _BARCODE_HEIGHT,
                ),
              ),
            ),
          ),

          // ✅ ENHANCED - Bottom info with effective stock
          pw.Container(
            width: double.infinity,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Text(
                  'Stock: ${item.effectiveStockQuantity}',
                  style: _createTextStyle(fontSize: 8),
                ),
                pw.Text(
                  'Min: ${item.minStockLevel}',
                  style: _createTextStyle(fontSize: 8),
                ),
                if (item.hasPrice)
                  pw.Text(
                    item.displayPrice,
                    style: _createTextStyle(fontSize: 8, isBold: true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW - ZPL Export with serial number support
  Future<String> exportToZPL(
      List<InventoryItem> items, {
        bool includeSerialNumbers = false,
        SerialNumberBarcodeOption barcodeOption = SerialNumberBarcodeOption.combined,
      }) async {
    try {
      if (items.isEmpty) {
        throw Exception('No items to export');
      }

      final categoryMap = await _getCategoryMap();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'zebra_labels_$timestamp.zpl';
      final filePath = '${directory.path}/$fileName';

      final StringBuffer zplBuffer = StringBuffer();

      for (final item in items) {
        if (item.isSerialTracked && includeSerialNumbers && item.serialNumbers.isNotEmpty) {
          // Generate ZPL for each serial number
          for (final serial in item.serialNumbers) {
            final String barcodeData;
            switch (barcodeOption) {
              case SerialNumberBarcodeOption.skuOnly:
                barcodeData = item.sku;
                break;
              case SerialNumberBarcodeOption.serialOnly:
                barcodeData = serial.serialNumber;
                break;
              case SerialNumberBarcodeOption.combined:
                barcodeData = item.getBarcodeData(serialNumber: serial.serialNumber);
                break;
            }

            zplBuffer.writeln('^XA'); // Start of label
            zplBuffer.writeln('^CF0,30'); // Default font, size 30
            zplBuffer.writeln('^LH30,30'); // Label home position

            // Category
            zplBuffer.writeln('^FO20,20^A0N,25,25^FDCategory: ${categoryMap[item.categoryId] ?? 'Unknown'}^FS');

            // Status
            zplBuffer.writeln('^FO20,50^A0N,20,20^FDStatus: ${serial.status.displayName}^FS');

            // Product name
            zplBuffer.writeln('^FO20,80^A0N,30,30^FD${item.nameEn}^FS');

            // SKU
            zplBuffer.writeln('^FO20,120^A0N,25,25^FDSKU: ${item.sku}^FS');

            // Serial Number
            zplBuffer.writeln('^FO20,150^A0N,25,25^FDSerial: ${serial.serialNumber}^FS');

            // ✅ BARCODE with serial data
            zplBuffer.writeln('^FO50,180^BY2^BCN,50,Y,N,N^FD$barcodeData^FS');

            // Price and notes
            if (item.hasPrice) {
              zplBuffer.writeln('^FO200,240^A0N,18,18^FD${item.displayPrice}^FS');
            }

            if (serial.notes != null && serial.notes!.isNotEmpty) {
              zplBuffer.writeln('^FO20,270^A0N,15,15^FDNotes: ${serial.notes}^FS');
            }

            zplBuffer.writeln('^XZ'); // End of label
            zplBuffer.writeln(); // Empty line
          }
        } else {
          // Standard item ZPL
          zplBuffer.writeln('^XA');
          zplBuffer.writeln('^CF0,30');
          zplBuffer.writeln('^LH30,30');

          final categoryName = categoryMap[item.categoryId] ?? 'Unknown';
          zplBuffer.writeln('^FO20,20^A0N,25,25^FDCategory: $categoryName^FS');
          zplBuffer.writeln('^FO20,50^A0N,20,20^FDSub: ${item.subcategory}^FS');
          zplBuffer.writeln('^FO20,90^A0N,35,35^FD${item.nameEn}^FS');
          zplBuffer.writeln('^FO20,140^A0N,25,25^FDSKU: ${item.sku}^FS');

          // ✅ Serial tracking info for ZPL
          if (item.isSerialTracked) {
            zplBuffer.writeln('^FO20,170^A0N,20,20^FDSerial Tracked: ${item.availableStock}/${item.totalSerialCount}^FS');
          }

          zplBuffer.writeln('^FO50,200^BY2^BCN,50,Y,N,N^FD${item.sku}^FS');
          zplBuffer.writeln('^FO20,260^A0N,18,18^FDStock: ${item.effectiveStockQuantity}   Min: ${item.minStockLevel}^FS');

          if (item.hasPrice) {
            zplBuffer.writeln('^FO200,260^A0N,18,18^FD${item.displayPrice}^FS');
          }

          zplBuffer.writeln('^XZ');
        }
      }

      final file = File(filePath);
      await file.writeAsString(zplBuffer.toString());

      print('✅ ZPL file created: $filePath');
      print('📄 Contains labels for ${items.length} items');

      return filePath;

    } catch (e) {
      throw Exception('ZPL export failed: ${e.toString()}');
    }
  }

  // ✅ Helper methods
  PdfColor _getStatusColor(SerialStatus status) {
    switch (status) {
      case SerialStatus.available: return PdfColors.green;
      case SerialStatus.reserved: return PdfColors.orange;
      case SerialStatus.sold: return PdfColors.blue;
      case SerialStatus.rented: return PdfColors.purple;
      case SerialStatus.damaged: return PdfColors.red;
      case SerialStatus.returned: return PdfColors.amber;
      case SerialStatus.recalled: return PdfColors.red;
    }
  }

  // ✅ Get category map using correct NoParams
  Future<Map<String, String>> _getCategoryMap() async {
    try {
      final result = await _getCategories(NoParams());
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
                style: _createTextStyle(fontSize: 24, isBold: true),
              ),
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: _createTextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Page $currentPage of $totalPages',
                style: _createTextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                'Total Items: $totalItems',
                style: _createTextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ ENHANCED - Build inventory table with serial tracking awareness
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
              _buildTableCell(
                  item.isSerialTracked
                      ? '${item.effectiveStockQuantity} (${item.totalSerialCount} total)'
                      : item.stockQuantity.toString()
              ),
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

  // ✅ Helper methods (unchanged)
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: _createTextStyle(
          fontSize: isHeader ? 10 : 9,
          isBold: isHeader,
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

  // ✅ ENHANCED - Create item from CSV row with serial support
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
        imageUrl: _safeGetOptionalString(row, 18),
        imageFileName: _safeGetOptionalString(row, 19),
        comment: _safeGetOptionalString(row, 20),
        // ✅ NEW - Serial tracking fields (with sensible defaults for imports)
        isSerialTracked: _safeGetBool(row, 21, defaultValue: false),
        serialNumberPrefix: _safeGetOptionalString(row, 22),
        serialNumberLength: _safeGetOptionalInt(row, 23),
        serialFormat: _safeGetSerialFormat(row, 24),
        // Note: Serial numbers would be imported separately or parsed from the list
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Row $rowNumber parsing error: $e');
    }
  }

  // ✅ NEW - Helper methods for serial number parsing
  bool _safeGetBool(List<dynamic> row, int index, {bool defaultValue = false}) {
    if (index >= row.length) return defaultValue;
    final value = row[index]?.toString().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  SerialNumberFormat _safeGetSerialFormat(List<dynamic> row, int index) {
    if (index >= row.length) return SerialNumberFormat.numeric;
    final value = row[index]?.toString().toLowerCase() ?? 'numeric';
    return SerialNumberFormat.values.firstWhere(
          (format) => format.name == value,
      orElse: () => SerialNumberFormat.numeric,
    );
  }

  // ✅ Existing helper methods (unchanged)
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

// ✅ NEW - Barcode options for serial numbers
enum SerialNumberBarcodeOption {
  skuOnly,      // Just the SKU (7073)
  serialOnly,   // Just the serial number (SN001234)
  combined,     // SKU + Serial (7073-SN001234)
}
