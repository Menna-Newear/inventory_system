// ✅ presentation/widgets/order/order_management_section.dart (COMPLETE FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import 'create_order_dialog.dart';
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
    return Column(
      children: [
        // ✅ HEADER WITH SEARCH AND NEW ORDER BUTTON
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Search bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search orders by number, customer, or email...',
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              SizedBox(width: 16),

              // Filter button
              OutlinedButton.icon(
                onPressed: _showFiltersDialog,
                icon: Icon(Icons.filter_list),
                label: Text('Filters'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              SizedBox(width: 12),

              // Reports button
              ElevatedButton.icon(
                onPressed: _showReportsDialog,
                icon: Icon(Icons.bar_chart),
                label: Text('Reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              SizedBox(width: 12),

              // New Order button
              ElevatedButton.icon(
                onPressed: _showCreateOrderDialog,
                icon: Icon(Icons.add_shopping_cart),
                label: Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // ✅ ORDERS DATA TABLE WITH BLOC BUILDER
        Expanded(
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No orders found' : 'No orders match your search',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // ✅ FIXED: Use OrdersDataTable with orders parameter
                return Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: OrdersDataTable(orders: filteredOrders), // ✅ Fixed: orders parameter provided
                );
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
                child: Text('Initialize orders loading...'),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateOrderDialog(),
    );
  }

  void _showFiltersDialog() {
    // TODO: Implement filters dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Filters'),
        content: Text('Filter functionality will be implemented here.'),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog() {
    // TODO: Implement reports dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Reports'),
        content: Text('Reports functionality will be implemented here.'),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
