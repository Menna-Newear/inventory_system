// ✅ presentation/widgets/order/create_order_dialog.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import 'forms/customer_info_form.dart';
import 'forms/order_type_selector.dart';
import 'forms/rental_settings_form.dart';
import 'forms/item_selector_grid.dart';
import 'panels/order_summary_panel.dart';
import 'models/order_form_data.dart';

class CreateOrderDialog extends StatefulWidget {
  @override
  State<CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<CreateOrderDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Centralized form data model
  final OrderFormData _formData = OrderFormData();

  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ Responsive layout
          final isMobile = constraints.maxWidth < 900;

          return Container(
            width: isMobile
                ? constraints.maxWidth
                : 1400,
            height: isMobile
                ? constraints.maxHeight
                : 750,
            decoration: BoxDecoration(
              color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildHeader(theme, isDark),
                Expanded(
                  child: isMobile
                      ? _buildMobileLayout(theme, isDark)
                      : _buildDesktopLayout(theme, isDark),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // ✅ LEFT: Tabs (70%)
        Expanded(
          flex: 70,
          child: Column(
            children: [
              _buildTabBar(theme, isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CustomerInfoForm(formData: _formData),
                    _buildOrderDetailsTab(theme, isDark),
                    ItemSelectorGrid(
                      formData: _formData,
                      onItemsChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ Divider
        VerticalDivider(
          width: 1,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
        ),

        // ✅ RIGHT: Summary (30%)
        Expanded(
          flex: 30,
          child: OrderSummaryPanel(
            formData: _formData,
            isCreating: _isCreatingOrder,
            onCreateOrder: _createOrder,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildTabBar(theme, isDark),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              CustomerInfoForm(formData: _formData),
              _buildOrderDetailsTab(theme, isDark),
              ItemSelectorGrid(
                formData: _formData,
                onItemsChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              _formData.orderType.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'create_order_dialog.title'.tr(
                    namedArgs: {
                      'type': _formData.orderType.displayName,
                    },
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getOrderTypeDescription(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 26),
              onPressed: _handleClose,
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _getOrderTypeDescription() {
    if (_formData.orderType == OrderType.sell) {
      return 'create_order_dialog.description_sell'.tr();
    } else {
      return 'create_order_dialog.description_rental'.tr();
    }
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.primaryColor,
        unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
        indicatorColor: theme.primaryColor,
        indicatorWeight: 3,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(
            icon: Icon(Icons.person_outline),
            text: 'create_order_dialog.tab_customer'.tr(),
          ),
          Tab(
            icon: Icon(_formData.orderType.icon),
            text: 'create_order_dialog.tab_details'.tr(),
          ),
          Tab(
            icon: Icon(Icons.shopping_basket),
            text: 'create_order_dialog.tab_items'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderTypeSelector(
            selectedType: _formData.orderType,
            onTypeChanged: (type) {
              setState(() => _formData.orderType = type);
              _tabController.animateTo(1);
            },
          ),
          if (_formData.orderType == OrderType.rental) ...[
            SizedBox(height: 32),
            RentalSettingsForm(formData: _formData),
          ],
          if (_formData.orderType == OrderType.sell) ...[
            SizedBox(height: 32),
            _buildSellOrderInfo(theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildSellOrderInfo(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sell Order Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Select items from the Items tab to add them to this order. No additional configuration needed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleClose() {
    if (_formData.hasChanges) {
      _showConfirmationDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?'),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _createOrder() async {
    if (_isCreatingOrder) return;

    // ✅ Validation using form data model
    final validation = _formData.validate();
    if (!validation.isValid) {
      _showError(validation.errorMessage!);
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      // ✅ Create order from form data
      final order = _formData.toOrder();

      // ✅ Dispatch event
      context.read<OrderBloc>().add(CreateOrderEvent(order));

      await Future.delayed(Duration(seconds: 1)); // Simulate network delay

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'create_order_dialog.error_message'.tr(
            namedArgs: {'error': e.toString()},
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingOrder = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'create_order_dialog.success_message'.tr(
                  namedArgs: {
                    'type': _formData.orderType.displayName,
                  },
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _formData.dispose();
    super.dispose();
  }
}
