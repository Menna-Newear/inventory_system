// ✅ presentation/widgets/order/order_filter_panel.dart (ENHANCED UI)
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

  // Rental-specific filters
  DateTime? _rentalStartAfter;
  DateTime? _rentalStartBefore;
  DateTime? _rentalEndAfter;
  DateTime? _rentalEndBefore;
  final TextEditingController _minDailyRateController = TextEditingController();
  final TextEditingController _maxDailyRateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.filter_alt, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Orders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Refine your search',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: widget.onClose,
                tooltip: 'Close',
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickFilters(),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),
                _buildAdvancedFilters(),
                if (_selectedOrderType == OrderType.rental || _selectedOrderType == null) ...[
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  _buildRentalFilters(),
                ],
              ],
            ),
          ),
        ),

        // Action buttons at bottom
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: Icon(Icons.check),
                  label: Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear_all),
                  label: Text('Clear All Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Quick Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatusFilter()),
            SizedBox(width: 12),
            Expanded(child: _buildOrderTypeFilter()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<OrderStatus>(
        value: _selectedStatus,
        decoration: InputDecoration(
          labelText: 'Order Status',
          prefixIcon: Icon(Icons.info_outline, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        isExpanded: true, // ✅ ADD THIS
        items: [
          DropdownMenuItem<OrderStatus>(
            value: null,
            child: Text('All Statuses', style: TextStyle(color: Colors.grey[600])),
          ),
          ...OrderStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min, // ✅ ADD THIS
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded( // ✅ WRAP Text IN Expanded
                    child: Text(
                      status.displayName,
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis, // ✅ ADD THIS
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (value) => setState(() => _selectedStatus = value),
      ),
    );
  }

  Widget _buildOrderTypeFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<OrderType>(
        value: _selectedOrderType,
        decoration: InputDecoration(
          labelText: 'Order Type',
          prefixIcon: Icon(Icons.category, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        isExpanded: true, // ✅ ADD THIS
        items: [
          DropdownMenuItem<OrderType>(
            value: null,
            child: Text('All Types', style: TextStyle(color: Colors.grey[600])),
          ),
          ...OrderType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                mainAxisSize: MainAxisSize.min, // ✅ ADD THIS
                children: [
                  Icon(type.icon, color: type.typeColor, size: 16),
                  SizedBox(width: 10),
                  Expanded( // ✅ WRAP Text IN Expanded
                    child: Text(
                      type.displayName,
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis, // ✅ ADD THIS
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (value) => setState(() => _selectedOrderType = value),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Advanced Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Customer name
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: 'Customer Name',
              prefixIcon: Icon(Icons.person_search, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Search by customer name...',
              hintStyle: TextStyle(fontSize: 13),
            ),
          ),
        ),

        SizedBox(height: 12),

        // Amount range
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _minAmountController,
                  decoration: InputDecoration(
                    labelText: 'Min Amount',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _maxAmountController,
                  decoration: InputDecoration(
                    labelText: 'Max Amount',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.money_off, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRentalFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[100]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple[700],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time, color: Colors.white, size: 16),
              ),
              SizedBox(width: 10),
              Text(
                'Rental Period Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[900],
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Dates in compact grid
          Row(
            children: [
              Expanded(child: _buildDateButton('Start After', _rentalStartAfter, 'rental_start_after')),
              SizedBox(width: 8),
              Expanded(child: _buildDateButton('Start Before', _rentalStartBefore, 'rental_start_before')),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDateButton('End After', _rentalEndAfter, 'rental_end_after')),
              SizedBox(width: 8),
              Expanded(child: _buildDateButton('End Before', _rentalEndBefore, 'rental_end_before')),
            ],
          ),

          SizedBox(height: 12),

          // Daily rate range
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _minDailyRateController,
                    decoration: InputDecoration(
                      labelText: 'Min Rate',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _maxDailyRateController,
                    decoration: InputDecoration(
                      labelText: 'Max Rate',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, String filterType) {
    return InkWell(
      onTap: () => _selectDate(context, filterType),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: date != null ? Colors.purple[400]! : Colors.purple[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.purple[700], fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.purple[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : 'Select',
                    style: TextStyle(
                      fontSize: 12,
                      color: date != null ? Colors.black87 : Colors.grey[500],
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: Icon(Icons.clear_all, size: 18),
            label: Text('Clear All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[400]!),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: Icon(Icons.check, size: 18),
            label: Text('Apply Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_selectedStatus != null) {
      filters['status'] = _selectedStatus.toString().split('.').last;
    }
    if (_selectedOrderType != null) {
      filters['order_type'] = _selectedOrderType.toString().split('.').last;
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

    // Rental filters
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Filters applied successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedOrderType = null;
      _minAmountController.clear();
      _maxAmountController.clear();
      _customerNameController.clear();
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
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('All filters cleared'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
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
