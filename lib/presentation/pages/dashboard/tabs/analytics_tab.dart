// ✅ presentation/pages/dashboard/tabs/analytics_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/order/order_bloc.dart';
import '../../../blocs/order/order_state.dart';
import '../../../widgets/inventory/inventory_stats_cards.dart';
import '../../../widgets/order/order_stats_cards.dart';
import '../../../widgets/inventory/import_export_dialog.dart';
import '../../../widgets/order/create_order_dialog.dart';
import '../../inventory/add_edit_item_dialog.dart';

class AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: 24),
          _buildAnalyticsSection('Inventory Overview', Icons.inventory_2, Colors.blue, InventoryStatsCards()),
          SizedBox(height: 24),
          _buildAnalyticsSection('Orders Overview', Icons.shopping_cart, Colors.green, OrderStatsCards()),
          SizedBox(height: 24),
          _buildCombinedMetrics(context),
          SizedBox(height: 24),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.analytics, size: 32, color: Theme.of(context).primaryColor),
        SizedBox(width: 12),
        Text(
          'Business Analytics Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(String title, IconData icon, Color color, Widget content) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildCombinedMetrics(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.purple),
                SizedBox(width: 8),
                Text('Business Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<InventoryBloc, InventoryState>(
                    builder: (context, inventoryState) {
                      return BlocBuilder<OrderBloc, OrderState>(
                        builder: (context, orderState) {
                          String turnoverText = 'Loading...';
                          if (inventoryState is InventoryLoaded && orderState is OrderLoaded) {
                            final turnoverRate = inventoryState.totalItems > 0
                                ? (orderState.totalOrders / inventoryState.totalItems * 100).toStringAsFixed(1)
                                : '0.0';
                            turnoverText = '$turnoverRate%';
                          }
                          return _buildMetricTile('Inventory Turnover', turnoverText, Icons.refresh, Colors.indigo);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, state) {
                      String fulfillmentText = 'Loading...';
                      if (state is OrderLoaded) {
                        final fulfillmentRate = state.totalOrders > 0
                            ? (state.approvedOrders / state.totalOrders * 100).toStringAsFixed(1)
                            : '0.0';
                        fulfillmentText = '$fulfillmentRate%';
                      }
                      return _buildMetricTile('Order Fulfillment Rate', fulfillmentText, Icons.check_circle, Colors.teal);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber[700]),
                SizedBox(width: 8),
                Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[700])),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton(context, 'Add Item', Icons.add_box, Colors.blue, () {
                  showDialog(context: context, barrierDismissible: false, builder: (_) => AddEditItemDialog());
                }),
                _buildQuickActionButton(context, 'Create Order', Icons.add_shopping_cart, Colors.green, () {
                  showDialog(context: context, barrierDismissible: false, builder: (_) => CreateOrderDialog());
                }),
                _buildQuickActionButton(context, 'Import Data', Icons.upload, Colors.purple, () {
                  showDialog(context: context, builder: (_) => ImportExportDialog());
                }),
                _buildQuickActionButton(context, 'Export Reports', Icons.download, Colors.orange, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export feature coming soon!'), backgroundColor: Colors.blue),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
