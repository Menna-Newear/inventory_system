// ✅ presentation/widgets/order/orders_data_table.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/pdf_service.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';

class OrdersDataTable extends StatelessWidget {
  final List<Order> orders;

  const OrdersDataTable({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ✅ ORDERS COUNT HEADER WITH SELL/RENTAL BREAKDOWN
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Orders (${orders.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 16),
                // ✅ NEW: Show sell vs rental breakdown
                if (orders.isNotEmpty) ...[
                  _buildOrderTypeChip('Sales', _getSellOrdersCount(), Colors.blue),
                  SizedBox(width: 8),
                  _buildOrderTypeChip('Rentals', _getRentalOrdersCount(), Colors.purple),
                ],
                Spacer(),
                if (orders.isNotEmpty) ...[
                  Text(
                    'Total: \$${_calculateTotalRevenue().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ✅ DATA TABLE WITH UPDATED COLUMNS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 50,
              dataRowHeight: 50, // ✅ FIXED ROW HEIGHT
              columns: [
                DataColumn(
                  label: Text('Order #', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)), // ✅ NEW: Type column
                ),
                DataColumn(
                  label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Created', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                // ✅ NEW: Rental info column (conditional)
                if (_hasRentalOrders())
                  DataColumn(
                    label: Text('Rental Info', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                DataColumn(
                  label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: orders.map((order) => DataRow(
                cells: [
                  // Order Number
                  DataCell(
                    Container(
                      width: 140,
                      child: Text(
                        order.orderNumber,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // ✅ NEW: Order Type (Sell/Rental)
                  DataCell(_buildOrderTypeChip(
                    order.orderType.displayName,
                    null,
                    order.orderType.typeColor,
                    showIcon: true,
                    icon: order.orderType.icon,
                  )),

                  // Customer
                  DataCell(
                    Container(
                      width: 120,
                      child: Text(
                        order.customerName ?? 'Unknown',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),

                  // Status with Dropdown
                  DataCell(_buildStatusDropdown(context, order)),

                  // Items Count (✅ FIXED)
                  DataCell(
                    Container(
                      width: 80,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${order.items.length}',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                if (order.items.isNotEmpty)
                                  Text(
                                    '(${order.items.fold(0, (sum, item) => sum + item.quantity)} qty)',
                                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Total Amount
                  DataCell(
                    Container(
                      width: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${order.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 12,
                            ),
                          ),
                          // ✅ NEW: Show rental breakdown if applicable
                          if (order.isRental && order.dailyRate != null && order.rentalDurationDays != null)
                            Text(
                              '\$${order.dailyRate!.toStringAsFixed(2)}/day × ${order.rentalDurationDays}d',
                              style: TextStyle(fontSize: 9, color: Colors.purple[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ FIXED: Created Date (NO MORE OVERFLOW)
                  DataCell(
                    Container(
                      width: 100,
                      height: 45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'by ${order.createdBy}',
                            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ NEW: Rental Info (conditional column)
                  if (_hasRentalOrders())
                    DataCell(_buildRentalInfoCell(order)),

                  // Actions
                  DataCell(
                    Container(
                      width: 120,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // PDF Generation Button
                          IconButton(
                            icon: Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 18),
                            tooltip: 'Generate PDF',
                            onPressed: () => _generateOrderPDF(context, order),
                          ),
                          // View Details Button
                          IconButton(
                            icon: Icon(Icons.visibility, color: Colors.blue[600], size: 18),
                            tooltip: 'View Details',
                            onPressed: () => _viewOrderDetails(context, order),
                          ),
                          // ✅ NEW: Return rental button (for active rentals)
                          if (order.isRental &&
                              order.status == OrderStatus.approved &&
                              !order.isRentalOverdue)
                            IconButton(
                              icon: Icon(Icons.assignment_return, color: Colors.orange[600], size: 18),
                              tooltip: 'Return Rental',
                              onPressed: () => _returnRental(context, order),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Order type chip builder
  Widget _buildOrderTypeChip(String label, int? count, Color color,
      {bool showIcon = false, IconData? icon}) {
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
          if (showIcon && icon != null) ...[
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
          ],
          Text(
            count != null ? '$label ($count)' : label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Rental info cell
  Widget _buildRentalInfoCell(Order order) {
    if (!order.isRental) {
      return Container(
          width: 100,
          height: 45,
          child: Center(
              child: Text('-', style: TextStyle(color: Colors.grey))
          )
      );
    }

    return Container(
      width: 120,
      height: 45,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.rentalStartDate != null && order.rentalEndDate != null)
            Text(
              '${_formatDateShort(order.rentalStartDate!)} - ${_formatDateShort(order.rentalEndDate!)}',
              style: TextStyle(fontSize: 9, color: Colors.purple[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (order.rentalDurationDays != null)
            Text(
              '${order.rentalDurationDays} days',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple[800]),
            ),
          // ✅ Rental status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getRentalStatusColor(order).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getRentalStatusText(order),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: _getRentalStatusColor(order),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ STATUS DROPDOWN WITH CHANGE FUNCTIONALITY
  Widget _buildStatusDropdown(BuildContext context, Order order) {
    return Container(
      width: 120,
      height: 35,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: order.status.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: order.status.statusColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrderStatus>(
          value: order.status,
          isDense: true,
          isExpanded: true,
          style: TextStyle(
            color: order.status.statusColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: order.status.statusColor,
            size: 14,
          ),
          onChanged: (OrderStatus? newStatus) {
            if (newStatus != null && newStatus != order.status) {
              _changeOrderStatus(context, order, newStatus);
            }
          },
          items: OrderStatus.values.map<DropdownMenuItem<OrderStatus>>((OrderStatus status) {
            return DropdownMenuItem<OrderStatus>(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: status.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      status.displayName,
                      style: TextStyle(
                        color: status.statusColor,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ✅ STATUS CHANGE HANDLER
  void _changeOrderStatus(BuildContext context, Order order, OrderStatus newStatus) {
    // Show confirmation dialog for important status changes
    if (newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Status Change'),
            content: Text('Are you sure you want to change the order status to ${newStatus.displayName}?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text('Confirm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: newStatus.statusColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateOrderStatus(context, order, newStatus);
                },
              ),
            ],
          );
        },
      );
    } else {
      _updateOrderStatus(context, order, newStatus);
    }
  }

  void _updateOrderStatus(BuildContext context, Order order, OrderStatus newStatus) {
    // ✅ Use the new event with stock management
    context.read<OrderBloc>().add(UpdateOrderStatusEvent(
      orderId: order.id,
      newStatus: newStatus,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Updating order status and stock levels...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ✅ Update the return rental method
  void _returnRental(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Return Rental'),
          content: Text('Mark this rental as returned? This will restore the inventory stock.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Return & Restore Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();

                // ✅ Use new event for rental return
                context.read<OrderBloc>().add(ReturnRentalEvent(order.id));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Returning rental and restoring stock...'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ Updated PDF generation method
  void _generateOrderPDF(BuildContext context, Order order) async {
    // ✅ CHECK IF WIDGET IS STILL MOUNTED
    if (!context.mounted) return;

    try {
      await PDFService.generateOrderPDF(order);

      // ✅ CHECK AGAIN BEFORE SHOWING SNACKBAR
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generated successfully for order ${order.orderNumber}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ✅ CHECK AGAIN BEFORE SHOWING ERROR
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(order.orderType.icon, color: order.orderType.typeColor),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${order.orderType.displayName} - ${order.orderNumber}',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Badge
                Container(
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
                ),

                SizedBox(height: 16),

                // Customer Info
                Text('Customer Information:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                _buildDetailRow('Customer:', order.customerName ?? 'Unknown'),
                if (order.customerEmail != null)
                  _buildDetailRow('Email:', order.customerEmail!),
                if (order.customerPhone != null)
                  _buildDetailRow('Phone:', order.customerPhone!),
                if (order.shippingAddress != null)
                  _buildDetailRow('Address:', order.shippingAddress!),

                // ✅ Rental-specific info
                if (order.isRental) ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.purple[700], size: 20),
                      SizedBox(width: 8),
                      Text('Rental Information:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple[700])),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (order.rentalStartDate != null)
                    _buildDetailRow('Start Date:', _formatDateShort(order.rentalStartDate!)),
                  if (order.rentalEndDate != null)
                    _buildDetailRow('End Date:', _formatDateShort(order.rentalEndDate!)),
                  if (order.rentalDurationDays != null)
                    _buildDetailRow('Duration:', '${order.rentalDurationDays} days'),
                  if (order.dailyRate != null)
                    _buildDetailRow('Daily Rate:', '\$${order.dailyRate!.toStringAsFixed(2)}'),
                  if (order.securityDeposit != null && order.securityDeposit! > 0)
                    _buildDetailRow('Security Deposit:', '\$${order.securityDeposit!.toStringAsFixed(2)}'),
                  _buildDetailRow('Rental Status:', _getRentalStatusText(order),
                      color: _getRentalStatusColor(order)),
                ],

                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),

                // Items
                Row(
                  children: [
                    Icon(Icons.shopping_basket, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Text('Order Items (${order.items.length}):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                SizedBox(height: 12),

                // ✅ UPDATED: Items list with serial numbers
                ...order.items.map((item) => Container(
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
                                  'SKU: ${item.itemSku}',
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
                          _buildItemInfoChip('Qty: ${item.quantity}', Icons.inventory_2, Colors.blue),
                          SizedBox(width: 8),
                          _buildItemInfoChip('Unit: \$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}', Icons.attach_money, Colors.green),
                        ],
                      ),

                      // ✅ NEW: Show serial numbers if present
                      if (item.serialNumbers != null && item.serialNumbers!.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
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
                                    'Assigned Serial Numbers (${item.serialNumbers!.length})',
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
                                children: item.serialNumbers!.map((serialId) => Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purple[300]!),
                                  ),
                                  child: Text(
                                    serialId.length > 12 ? '${serialId.substring(0, 12)}...' : serialId,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.purple[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                )).toList(),

                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),

                // Total
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Items:', style: TextStyle(fontSize: 14)),
                          Text('${order.items.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Quantity:', style: TextStyle(fontSize: 14)),
                          Text('${order.items.fold(0, (sum, item) => sum + item.quantity)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (order.isRental && order.securityDeposit != null && order.securityDeposit! > 0) ...[
                        Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rental Amount:', style: TextStyle(fontSize: 14)),
                            Text('\$${(order.totalAmount - order.securityDeposit!).toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Security Deposit:', style: TextStyle(fontSize: 14)),
                            Text('\$${order.securityDeposit!.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                      Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL AMOUNT:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('\$${order.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green[700])),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Created info
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Created by: ${order.createdBy}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      Text('Date: ${_formatDate(order.createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.picture_as_pdf),
            label: Text('Generate PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _generateOrderPDF(context, order);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfoChip(String label, IconData icon, Color color) {
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ HELPER METHODS
  double _calculateTotalRevenue() {
    return orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  int _getSellOrdersCount() {
    return orders.where((order) => order.orderType == OrderType.sell).length;
  }

  int _getRentalOrdersCount() {
    return orders.where((order) => order.orderType == OrderType.rental).length;
  }

  bool _hasRentalOrders() {
    return orders.any((order) => order.orderType == OrderType.rental);
  }

  Color _getRentalStatusColor(Order order) {
    if (!order.isRental) return Colors.grey;

    if (order.isRentalActive) return Colors.green;
    if (order.isRentalOverdue) return Colors.red;
    if (order.status == OrderStatus.returned) return Colors.blue;
    return Colors.orange; // Scheduled
  }

  String _getRentalStatusText(Order order) {
    if (!order.isRental) return 'N/A';

    if (order.isRentalActive) return 'ACTIVE';
    if (order.isRentalOverdue) return 'OVERDUE';
    if (order.status == OrderStatus.returned) return 'RETURNED';
    return 'SCHEDULED';
  }

  // ✅ FIXED: Date formatting (single line to prevent overflow)
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}
