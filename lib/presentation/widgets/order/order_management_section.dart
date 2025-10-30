// ✅ presentation/widgets/order/sections/order_management_section.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';

import '../../dialogs/order_reports_dialog.dart';
import 'create_order_dialog.dart';
import 'order_filter_panel.dart';
import 'orders_data_table.dart';

class OrderManagementSection extends StatefulWidget {
  @override
  State<OrderManagementSection> createState() => _OrderManagementSectionState();
}

class _OrderManagementSectionState extends State<OrderManagementSection> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load orders when the section initializes
    context.read<OrderBloc>().add(LoadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(theme, isDark),
        Expanded(
          child: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderLoading) {
                return _buildLoadingView(theme);
              } else if (state is OrderLoaded) {
                return _buildOrdersView(state, theme, isDark);
              } else if (state is OrderError) {
                return _buildErrorView(state, theme);
              }
              return _buildInitializeView(theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Search bar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'order_management.search_hint'.tr(),
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
          ),

          SizedBox(width: 12),

          // ✅ Filters button
          OutlinedButton.icon(
            onPressed: _showFiltersDialog,
            icon: Icon(Icons.filter_list),
            label: Text('order_management.filters_button'.tr()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              foregroundColor: theme.primaryColor,
              side: BorderSide(color: theme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          SizedBox(width: 12),

          // ✅ Reports button
          ElevatedButton.icon(
            onPressed: _showReportsDialog,
            icon: Icon(Icons.bar_chart),
            label: Text('order_management.reports_button'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          SizedBox(width: 12),

          // ✅ New Order button
          ElevatedButton.icon(
            onPressed: _showCreateOrderDialog,
            icon: Icon(Icons.add_shopping_cart),
            label: Text('order_management.new_order_button'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'order_management.loading'.tr(),
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersView(
      OrderLoaded state,
      ThemeData theme,
      bool isDark,
      ) {
    // ✅ Filter orders based on search query
    final filteredOrders = _searchQuery.isEmpty
        ? state.orders
        : state.orders.where((order) {
      final query = _searchQuery.toLowerCase();
      return order.orderNumber.toLowerCase().contains(query) ||
          (order.customerName?.toLowerCase().contains(query) ?? false) ||
          (order.customerEmail?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filteredOrders.isEmpty) {
      return _buildEmptyView(theme, isDark);
    }

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: OrdersDataTable(orders: filteredOrders),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.primaryColor.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? 'order_management.no_orders'.tr()
                : 'order_management.no_search_results'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: Icon(Icons.clear),
              label: Text('order_management.clear_search'.tr()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(OrderError state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'order_management.error_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              state.message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
            icon: Icon(Icons.refresh),
            label: Text('order_management.retry_button'.tr()),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializeView(ThemeData theme) {
    return Center(
      child: Text(
        'order_management.initialize'.tr(),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  void _showCreateOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateOrderDialog(),
    );
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        initialChildSize: 0.75,
        builder: (context, scrollController) => OrderFilterPanel(
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => OrderReportsDialog(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
