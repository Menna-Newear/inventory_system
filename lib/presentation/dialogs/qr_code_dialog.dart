// presentation/dialogs/enhanced_qr_code_dialog.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_system/data/services/qr_code_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/inventory_item.dart';
import '../widgets/inventory/qr_code_widget.dart';

class EnhancedQrCodeDialog extends StatefulWidget {
  final InventoryItem item;

  const EnhancedQrCodeDialog({Key? key, required this.item}) : super(key: key);

  @override
  State<EnhancedQrCodeDialog> createState() => _EnhancedQrCodeDialogState();
}

class _EnhancedQrCodeDialogState extends State<EnhancedQrCodeDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, // ✅ REDUCED to 85%
          maxWidth: 500,
        ),
        child: Padding(
          padding: EdgeInsets.all(20), // ✅ REDUCED padding from 24 to 20
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ FIXED - Header (Fixed size)
              _buildHeader(context),

              SizedBox(height: 16), // ✅ REDUCED from 24 to 16

              // ✅ FIXED - Scrollable content area
              Flexible(
                child: SingleChildScrollView(
                  child: _buildQrContent(context),
                ),
              ),

              SizedBox(height: 16), // ✅ REDUCED from 24 to 16

              // ✅ FIXED - Action buttons (Fixed size)
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
            Icons.qr_code_2,
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
                'Enhanced QR Code',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1, // ✅ PREVENT overflow
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'for ${widget.item.nameEn}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                maxLines: 1, // ✅ PREVENT overflow
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

  Widget _buildQrContent(BuildContext context) {
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
          // ✅ Screenshot only wraps QR Code Widget
          Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: EdgeInsets.all(12), // ✅ REDUCED padding
              color: Colors.white,
              child: EnhancedQrCodeWidget(
                item: widget.item,
                size: 200, // ✅ REDUCED from 250 to 200
                showControls: false,
              ),
            ),
          ),

          SizedBox(height: 12), // ✅ REDUCED spacing

          // Item Info (not captured in screenshot)
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
                    fontSize: 15, // ✅ REDUCED from 16
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // ✅ LIMIT lines
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.item.nameAr.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    widget.item.nameAr,
                    style: TextStyle(fontSize: 13), // ✅ REDUCED from 14
                    textAlign: TextAlign.center,
                    maxLines: 2, // ✅ LIMIT lines
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 8),
                // ✅ Use Wrap to prevent horizontal overflow
                Wrap(
                  spacing: 6, // ✅ REDUCED spacing
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildInfoChip('SKU: ${widget.item.sku}'),
                    if (widget.item.unitPrice != null)
                      _buildInfoChip(
                        '\$${widget.item.unitPrice!.toStringAsFixed(2)}',
                      ),
                    _buildInfoChip('Stock: ${widget.item.stockQuantity}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // ✅ REDUCED padding
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10), // ✅ REDUCED radius
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11, // ✅ REDUCED from 12
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (_isProcessing) {
      return Container(
        height: 60, // ✅ FIXED height for loading state
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          'Copy',
          Icons.copy,
          Colors.blue,
              () => _copyQrData(context),
        ),
        _buildActionButton(
          context,
          'Save',
          Icons.download,
          Colors.green,
              () => _saveQrCode(context),
        ),
        _buildActionButton(
          context,
          'Print',
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
          width: 42, // ✅ REDUCED from 48
          height: 42,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // ✅ REDUCED radius
              ),
              elevation: 0,
            ),
            child: Icon(icon, size: 18), // ✅ REDUCED from 20
          ),
        ),
        SizedBox(height: 3), // ✅ REDUCED from 4
        Text(
          label,
          style: TextStyle(
            fontSize: 9, // ✅ REDUCED from 10
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1, // ✅ PREVENT overflow
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ✅ All your existing methods remain the same
  void _copyQrData(BuildContext context) {
    final qrService = EnhancedQrCodeService();
    final qrData = qrService.generateQrData(widget.item);

    Clipboard.setData(ClipboardData(text: qrData));
    _showSnackBar(
      context,
      'QR code data copied to clipboard',
      Colors.green,
      Icons.check_circle,
    );
  }

  Future<void> _saveQrCode(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar(
          context,
          'Storage permission required',
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
        throw Exception('Failed to capture QR code');
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'qr_${widget.item.sku}_$timestamp.png';
      final filePath = '${directory.path}/$filename';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      _showSnackBar(
        context,
        'QR saved: $filename',
        Colors.green,
        Icons.check_circle,
      );

      _showSaveSuccessDialog(context, filePath);
    } catch (e) {
      _showSnackBar(
        context,
        'Save failed: ${e.toString()}',
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
      final Uint8List? qrImageBytes = await _screenshotController.capture(
        delay: Duration(milliseconds: 100),
        pixelRatio: 4.0,
      );

      if (qrImageBytes == null) {
        throw Exception('Failed to capture QR code');
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
                pw.Text(
                  'Inventory Item Label',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Container(
                    width: 200,
                    height: 200,
                    child: pw.Image(
                      pw.MemoryImage(qrImageBytes),
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
                      _buildPdfRow('Item:', widget.item.nameEn),
                      if (widget.item.nameAr.isNotEmpty)
                        _buildPdfRow('Arabic:', widget.item.nameAr),
                      _buildPdfRow('SKU:', widget.item.sku),
                      if (widget.item.unitPrice != null)
                        _buildPdfRow(
                          'Price:',
                          '\$${widget.item.unitPrice!.toStringAsFixed(2)}',
                        ),
                      _buildPdfRow('Stock:', '${widget.item.stockQuantity}'),
                      _buildPdfRow('Category:', widget.item.categoryId),
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
        name: 'QR_${widget.item.sku}',
      );

      _showSnackBar(
        context,
        'Print dialog opened',
        Colors.purple,
        Icons.print,
      );
    } catch (e) {
      _showSnackBar(
        context,
        'Print failed: ${e.toString()}',
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

  Future<void> _shareQrCode(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture QR code');
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'qr_${widget.item.sku}_$timestamp.png';
      final filePath = '${directory.path}/$filename';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'QR Code: ${widget.item.nameEn}\nSKU: ${widget.item.sku}',
        subject: 'Inventory QR Code',
      );
    } catch (e) {
      _showSnackBar(
        context,
        'Share failed: ${e.toString()}',
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
            Text('Saved'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QR code saved to:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                filePath,
                style: TextStyle(fontSize: 11, fontFamily: 'monospace',color: Colors.green),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
