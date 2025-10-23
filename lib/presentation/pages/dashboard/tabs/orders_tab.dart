// ✅ presentation/pages/dashboard/tabs/orders_tab.dart (THEME-AWARE)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/order/order_bloc.dart';
import '../../../blocs/order/order_event.dart';
import '../../../blocs/order/order_state.dart';
import '../../../widgets/order/order_stats_cards.dart';
import '../../../widgets/order/order_search_bar.dart';
import '../../../widgets/order/order_filter_panel.dart';
import '../../../widgets/order/orders_data_table.dart';
import '../../../widgets/order/create_order_dialog.dart';

class OrdersTab extends StatefulWidget {
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _showFilterPanel = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            OrderStatsCards(),
            _buildActionBar(),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: _buildOrdersContent(),
              ),
            ),
          ],
        ),
        if (_showFilterPanel) _buildFilterDrawer(),
      ],
    );
  }

  Widget _buildActionBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: OrderSearchBar()),
          SizedBox(width: 16),
          _buildFilterButton(),
          SizedBox(width: 8),
          _buildReportsButton(),
          SizedBox(width: 8),
          _buildNewOrderButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
      icon: Icon(_showFilterPanel ? Icons.filter_alt_off : Icons.filter_alt),
      label: Text(_showFilterPanel ? 'Hide Filters' : 'Filters'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _showFilterPanel
            ? (isDark ? Colors.orange[700] : Colors.orange)
            : (isDark ? Colors.grey[700] : Colors.grey[600]),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildReportsButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('Order reports feature coming soon!'),
              ],
            ),
            backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: Icon(Icons.analytics),
      label: Text('Reports'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.purple[700] : Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildNewOrderButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CreateOrderDialog(),
      ),
      icon: Icon(Icons.add_shopping_cart),
      label: Text('New Order'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.green[700] : Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildOrdersContent() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return _buildLoadingState();
        } else if (state is OrderLoaded) {
          if (state.displayOrders.isEmpty) {
            return _buildEmptyState();
          }
          return SingleChildScrollView(
            child: OrdersDataTable(orders: state.displayOrders),
          );
        } else if (state is OrderError) {
          return _buildErrorState(state.message);
        }
        return _buildInitialState();
      },
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => CreateOrderDialog(),
            ),
            icon: Icon(Icons.add_shopping_cart),
            label: Text('Create First Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.green[700] : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red[400] : Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.red[400] : Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to Orders Management',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
            icon: Icon(Icons.refresh),
            label: Text('Load Orders'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDrawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _showFilterPanel = false),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 450,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.26),
                    blurRadius: 10,
                    offset: Offset(-5, 0),
                  ),
                ],
              ),
              child: OrderFilterPanel(
                onClose: () => setState(() => _showFilterPanel = false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
