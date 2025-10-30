// ✅ presentation/pages/dashboard/tabs/orders_tab.dart (FULLY LOCALIZED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/order/order_bloc.dart';
import '../../../blocs/order/order_event.dart';
import '../../../blocs/order/order_state.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../../domain/entities/user.dart';
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
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<OrderBloc>().add(SetCurrentUser(authState.user));
    }

    context.read<OrderBloc>().add(LoadOrders());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final currentUser = authState is Authenticated ? authState.user : null;

        return Stack(
          children: [
            Column(
              children: [
                OrderStatsCards(),
                _buildActionBar(currentUser),
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
      },
    );
  }

  Widget _buildActionBar(User? currentUser) {
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

          _buildFilterButton(isDark),
          SizedBox(width: 8),

          if (currentUser?.hasPermission(Permission.reportsView) == true) ...[
            _buildReportsButton(isDark),
            SizedBox(width: 8),
          ],

          if (currentUser?.hasPermission(Permission.orderCreate) == true)
            _buildNewOrderButton(currentUser!, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterButton(bool isDark) {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
      icon: Icon(_showFilterPanel ? Icons.filter_alt_off : Icons.filter_alt),
      label: Text(_showFilterPanel ? 'orders_tab.hide_filters'.tr() : 'orders_tab.filters'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: _showFilterPanel
            ? (isDark ? Colors.orange[700] : Colors.orange)
            : (isDark ? Colors.grey[700] : Colors.grey[600]),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildReportsButton(bool isDark) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('orders_tab.reports_coming_soon'.tr()),
              ],
            ),
            backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: Icon(Icons.analytics),
      label: Text('orders_tab.reports'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.purple[700] : Colors.purple,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildNewOrderButton(User currentUser, bool isDark) {
    return ElevatedButton.icon(
      onPressed: () {
        if (!currentUser.hasPermission(Permission.orderCreate)) {
          _showPermissionDeniedMessage('orders_tab.permission_denied'.tr(namedArgs: {'action': 'create orders'}));
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => BlocProvider.value(
            value: context.read<OrderBloc>(),
            child: CreateOrderDialog(),
          ),
        );
      },
      icon: Icon(Icons.add_shopping_cart),
      label: Text('orders_tab.new_order'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.green[700] : Colors.green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            'orders_tab.loading_orders'.tr(),
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final canCreate = currentUser?.hasPermission(Permission.orderCreate) ?? false;

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
            'orders_tab.no_orders_found'.tr(),
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          if (canCreate) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => BlocProvider.value(
                  value: context.read<OrderBloc>(),
                  child: CreateOrderDialog(),
                ),
              ),
              icon: Icon(Icons.add_shopping_cart),
              label: Text('orders_tab.create_first_order'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.green[700] : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
            'orders_tab.error_loading_orders'.tr(),
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
            label: Text('orders_tab.retry'.tr()),
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
            'orders_tab.welcome_title'.tr(),
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<OrderBloc>().add(LoadOrders()),
            icon: Icon(Icons.refresh),
            label: Text('orders_tab.load_orders'.tr()),
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

  void _showPermissionDeniedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'orders_tab.ok'.tr(),
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
