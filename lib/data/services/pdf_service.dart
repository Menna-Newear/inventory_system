// ✅ Create: lib/services/pdf_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/order.dart';

class PDFService {
  static Future<void> generateOrderPDF(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(order),
            pw.SizedBox(height: 30),
            _buildCustomerInfo(order),
            pw.SizedBox(height: 30),
            _buildItemsTable(order),
            pw.SizedBox(height: 30),
            _buildTotal(order),
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save and share the PDF [web:777]
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Order_${order.orderNumber}.pdf',
    );
  }

  static pw.Widget _buildHeader(Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ORDER INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Order #: ${order.orderNumber}'),
                pw.Text('Date: ${_formatDate(order.createdAt)}'),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    order.status.displayName,
                    style: pw.TextStyle(
                      color: PdfColors.green800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CUSTOMER INFORMATION',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Name: ${order.customerName ?? 'N/A'}'),
        if (order.customerEmail != null)
          pw.Text('Email: ${order.customerEmail}'),
        if (order.customerPhone != null)
          pw.Text('Phone: ${order.customerPhone}'),
        if (order.shippingAddress != null) ...[
          pw.SizedBox(height: 5),
          pw.Text('Shipping Address:'),
          pw.Text('${order.shippingAddress}'),
        ],
      ],
    );
  }

  static pw.Widget _buildItemsTable(Order order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ORDER ITEMS',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Item Name', isHeader: true),
                _buildTableCell('SKU', isHeader: true),
                _buildTableCell('Qty', isHeader: true),
                _buildTableCell('Unit Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Data rows
            ...order.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.itemName),
                _buildTableCell(item.itemSku),
                _buildTableCell('${item.quantity}'),
                _buildTableCell('\$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}'),
                _buildTableCell('\$${item.totalPrice?.toStringAsFixed(2) ?? '0.00'}'),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
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

  static pw.Widget _buildTotal(Order order) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        padding: pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          border: pw.Border.all(color: PdfColors.green),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Items:'),
                pw.Text('${order.items.length}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Quantity:'),
                pw.Text('${order.items.fold(0, (sum, item) => sum + item.quantity)}'),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL AMOUNT:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
        ),
        pw.Text(
          'Generated on ${_formatDate(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
