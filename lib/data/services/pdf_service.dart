//  lib/services/pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
            // ✅ Updated to include rental info if applicable
            if (order.isRental) ...[
              _buildRentalInfo(order),
              pw.SizedBox(height: 30),
            ],
            _buildItemsTable(order),
            pw.SizedBox(height: 30),
            _buildTotal(order),
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

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
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ORDER INVOICE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                // ✅ Show order type
                pw.Text(
                  order.orderType.displayName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: order.isRental ? PdfColors.purple : PdfColors.blue,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Order #: ${order.orderNumber}'),
                pw.Text('Date: ${_formatDate(order.createdAt)}'),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    order.status.displayName,
                    style: pw.TextStyle(
                      color: PdfColors.white,
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

  // ✅ NEW: Rental information section
  static pw.Widget _buildRentalInfo(Order order) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        border: pw.Border.all(color: PdfColors.purple),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RENTAL INFORMATION',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.purple800),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Start Date: ${order.rentalStartDate != null ? _formatDate(order.rentalStartDate!) : 'N/A'}'),
                  pw.Text('End Date: ${order.rentalEndDate != null ? _formatDate(order.rentalEndDate!) : 'N/A'}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Duration: ${order.rentalDurationDays ?? 0} days'),
                  pw.Text('Daily Rate: \$${order.dailyRate?.toStringAsFixed(2) ?? '0.00'}'),
                  if (order.securityDeposit != null)
                    pw.Text('Security Deposit: \$${order.securityDeposit!.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Items table now includes serial numbers
  static pw.Widget _buildItemsTable(Order order) {
    // Check if any item has serial numbers
    final hasSerials = order.items.any((item) =>
    item.serialNumbers != null && item.serialNumbers!.isNotEmpty
    );

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
        // ✅ NEW: Show serial numbers below the table if any exist
        if (hasSerials) ...[
          pw.SizedBox(height: 20),
          _buildSerialNumbersSection(order),
        ],
      ],
    );
  }

  // ✅ NEW: Serial numbers section
  static pw.Widget _buildSerialNumbersSection(Order order) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '🔢',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'ASSIGNED SERIAL NUMBERS',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...order.items.where((item) =>
          item.serialNumbers != null && item.serialNumbers!.isNotEmpty
          ).map((item) => pw.Container(
            margin: pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${item.itemName} (${item.itemSku})',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.serialNumbers!.map((serialId) => pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.blue300),
                    ),
                    child: pw.Text(
                      serialId.length > 12 ? '${serialId.substring(0, 12)}...' : serialId,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  )).toList(),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
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
        width: 250,
        padding: pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: order.isRental ? PdfColors.purple50 : PdfColors.green50,
          border: pw.Border.all(color: order.isRental ? PdfColors.purple : PdfColors.green),
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
            // ✅ Show security deposit for rentals
            if (order.isRental && order.securityDeposit != null) ...[
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Rental Amount:'),
                  pw.Text('\$${(order.totalAmount - (order.securityDeposit ?? 0)).toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Security Deposit:'),
                  pw.Text('\$${order.securityDeposit!.toStringAsFixed(2)}'),
                ],
              ),
            ],
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

  // ✅ Helper: Get status color
  static PdfColor _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.draft:
        return PdfColors.grey;
      case OrderStatus.pending:
        return PdfColors.orange;
      case OrderStatus.approved:
        return PdfColors.green;
      case OrderStatus.rejected:
        return PdfColors.red;
      case OrderStatus.processing:
        return PdfColors.blue;
      case OrderStatus.shipped:
        return PdfColors.purple;
      case OrderStatus.delivered:
        return PdfColors.green700;
      case OrderStatus.cancelled:
        return PdfColors.red700;
      case OrderStatus.returned:
        return PdfColors.amber;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
