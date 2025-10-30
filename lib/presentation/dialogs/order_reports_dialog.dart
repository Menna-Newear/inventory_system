// ✅ presentation/widgets/order/dialogs/order_reports_dialog.dart (FIXED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/order.dart';
import '../blocs/order/order_bloc.dart';
import '../blocs/order/order_state.dart';

class OrderReportsDialog extends StatefulWidget {
  @override
  State<OrderReportsDialog> createState() => _OrderReportsDialogState();
}

class _OrderReportsDialogState extends State<OrderReportsDialog> {
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    if (state is OrderLoaded) {
                      return _buildReportsContent(
                        state.orders,
                        theme,
                        isDark,
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
            _buildFooter(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple,
            Colors.purple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.purple.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bar_chart,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'reports_dialog.title'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'reports_dialog.subtitle'.tr(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent(
      List<Order> orders,
      ThemeData theme,
      bool isDark,
      ) {
    // ✅ FIXED: Use the correct OrderStatus enum values from your order_state.dart
    // Your OrderStatus enum has: draft, pending, approved, rejected

    // Calculate statistics
    final totalOrders = orders.length;
    final totalRevenue = orders.fold<double>(
      0,
          (sum, order) => sum + order.totalAmount,
    );
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    // ✅ FIXED: Use 'approved' instead of 'completed'
    final approvedOrders =
        orders.where((o) => o.status == OrderStatus.approved).length;

    // ✅ FIXED: Combine draft and pending for "pending" count
    final pendingOrders = orders.where((o) =>
    o.status == OrderStatus.draft ||
        o.status == OrderStatus.pending
    ).length;

    final rejectedOrders =
        orders.where((o) => o.status == OrderStatus.rejected).length;

    final rentalOrders =
        orders.where((o) => o.orderType == OrderType.rental).length;
    final sellOrders =
        orders.where((o) => o.orderType == OrderType.sell).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key metrics row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'reports_dialog.total_orders'.tr(),
                totalOrders.toString(),
                Colors.blue,
                Icons.shopping_cart,
                isDark,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'reports_dialog.total_revenue'.tr(),
                '\$${totalRevenue.toStringAsFixed(2)}',
                Colors.green,
                Icons.attach_money,
                isDark,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'reports_dialog.average_order_value'.tr(),
                '\$${averageOrderValue.toStringAsFixed(2)}',
                Colors.orange,
                Icons.trending_up,
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Status distribution
        Text(
          'Order Status Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                // ✅ FIXED: Use 'Approved' instead of 'Completed'
                'reports_dialog.approved'.tr(),
                approvedOrders,
                Colors.green,
                isDark,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'reports_dialog.pending'.tr(),
                pendingOrders,
                Colors.orange,
                isDark,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'reports_dialog.rejected'.tr(),
                rejectedOrders,
                Colors.red,
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Order type distribution
        Text(
          'Order Type Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                'reports_dialog.rental_orders'.tr(),
                rentalOrders,
                Colors.purple,
                isDark,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                'reports_dialog.sell_orders'.tr(),
                sellOrders,
                Colors.teal,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String label,
      String value,
      Color color,
      IconData icon,
      bool isDark,
      ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      String label,
      int count,
      Color color,
      bool isDark,
      ) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
      String label,
      int count,
      Color color,
      bool isDark,
      ) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            label: Text('reports_dialog.close'.tr()),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
