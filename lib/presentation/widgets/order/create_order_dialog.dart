// ✅ presentation/widgets/order/create_order_dialog.dart (CLEAN VERSION)
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
    return Dialog(
      child: Container(
        width: 1200,
        height: 700,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                children: [
                  // ✅ LEFT: Tabs (70%)
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        _buildTabBar(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              CustomerInfoForm(formData: _formData),
                              _buildOrderDetailsTab(),
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

                  // ✅ RIGHT: Summary (30%)
                  OrderSummaryPanel(
                    formData: _formData,
                    isCreating: _isCreatingOrder,
                    onCreateOrder: _createOrder,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_formData.orderType.icon, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New ${_formData.orderType.displayName}',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(_formData.orderType.description,
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        tabs: [
          Tab(icon: Icon(Icons.person_outline), text: 'Customer'),
          Tab(icon: Icon(_formData.orderType.icon), text: 'Details'),
          Tab(icon: Icon(Icons.shopping_basket), text: 'Items'),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          OrderTypeSelector(
            selectedType: _formData.orderType,
            onTypeChanged: (type) => setState(() => _formData.orderType = type),
          ),
          SizedBox(height: 24),
          if (_formData.orderType == OrderType.rental)
            RentalSettingsForm(formData: _formData),
        ],
      ),
    );
  }

  void _createOrder() async {
    if (_isCreatingOrder) return;

    setState(() => _isCreatingOrder = true);

    try {
      // ✅ Validation using form data model
      final validation = _formData.validate();
      if (!validation.isValid) {
        _showError(validation.errorMessage!);
        return;
      }

      // ✅ Create order from form data
      final order = _formData.toOrder();

      // ✅ Dispatch event
      context.read<OrderBloc>().add(CreateOrderEvent(order));

      Navigator.of(context).pop();
      _showSuccess();

    } catch (e) {
      _showError('Failed to create order: $e');
    } finally {
      setState(() => _isCreatingOrder = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_formData.orderType.displayName} created successfully!'),
        backgroundColor: Colors.green,
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
