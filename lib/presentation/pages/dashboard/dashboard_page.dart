// ✅ presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/stock_management_service.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/analytics_tab.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    InventoryRefreshNotifier().addListener(_refreshInventory);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderBloc>().add(LoadOrders());
      context.read<InventoryBloc>().add(LoadInventoryItems());
    });
  }

  @override
  void dispose() {
    InventoryRefreshNotifier().removeListener(_refreshInventory);
    _tabController.dispose();
    super.dispose();
  }

  void _refreshInventory() {
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
          InventoryTab(),
          OrdersTab(),
          AnalyticsTab(),
        ],
      ),
    );
  }
}
