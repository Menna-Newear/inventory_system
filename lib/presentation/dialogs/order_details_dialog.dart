// ✅ Add this as a separate file: presentation/widgets/order/dialogs/order_details_dialog.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/order.dart';
import '../../../data/services/pdf_service.dart';

class OrderDetailsDialog extends StatelessWidget {
  final Order order;

  const OrderDetailsDialog({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: _buildTitle(theme, isDark),
      content: Container(
        width: 700,
        constraints: BoxConstraints(maxHeight: 700),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              _buildStatusBadge(order, theme),

              SizedBox(height: 16),

              // Customer Info
              _buildSectionTitle('orders_table.customer_information', Icons.person, Colors.blue, theme),
              SizedBox(height: 8),
              _buildDetailRow('orders_table.customer'.tr(), order.customerName ?? 'orders_table.unknown_customer'.tr(), theme),
              if (order.customerEmail != null)
                _buildDetailRow('orders_table.email'.tr(), order.customerEmail!, theme),
              if (order.customerPhone != null)
                _buildDetailRow('orders_table.phone'.tr(), order.customerPhone!, theme),
              if (order.shippingAddress != null)
                _buildDetailRow('orders_table.address'.tr(), order.shippingAddress!, theme),

              // Rental Info
              if (order.isRental) ...[
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                _buildSectionTitle('orders_table.rental_information', Icons.access_time, Colors.purple, theme),
                SizedBox(height: 8),
                if (order.rentalStartDate != null)
                  _buildDetailRow('orders_table.start_date'.tr(), _formatDateShort(order.rentalStartDate!), theme),
                if (order.rentalEndDate != null)
                  _buildDetailRow('orders_table.end_date'.tr(), _formatDateShort(order.rentalEndDate!), theme),
                if (order.rentalDurationDays != null)
                  _buildDetailRow('orders_table.duration'.tr(), '${order.rentalDurationDays} ${'orders_table.days'.tr()}', theme),
                if (order.dailyRate != null)
                  _buildDetailRow('orders_table.daily_rate'.tr(), '\$${order.dailyRate!.toStringAsFixed(2)}', theme),
                if (order.securityDeposit != null && order.securityDeposit! > 0)
                  _buildDetailRow('orders_table.security_deposit'.tr(), '\$${order.securityDeposit!.toStringAsFixed(2)}', theme),
              ],

              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),

              // Items
              _buildSectionTitle(
                '${'orders_table.order_items'.tr()} (${order.items.length})',
                Icons.shopping_basket,
                Colors.blue[700]!,
                theme,
              ),
              SizedBox(height: 12),

              ...order.items.map((item) => _buildItemCard(item, theme, isDark)).toList(),

              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),

              // Total Summary
              _buildTotalSummary(order, theme),

              SizedBox(height: 12),

              // Created Info
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'orders_table.created_by'.tr()} ${order.createdByName ?? order.createdBy}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      '${'orders_table.created_date'.tr()} ${_formatDate(order.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('orders_table.close'.tr()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.picture_as_pdf),
          label: Text('orders_table.generate_pdf'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            try {
              await PDFService.generateOrderPDF(order);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('orders_table.pdf_success'.tr(namedArgs: {'order': order.orderNumber})),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('orders_table.pdf_error'.tr(namedArgs: {'error': e.toString()})),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Icon(order.orderType.icon, color: order.orderType.typeColor, size: 24),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '${order.orderType.displayName} - ${order.orderNumber}',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Order order, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: order.status.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: order.status.statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: order.status.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            order.status.displayName,
            style: TextStyle(
              color: order.status.statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${'orders_table.sku'.tr()} ${item.itemSku}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${item.totalPrice?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildItemChip('${'orders_table.qty_label'.tr()} ${item.quantity}', Icons.inventory_2, Colors.blue),
              SizedBox(width: 8),
              _buildItemChip('${'orders_table.unit'.tr()} \$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}', Icons.attach_money, Colors.green),
            ],
          ),
          if (item.serialNumbers != null && item.serialNumbers!.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildSerialNumbers(item.serialNumbers!),
          ],
        ],
      ),
    );
  }

  Widget _buildItemChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialNumbers(List<String> serialNumbers) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2, size: 16, color: Colors.purple[700]),
              SizedBox(width: 6),
              Text(
                '${'orders_table.assigned_serial'.tr()} (${serialNumbers.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: serialNumbers
                .map((serialId) => Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[300]!),
              ),
              child: Text(
                serialId.length > 12
                    ? '${serialId.substring(0, 12)}...'
                    : serialId,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.purple[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary(Order order, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!, width: 2),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'orders_table.total_items'.tr(),
            '${order.items.length}',
            theme,
          ),
          SizedBox(height: 4),
          _buildSummaryRow(
            'orders_table.total_quantity'.tr(),
            '${order.items.fold(0, (sum, item) => sum + item.quantity)}',
            theme,
          ),
          if (order.isRental &&
              order.securityDeposit != null &&
              order.securityDeposit! > 0) ...[
            Divider(height: 20),
            _buildSummaryRow(
              'orders_table.rental_amount'.tr(),
              '\$${(order.totalAmount - order.securityDeposit!).toStringAsFixed(2)}',
              theme,
            ),
            SizedBox(height: 4),
            _buildSummaryRow(
              'orders_table.security_deposit'.tr(),
              '\$${order.securityDeposit!.toStringAsFixed(2)}',
              theme,
            ),
          ],
          Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'orders_table.total_amount'.tr()}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}
