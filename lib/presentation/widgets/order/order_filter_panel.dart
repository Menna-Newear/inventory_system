// ✅ presentation/widgets/order/order_filter_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/order/order_event.dart';

class OrderFilterPanel extends StatefulWidget {
  final VoidCallback onClose;

  const OrderFilterPanel({Key? key, required this.onClose}) : super(key: key);

  @override
  State<OrderFilterPanel> createState() => _OrderFilterPanelState();
}

class _OrderFilterPanelState extends State<OrderFilterPanel> {
  OrderStatus? _selectedStatus;
  OrderType? _selectedOrderType;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();

  // ✅ NEW: Rental-specific filters
  DateTime? _rentalStartAfter;
  DateTime? _rentalStartBefore;
  DateTime? _rentalEndAfter;
  DateTime? _rentalEndBefore;
  final TextEditingController _minDailyRateController = TextEditingController();
  final TextEditingController _maxDailyRateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            _buildBasicFilters(),
            SizedBox(height: 16),
            _buildAmountFilters(),
            SizedBox(height: 16),
            _buildCustomerFilter(),
            // ✅ NEW: Show rental filters only if rental type is selected or no type selected
            if (_selectedOrderType == OrderType.rental || _selectedOrderType == null) ...[
              SizedBox(height: 16),
              _buildRentalFilters(),
            ],
            SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.filter_alt, color: Theme.of(context).primaryColor),
        SizedBox(width: 8),
        Text('Order Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            )),
        Spacer(),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onClose,
          tooltip: 'Close filters',
        ),
      ],
    );
  }

  Widget _buildBasicFilters() {
    return Row(
      children: [
        // ✅ Order Status Filter
        Expanded(
          child: DropdownButtonFormField<OrderStatus>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.info_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: [
              DropdownMenuItem<OrderStatus>(
                value: null,
                child: Text('All Statuses', style: TextStyle(color: Colors.grey[600])),
              ),
              ...OrderStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: status.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
        ),
        SizedBox(width: 16),
        // ✅ Order Type Filter (Sell/Rental)
        Expanded(
          child: DropdownButtonFormField<OrderType>(
            value: _selectedOrderType,
            decoration: InputDecoration(
              labelText: 'Order Type',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: [
              DropdownMenuItem<OrderType>(
                value: null,
                child: Text('All Types', style: TextStyle(color: Colors.grey[600])),
              ),
              ...OrderType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, color: type.typeColor, size: 16),
                      SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) => setState(() => _selectedOrderType = value),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minAmountController,
            decoration: InputDecoration(
              labelText: 'Min Amount (\$)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _maxAmountController,
            decoration: InputDecoration(
              labelText: 'Max Amount (\$)',
              prefixIcon: Icon(Icons.money_off),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerFilter() {
    return TextField(
      controller: _customerNameController,
      decoration: InputDecoration(
        labelText: 'Customer Name',
        prefixIcon: Icon(Icons.person_search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'Search by customer name...',
      ),
    );
  }

  Widget _buildRentalFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.purple[700], size: 20),
              SizedBox(width: 8),
              Text(
                'Rental Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Rental start date range
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, 'rental_start_after'),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purple[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rental Start After',
                            style: TextStyle(fontSize: 12, color: Colors.purple[600])),
                        Text(_rentalStartAfter != null
                            ? _formatDate(_rentalStartAfter!)
                            : 'Select date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _rentalStartAfter != null ? Colors.black87 : Colors.grey[600],
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, 'rental_start_before'),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purple[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rental Start Before',
                            style: TextStyle(fontSize: 12, color: Colors.purple[600])),
                        Text(_rentalStartBefore != null
                            ? _formatDate(_rentalStartBefore!)
                            : 'Select date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _rentalStartBefore != null ? Colors.black87 : Colors.grey[600],
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Rental end date range
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, 'rental_end_after'),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purple[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rental End After',
                            style: TextStyle(fontSize: 12, color: Colors.purple[600])),
                        Text(_rentalEndAfter != null
                            ? _formatDate(_rentalEndAfter!)
                            : 'Select date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _rentalEndAfter != null ? Colors.black87 : Colors.grey[600],
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, 'rental_end_before'),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.purple[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rental End Before',
                            style: TextStyle(fontSize: 12, color: Colors.purple[600])),
                        Text(_rentalEndBefore != null
                            ? _formatDate(_rentalEndBefore!)
                            : 'Select date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _rentalEndBefore != null ? Colors.black87 : Colors.grey[600],
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Daily rate range
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minDailyRateController,
                  decoration: InputDecoration(
                    labelText: 'Min Daily Rate (\$)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxDailyRateController,
                  decoration: InputDecoration(
                    labelText: 'Max Daily Rate (\$)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _clearFilters,
          icon: Icon(Icons.clear_all),
          label: Text('Clear All'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
        ),
        SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _applyFilters,
          icon: Icon(Icons.filter_alt),
          label: Text('Apply Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED: Apply filters with rental support
  void _applyFilters() {
    final filters = <String, dynamic>{};

    // Basic filters
    if (_selectedStatus != null) {
      filters['status'] = _selectedStatus.toString().split('.').last;
    }
    if (_selectedOrderType != null) {
      filters['order_type'] = _selectedOrderType.toString().split('.').last; // ✅ CHANGED
    }
    if (_minAmountController.text.isNotEmpty) {
      filters['min_amount'] = double.tryParse(_minAmountController.text);
    }
    if (_maxAmountController.text.isNotEmpty) {
      filters['max_amount'] = double.tryParse(_maxAmountController.text);
    }
    if (_customerNameController.text.isNotEmpty) {
      filters['customer_name'] = _customerNameController.text.trim();
    }

    // ✅ NEW: Rental-specific filters
    if (_rentalStartAfter != null) {
      filters['rental_start_after'] = _rentalStartAfter!.toIso8601String().split('T')[0];
    }
    if (_rentalStartBefore != null) {
      filters['rental_start_before'] = _rentalStartBefore!.toIso8601String().split('T')[0];
    }
    if (_rentalEndAfter != null) {
      filters['rental_end_after'] = _rentalEndAfter!.toIso8601String().split('T')[0];
    }
    if (_rentalEndBefore != null) {
      filters['rental_end_before'] = _rentalEndBefore!.toIso8601String().split('T')[0];
    }
    if (_minDailyRateController.text.isNotEmpty) {
      filters['min_daily_rate'] = double.tryParse(_minDailyRateController.text);
    }
    if (_maxDailyRateController.text.isNotEmpty) {
      filters['max_daily_rate'] = double.tryParse(_maxDailyRateController.text);
    }

    context.read<OrderBloc>().add(FilterOrdersEvent(filters));

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filters applied successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedOrderType = null; // ✅ CHANGED
      _minAmountController.clear();
      _maxAmountController.clear();
      _customerNameController.clear();
      // ✅ NEW: Clear rental filters
      _rentalStartAfter = null;
      _rentalStartBefore = null;
      _rentalEndAfter = null;
      _rentalEndBefore = null;
      _minDailyRateController.clear();
      _maxDailyRateController.clear();
    });

    context.read<OrderBloc>().add(ClearOrderFilters());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All filters cleared'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ NEW: Date picker helper
  void _selectDate(BuildContext context, String filterType) async {
    DateTime? currentDate;
    switch (filterType) {
      case 'rental_start_after':
        currentDate = _rentalStartAfter;
        break;
      case 'rental_start_before':
        currentDate = _rentalStartBefore;
        break;
      case 'rental_end_after':
        currentDate = _rentalEndAfter;
        break;
      case 'rental_end_before':
        currentDate = _rentalEndBefore;
        break;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      helpText: 'Select Date for Filter',
    );

    if (date != null) {
      setState(() {
        switch (filterType) {
          case 'rental_start_after':
            _rentalStartAfter = date;
            break;
          case 'rental_start_before':
            _rentalStartBefore = date;
            break;
          case 'rental_end_after':
            _rentalEndAfter = date;
            break;
          case 'rental_end_before':
            _rentalEndBefore = date;
            break;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _customerNameController.dispose();
    _minDailyRateController.dispose();
    _maxDailyRateController.dispose();
    super.dispose();
  }
}
