// ✅ presentation/widgets/order/orders_data_table.dart (FULLY LOCALIZED & ENHANCED! PART 1)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/pdf_service.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../dialogs/order_details_dialog.dart';

class OrdersDataTable extends StatelessWidget {
  final List<Order> orders;

  const OrdersDataTable({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 50,
              dataRowHeight: 60,
              columns: [
                _buildDataColumn('orders_table.order_number'.tr()),
                _buildDataColumn('orders_table.type'.tr()),
                _buildDataColumn('orders_table.customer'.tr()),
                _buildDataColumn('orders_table.status'.tr()),
                _buildDataColumn('orders_table.items'.tr(), numeric: true),
                _buildDataColumn('orders_table.amount'.tr(), numeric: true),
                _buildDataColumn('orders_table.created'.tr()),
                if (_hasRentalOrders())
                  _buildDataColumn('orders_table.rental_info'.tr()),
                _buildDataColumn('orders_table.actions'.tr()),
              ],
              rows: orders
                  .map((order) => DataRow(
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

                  // Order Type
                  DataCell(_buildOrderTypeChip(
                    order.orderType.displayName,
                    order.orderType.typeColor,
                    icon: order.orderType.icon,
                  )),

                  // Customer
                  DataCell(
                    Container(
                      width: 120,
                      child: Text(
                        order.customerName ??
                            'orders_table.unknown_customer'.tr(),
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),

                  // Status Dropdown
                  DataCell(_buildStatusDropdown(context, order)),

                  // Items Count
                  DataCell(_buildItemsCell(order)),

                  // Total Amount
                  DataCell(_buildAmountCell(order)),

                  // Created Date
                  DataCell(_buildCreatedCell(order)),

                  // Rental Info
                  if (_hasRentalOrders())
                    DataCell(_buildRentalInfoCell(order)),

                  // Actions
                  DataCell(_buildActionsCell(context, order)),
                ],
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label, {bool numeric = false}) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      numeric: numeric,
    );
  }

  Widget _buildOrderTypeChip(
      String label,
      Color color, {
        IconData? icon,
      }) {
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
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
          ],
          Text(
            label,
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

  Widget _buildItemsCell(Order order) {
    return Container(
      width: 100,
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
                    '(${order.items.fold(0, (sum, item) => sum + item.quantity)} '
                        '${order.items.fold(0, (sum, item) => sum + item.quantity) == 1 ? 'orders_table.qty'.tr() : 'orders_table.qty'.tr()})',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCell(Order order) {
    return Container(
      width: 120,
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
          if (order.isRental &&
              order.dailyRate != null &&
              order.rentalDurationDays != null)
            Text(
              '\$${order.dailyRate!.toStringAsFixed(2)}/day × ${order.rentalDurationDays}'
                  '${order.rentalDurationDays == 1 ? 'd' : 'd'}',
              style: TextStyle(fontSize: 9, color: Colors.purple[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildCreatedCell(Order order) {
    return Container(
      width: 120,
      height: 50,
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
            '${'orders_table.by'.tr()} ${order.createdByName ?? order.createdBy}',
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRentalInfoCell(Order order) {
    if (!order.isRental) {
      return Container(
        width: 100,
        height: 50,
        child: Center(
          child: Text('orders_table.n_a'.tr(),
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      width: 140,
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.rentalStartDate != null && order.rentalEndDate != null)
            Text(
              '${_formatDateShort(order.rentalStartDate!)} - '
                  '${_formatDateShort(order.rentalEndDate!)}',
              style: TextStyle(fontSize: 9, color: Colors.purple[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (order.rentalDurationDays != null)
            Text(
              '${order.rentalDurationDays} '
                  '${order.rentalDurationDays == 1 ? 'orders_table.day'.tr() : 'orders_table.days'.tr()}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
          Container(
            margin: EdgeInsets.only(top: 4),
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

  Widget _buildStatusDropdown(BuildContext context, Order order) {
    return Container(
      width: 130,
      height: 40,
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
          items: OrderStatus.values
              .map<DropdownMenuItem<OrderStatus>>((OrderStatus status) {
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

  Widget _buildActionsCell(BuildContext context, Order order) {
    return Container(
      width: 140,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'orders_table.generate_pdf'.tr(),
            child: IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 18),
              onPressed: () => _generateOrderPDF(context, order),
              splashRadius: 16,
            ),
          ),
          Tooltip(
            message: 'orders_table.view_details'.tr(),
            child: IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue[600], size: 18),
              onPressed: () => _viewOrderDetails(context, order),
              splashRadius: 16,
            ),
          ),
          if (order.isRental &&
              order.status == OrderStatus.approved &&
              !order.isRentalOverdue)
            Tooltip(
              message: 'orders_table.return_btn'.tr(),
              child: IconButton(
                icon: Icon(Icons.assignment_return,
                    color: Colors.orange[600], size: 18),
                onPressed: () => _returnRental(context, order),
                splashRadius: 16,
              ),
            ),
        ],
      ),
    );
  }

  void _changeOrderStatus(
      BuildContext context,
      Order order,
      OrderStatus newStatus,
      ) {
    if (newStatus == OrderStatus.rejected) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('orders_table.confirm_status_change'.tr()),
            content: Text(
              'orders_table.are_you_sure_status_change'.tr(
                namedArgs: {'status': newStatus.displayName},
              ),
            ),
            actions: [
              TextButton(
                child: Text('orders_table.cancel'.tr()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text('orders_table.confirm'.tr()),
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

  void _updateOrderStatus(
      BuildContext context,
      Order order,
      OrderStatus newStatus,
      ) {
    context.read<OrderBloc>().add(UpdateOrderStatusEvent(
      orderId: order.id,
      newStatus: newStatus,
    ));

    Future.delayed(Duration(seconds: 2), () {
      if (context.mounted) {
        context.read<OrderBloc>().add(RefreshSingleOrder(order.id));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('orders_table.updating'.tr()),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _returnRental(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('orders_table.return_rental'.tr()),
          content: Text('orders_table.return_rental_confirm'.tr()),
          actions: [
            TextButton(
              child: Text('orders_table.cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('orders_table.return_restore_stock'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();

                context.read<OrderBloc>().add(ReturnRentalEvent(order.id));

                Future.delayed(Duration(seconds: 2), () {
                  if (context.mounted) {
                    context.read<OrderBloc>().add(RefreshSingleOrder(order.id));
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('orders_table.returning_rental'.tr()),
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

  void _generateOrderPDF(BuildContext context, Order order) async {
    if (!context.mounted) return;

    try {
      await PDFService.generateOrderPDF(order);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'orders_table.pdf_success'.tr(
                namedArgs: {'order': order.orderNumber},
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'orders_table.pdf_error'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(order: order),
    );
  }

  bool _hasRentalOrders() {
    return orders.any((order) => order.orderType == OrderType.rental);
  }

  Color _getRentalStatusColor(Order order) {
    if (!order.isRental) return Colors.grey;
    if (order.isRentalActive) return Colors.green;
    if (order.isRentalOverdue) return Colors.red;
    if (order.status == OrderStatus.returned) return Colors.blue;
    return Colors.orange;
  }

  String _getRentalStatusText(Order order) {
    if (!order.isRental) return 'orders_table.n_a'.tr();
    if (order.isRentalActive) return 'orders_table.active'.tr();
    if (order.isRentalOverdue) return 'orders_table.overdue'.tr();
    if (order.status == OrderStatus.returned)
      return 'orders_table.returned'.tr();
    return 'orders_table.scheduled'.tr();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}
