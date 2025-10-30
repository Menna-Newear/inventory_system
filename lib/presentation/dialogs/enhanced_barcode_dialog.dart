// presentation/dialogs/enhanced_barcode_dialog.dart (FULLY LOCALIZED!)
import 'dart:typed_data';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/inventory_item.dart';
import '../../data/services/barcode_service.dart';

class EnhancedBarcodeDialog extends StatefulWidget {
  final InventoryItem item;

  const EnhancedBarcodeDialog({Key? key, required this.item}) : super(key: key);

  @override
  State<EnhancedBarcodeDialog> createState() => _EnhancedBarcodeDialogState();
}

class _EnhancedBarcodeDialogState extends State<EnhancedBarcodeDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final BarcodeService _barcodeService = BarcodeService();
  bool _isProcessing = false;

  String _selectedSymbologyType = 'Code128';

  final List<BarcodeSymbologyOption> _symbologyOptions = [
    BarcodeSymbologyOption('Code 128', 'Code128'),
    BarcodeSymbologyOption('EAN-13', 'EAN13'),
    BarcodeSymbologyOption('EAN-8', 'EAN8'),
    BarcodeSymbologyOption('Code 39', 'Code39'),
    BarcodeSymbologyOption('Code 93', 'Code93'),
    BarcodeSymbologyOption('UPC-A', 'UPCA'),
    BarcodeSymbologyOption('UPC-E', 'UPCE'),
    BarcodeSymbologyOption('Codabar', 'Codabar'),
    BarcodeSymbologyOption('QR Code', 'QRCode'),
    BarcodeSymbologyOption('Data Matrix', 'DataMatrix'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 550,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 550,
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              SizedBox(height: 16),
              _buildSymbologySelector(),
              SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildBarcodeContent(context),
                ),
              ),
              SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.barcode_reader,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'barcode.title'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${'barcode.for'.tr()} ${widget.item.nameEn}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSymbologySelector() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'barcode.barcode_type'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedSymbologyType,
            isExpanded: true,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedSymbologyType = newValue;
                });
              }
            },
            items: _symbologyOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option.symbologyType,
                child: Text(option.displayName),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: _getBarcodeHeight(),
                    width: _getSmallBarcodeWidth(),
                    child: SfBarcodeGenerator(
                      value: _getBarcodeData(),
                      symbology: _getSymbologyInstance(),
                      showValue: true,
                      textSpacing: 5,
                      barColor: Colors.black,
                      backgroundColor: Colors.white,
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.nameEn,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.item.nameAr.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    widget.item.nameAr,
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildInfoChip('${'barcode.sku'.tr()} ${widget.item.sku}'),
                    if (widget.item.unitPrice != null)
                      _buildInfoChip(
                        '\$${widget.item.unitPrice!.toStringAsFixed(2)}',
                      ),
                    _buildInfoChip('${'barcode.stock'.tr()} ${widget.item.stockQuantity}'),
                    _buildInfoChip('${'barcode.type'.tr()} ${_getSymbologyDisplayName()}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  dynamic _getSymbologyInstance() {
    switch (_selectedSymbologyType) {
      case 'Code128':
        return Code128();
      case 'EAN13':
        return EAN13();
      case 'EAN8':
        return EAN8();
      case 'Code39':
        return Code39();
      case 'Code93':
        return Code93();
      case 'UPCA':
        return UPCA();
      case 'UPCE':
        return UPCE();
      case 'Codabar':
        return Codabar();
      case 'QRCode':
        return QRCode();
      case 'DataMatrix':
        return DataMatrix();
      default:
        return Code128();
    }
  }

  String _getBarcodeData() {
    return _barcodeService.generateBarcodeData(widget.item, _getSymbologyInstance());
  }

  double _getBarcodeHeight() {
    switch (_selectedSymbologyType) {
      case 'QRCode':
      case 'DataMatrix':
        return 80.0;
      case 'EAN13':
      case 'EAN8':
      case 'UPCA':
      case 'UPCE':
        return 60.0;
      default:
        return 50.0;
    }
  }

  double _getSmallBarcodeWidth() {
    switch (_selectedSymbologyType) {
      case 'QRCode':
      case 'DataMatrix':
        return 60.0;
      case 'EAN13':
      case 'UPCA':
        return 120.0;
      case 'EAN8':
      case 'UPCE':
        return 80.0;
      default:
        return 150.0;
    }
  }

  String _getSymbologyDisplayName() {
    return _symbologyOptions
        .firstWhere(
          (option) => option.symbologyType == _selectedSymbologyType,
      orElse: () => BarcodeSymbologyOption('Unknown', 'Code128'),
    )
        .displayName;
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (_isProcessing) {
      return Container(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          'barcode.save'.tr(),
          Icons.download,
          Colors.green,
              () => _saveBarcode(context),
        ),
        _buildActionButton(
          context,
          'barcode.print'.tr(),
          Icons.print,
          Colors.purple,
              () => _printLabel(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Icon(icon, size: 18),
          ),
        ),
        SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _copyBarcodeData(BuildContext context) {
    final barcodeData = _getBarcodeData();
    Clipboard.setData(ClipboardData(text: barcodeData));
    _showSnackBar(
      context,
      'barcode.barcode_copied'.tr(),
      Colors.green,
      Icons.check_circle,
    );
  }

  Future<void> _saveBarcode(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar(
          context,
          'barcode.storage_permission_required'.tr(),
          Colors.red,
          Icons.error,
        );
        return;
      }

      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        throw Exception('barcode.failed_capture'.tr());
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('barcode.storage_access_failed'.tr());
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'barcode_${widget.item.sku}_$timestamp.png';
      final filePath = '${directory.path}/$filename';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      _showSnackBar(
        context,
        'barcode.barcode_saved'.tr(namedArgs: {'filename': filename}),
        Colors.green,
        Icons.check_circle,
      );

      _showSaveSuccessDialog(context, filePath);
    } catch (e) {
      _showSnackBar(
        context,
        'barcode.save_failed'.tr(namedArgs: {'error': e.toString()}),
        Colors.red,
        Icons.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _printLabel(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final Uint8List? barcodeImageBytes = await _screenshotController.capture(
        delay: Duration(milliseconds: 100),
        pixelRatio: 4.0,
      );

      if (barcodeImageBytes == null) {
        throw Exception('barcode.failed_capture_print'.tr());
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Center(
                  child: pw.Container(
                    width: 250,
                    height: 150,
                    child: pw.Image(
                      pw.MemoryImage(barcodeImageBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      _buildPdfRow('barcode.item'.tr(), widget.item.nameEn),
                      if (widget.item.nameAr.isNotEmpty)
                        _buildPdfRow('barcode.arabic'.tr(), widget.item.nameAr),
                      _buildPdfRow('barcode.sku'.tr(), widget.item.sku),
                      if (widget.item.unitPrice != null)
                        _buildPdfRow(
                          'barcode.price'.tr(),
                          '\$${widget.item.unitPrice!.toStringAsFixed(2)}',
                        ),
                      _buildPdfRow('barcode.stock'.tr(), '${widget.item.stockQuantity}'),
                      _buildPdfRow('barcode.type'.tr(), _getSymbologyDisplayName()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Barcode_${widget.item.sku}',
      );

      _showSnackBar(
        context,
        'barcode.print_dialog_opened'.tr(),
        Colors.purple,
        Icons.print,
      );
    } catch (e) {
      _showSnackBar(
        context,
        'barcode.print_failed'.tr(namedArgs: {'error': e.toString()}),
        Colors.red,
        Icons.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Container(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  Future<void> _shareBarcode(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        throw Exception('barcode.failed_capture_share'.tr());
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'barcode_${widget.item.sku}_$timestamp.png';
      final filePath = '${directory.path}/$filename';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Barcode: ${widget.item.nameEn}\nSKU: ${widget.item.sku}',
        subject: 'Inventory Barcode',
      );
    } catch (e) {
      _showSnackBar(
        context,
        'barcode.share_failed'.tr(namedArgs: {'error': e.toString()}),
        Colors.red,
        Icons.error,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSaveSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('barcode.saved_title'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('barcode.saved_to'.tr()),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filePath,
                style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.green),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('barcode.ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
      BuildContext context,
      String message,
      Color backgroundColor,
      IconData icon,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class BarcodeSymbologyOption {
  final String displayName;
  final String symbologyType;

  BarcodeSymbologyOption(this.displayName, this.symbologyType);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarcodeSymbologyOption &&
        other.displayName == displayName &&
        other.symbologyType == symbologyType;
  }

  @override
  int get hashCode => displayName.hashCode ^ symbologyType.hashCode;

  @override
  String toString() => 'BarcodeSymbologyOption($displayName, $symbologyType)';
}
