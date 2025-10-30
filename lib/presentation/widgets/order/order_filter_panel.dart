// ✅ presentation/widgets/order/panels/order_filter_panel.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(theme, isDark),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickFilters(theme, isDark),
                SizedBox(height: 20),
                Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                SizedBox(height: 20),
                _buildAdvancedFilters(theme, isDark),
                if (_selectedOrderType == OrderType.rental ||
                    _selectedOrderType == null) ...[
                  SizedBox(height: 20),
                  Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  SizedBox(height: 20),
                  _buildRentalFilters(theme, isDark),
                ],
              ],
            ),
          ),
        ),
        _buildActionButtons(theme, isDark),
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
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.filter_alt,
              color: Colors.white,
              size: 26,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'order_filter.title'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'order_filter.subtitle'.tr(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: widget.onClose,
            tooltip: 'Close',
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.speed,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'order_filter.quick_filters'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatusFilter(theme, isDark)),
            SizedBox(width: 12),
            Expanded(child: _buildOrderTypeFilter(theme, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusFilter(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonFormField<OrderStatus>(
        value: _selectedStatus,
        decoration: InputDecoration(
          labelText: 'order_filter.order_status'.tr(),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          prefixIcon: Icon(Icons.info_outline, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        isExpanded: true,
        dropdownColor: isDark ? theme.cardColor : Colors.white,
        items: [
          DropdownMenuItem<OrderStatus>(
            value: null,
            child: Text(
              'order_filter.all_statuses'.tr(),
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
          ...OrderStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: Text(
                      status.displayName,
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildOrderTypeFilter(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonFormField<OrderType>(
        value: _selectedOrderType,
        decoration: InputDecoration(
          labelText: 'order_filter.order_type'.tr(),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          prefixIcon: Icon(Icons.category, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        isExpanded: true,
        dropdownColor: isDark ? theme.cardColor : Colors.white,
        items: [
          DropdownMenuItem<OrderType>(
            value: null,
            child: Text(
              'order_filter.all_types'.tr(),
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
          ...OrderType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, color: type.typeColor, size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      type.displayName,
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildAdvancedFilters(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'order_filter.advanced_filters'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextFilterField(
          theme: theme,
          isDark: isDark,
          controller: _customerNameController,
          label: 'order_filter.customer_name'.tr(),
          hint: 'order_filter.customer_search'.tr(),
          icon: Icons.person_search,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNumberFilterField(
                theme: theme,
                isDark: isDark,
                controller: _minAmountController,
                label: 'order_filter.min_amount'.tr(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildNumberFilterField(
                theme: theme,
                isDark: isDark,
                controller: _maxAmountController,
                label: 'order_filter.max_amount'.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFilterField({
    required ThemeData theme,
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          prefixIcon: Icon(icon, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNumberFilterField({
    required ThemeData theme,
    required bool isDark,
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          prefixText: '\$ ',
          prefixIcon: Icon(Icons.attach_money, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRentalFilters(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.access_time,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'order_filter.rental_filters'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[900],
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'order_filter.start_after'.tr(),
                  _rentalStartAfter,
                  'rental_start_after',
                  theme,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  'order_filter.start_before'.tr(),
                  _rentalStartBefore,
                  'rental_start_before',
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'order_filter.end_after'.tr(),
                  _rentalEndAfter,
                  'rental_end_after',
                  theme,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  'order_filter.end_before'.tr(),
                  _rentalEndBefore,
                  'rental_end_before',
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberFilterField(
                  theme: theme,
                  isDark: isDark,
                  controller: _minDailyRateController,
                  label: 'order_filter.min_rate'.tr(),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildNumberFilterField(
                  theme: theme,
                  isDark: isDark,
                  controller: _maxDailyRateController,
                  label: 'order_filter.max_rate'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(
      String label,
      DateTime? date,
      String filterType,
      ThemeData theme,
      ) {
    return InkWell(
      onTap: () => _selectDate(context, filterType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date != null ? Colors.purple[400]! : Colors.purple[200]!,
            width: date != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.purple[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.purple[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    date != null
                        ? _formatDate(date, context)
                        : 'order_filter.select_date'.tr(),
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

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: Icon(Icons.check),
              label: Text(
                'order_filter.apply_filters'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.clear_all),
              label: Text(
                'order_filter.clear_all'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                ),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
      filters['rental_start_after'] =
      _rentalStartAfter!.toIso8601String().split('T')[0];
    }
    if (_rentalStartBefore != null) {
      filters['rental_start_before'] =
      _rentalStartBefore!.toIso8601String().split('T')[0];
    }
    if (_rentalEndAfter != null) {
      filters['rental_end_after'] =
      _rentalEndAfter!.toIso8601String().split('T')[0];
    }
    if (_rentalEndBefore != null) {
      filters['rental_end_before'] =
      _rentalEndBefore!.toIso8601String().split('T')[0];
    }
    if (_minDailyRateController.text.isNotEmpty) {
      filters['min_daily_rate'] =
          double.tryParse(_minDailyRateController.text);
    }
    if (_maxDailyRateController.text.isNotEmpty) {
      filters['max_daily_rate'] =
          double.tryParse(_maxDailyRateController.text);
    }

    context.read<OrderBloc>().add(FilterOrdersEvent(filters));

    _showSuccessSnackBar('order_filter.applied_success'.tr());
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

    _showInfoSnackBar('order_filter.cleared_success'.tr());
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
      helpText: 'order_filter.select_date_dialog'.tr(),
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

  String _formatDate(DateTime date, BuildContext context) {
    final locale = context.locale.toString();
    final formatter = intl.DateFormat.yMMMd(locale);
    return formatter.format(date);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
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
