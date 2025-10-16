// ✅ presentation/pages/dashboard/dashboard_page.dart (UPDATED WITH REFRESH LISTENERS)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/order.dart';
import '../../../data/services/stock_management_service.dart'; // ✅ ADD THIS IMPORT
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import '../../widgets/inventory/inventory_stats_cards.dart';
import '../../widgets/inventory/inventory_search_bar.dart';
import '../../widgets/inventory/inventory_filter_panel.dart';
import '../../widgets/inventory/inventory_data_table.dart';
import '../../widgets/inventory/import_export_dialog.dart';
import '../../widgets/order/create_order_dialog.dart';
import '../../widgets/order/order_stats_cards.dart';
import '../../widgets/order/order_search_bar.dart';
import '../../widgets/order/order_filter_panel.dart';
import '../../widgets/order/orders_data_table.dart';
import '../inventory/add_edit_item_dialog.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showInventoryFilterPanel = false;
  bool _showOrderFilterPanel = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ✅ ADD THIS: Listen for inventory refresh events
    InventoryRefreshNotifier().addListener(_refreshInventory);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderBloc>().add(LoadOrders());
      // ✅ ADD THIS: Load inventory on startup
      context.read<InventoryBloc>().add(LoadInventoryItems());
    });
  }

  @override
  void dispose() {
    // ✅ ADD THIS: Remove the listener to prevent memory leaks
    InventoryRefreshNotifier().removeListener(_refreshInventory);
    _tabController.dispose();
    super.dispose();
  }

  // ✅ ADD THIS METHOD: Refresh inventory when stock changes
  void _refreshInventory() {
    print('🔄 DASHBOARD: Received inventory refresh notification - reloading inventory');
    if (mounted) {
      context.read<InventoryBloc>().add(LoadInventoryItems());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory Management System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.inventory_2), text: 'Inventory'),
            Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Orders'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventoryTab(),
          _buildOrdersTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Column(
      children: [
        InventoryStatsCards(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: InventorySearchBar()),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => setState(
                      () => _showInventoryFilterPanel = !_showInventoryFilterPanel,
                ),
                icon: Icon(
                  _showInventoryFilterPanel
                      ? Icons.filter_alt_off
                      : Icons.filter_alt,
                ),
                label: Text(
                  _showInventoryFilterPanel ? 'Hide Filters' : 'Filters',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showInventoryFilterPanel
                      ? Colors.orange
                      : Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showImportExportDialog,
                icon: Icon(Icons.import_export),
                label: Text('Import/Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: Icon(Icons.add),
                label: Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_showInventoryFilterPanel)
          InventoryFilterPanel(
            onClose: () => setState(() => _showInventoryFilterPanel = false),
          ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: InventoryDataTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        OrderStatsCards(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: OrderSearchBar()),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => setState(
                      () => _showOrderFilterPanel = !_showOrderFilterPanel,
                ),
                icon: Icon(
                  _showOrderFilterPanel
                      ? Icons.filter_alt_off
                      : Icons.filter_alt,
                ),
                label: Text(_showOrderFilterPanel ? 'Hide Filters' : 'Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showOrderFilterPanel
                      ? Colors.orange
                      : Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showOrderReports,
                icon: Icon(Icons.analytics),
                label: Text('Reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreateOrderDialog,
                icon: Icon(Icons.add_shopping_cart),
                label: Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_showOrderFilterPanel)
          OrderFilterPanel(
            onClose: () => setState(() => _showOrderFilterPanel = false),
          ),

        // ✅ Orders with BLoC handling
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading orders...'),
                      ],
                    ),
                  );
                } else if (state is OrderLoaded) {
                  if (state.displayOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateOrderDialog,
                            icon: Icon(Icons.add_shopping_cart),
                            label: Text('Create First Order'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                    );
                  }
                  return OrdersDataTable(orders: state.displayOrders);
                } else if (state is OrderError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
                          icon: Icon(Icons.refresh),
                          label: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Welcome to Orders Management'),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
                        icon: Icon(Icons.refresh),
                        label: Text('Load Orders'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 12),
              Text(
                'Business Analytics Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildAnalyticsSection(
            'Inventory Overview',
            Icons.inventory_2,
            Colors.blue,
            InventoryStatsCards(),
          ),
          SizedBox(height: 24),
          _buildAnalyticsSection(
            'Orders Overview',
            Icons.shopping_cart,
            Colors.green,
            OrderStatsCards(),
          ),
          SizedBox(height: 24),
          _buildCombinedMetrics(),
          SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(
      String title,
      IconData icon,
      Color color,
      Widget content,
      ) {
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildCombinedMetrics() {
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
                Text(
                  'Business Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
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
                          if (inventoryState is InventoryLoaded &&
                              orderState is OrderLoaded) {
                            final turnoverRate = inventoryState.totalItems > 0
                                ? (orderState.totalOrders /
                                inventoryState.totalItems *
                                100)
                                .toStringAsFixed(1)
                                : '0.0';
                            turnoverText = '$turnoverRate%';
                          }
                          return _buildMetricTile(
                            'Inventory Turnover',
                            turnoverText,
                            Icons.refresh,
                            Colors.indigo,
                          );
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
                            ? (state.approvedOrders / state.totalOrders * 100)
                            .toStringAsFixed(1)
                            : '0.0';
                        fulfillmentText = '$fulfillmentRate%';
                      }
                      return _buildMetricTile(
                        'Order Fulfillment Rate',
                        fulfillmentText,
                        Icons.check_circle,
                        Colors.teal,
                      );
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

  Widget _buildMetricTile(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      ) {
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
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton(
                  'Add Item',
                  Icons.add_box,
                  Colors.blue,
                  _showAddItemDialog,
                ),
                _buildQuickActionButton(
                  'Create Order',
                  Icons.add_shopping_cart,
                  Colors.green,
                  _showCreateOrderDialog,
                ),
                _buildQuickActionButton(
                  'Import Data',
                  Icons.upload,
                  Colors.purple,
                  _showImportExportDialog,
                ),
                _buildQuickActionButton(
                  'Export Reports',
                  Icons.download,
                  Colors.orange,
                  _showOrderReports,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
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

  void _showAddItemDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddEditItemDialog(),
    );
  }

  void _showCreateOrderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CreateOrderDialog(),
    );
  }

  void _showImportExportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => ImportExportDialog(),
    );
  }

  void _showOrderReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Order reports feature coming soon!'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
