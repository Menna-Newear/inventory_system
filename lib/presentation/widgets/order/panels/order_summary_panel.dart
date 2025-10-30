// ✅ presentation/widgets/order/panels/order_summary_panel.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../domain/entities/order.dart';
import '../models/order_form_data.dart';

class OrderSummaryPanel extends StatefulWidget {
  final OrderFormData formData;
  final bool isCreating;
  final VoidCallback onCreateOrder;

  const OrderSummaryPanel({
    Key? key,
    required this.formData,
    required this.isCreating,
    required this.onCreateOrder,
  }) : super(key: key);

  @override
  State<OrderSummaryPanel> createState() => _OrderSummaryPanelState();
}

class _OrderSummaryPanelState extends State<OrderSummaryPanel> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey[50],
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme, isDark),
          if (widget.formData.orderType == OrderType.rental &&
              _hasRentalInfo())
            _buildRentalInfo(theme, isDark),
          Expanded(
            child: _buildItemsList(theme, isDark),
          ),
          if (widget.formData.selectedItems.isNotEmpty)
            _buildFooter(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.formData.orderType.typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long,
              color: widget.formData.orderType.typeColor,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'order_summary.summary'.tr()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  widget.formData.orderType.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.formData.orderType.typeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalInfo(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      margin: EdgeInsets.all(12),
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
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.access_time,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'order_summary.rental_period'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[900],
                ),
              ),
            ],
          ),
          if (widget.formData.rentalStartDate != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'order_summary.from'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  _formatDate(
                    widget.formData.rentalStartDate!,
                    context,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
          ],
          if (widget.formData.rentalEndDate != null) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'order_summary.to'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  _formatDate(
                    widget.formData.rentalEndDate!,
                    context,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
          ],
          if (widget.formData.calculatedRentalDays != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'order_summary.duration'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple[800],
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${widget.formData.calculatedRentalDays} ${'order_summary.days'.tr()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme, bool isDark) {
    if (widget.formData.selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: theme.primaryColor.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'order_summary.no_items'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'order_summary.select_items_hint'.tr(
                  namedArgs: {
                    'type': widget.formData.orderType.displayName
                        .toLowerCase(),
                  },
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: widget.formData.selectedItems.length,
      itemBuilder: (context, index) {
        final item = widget.formData.selectedItems.values.elementAt(index);
        return _buildItemCard(item, theme, isDark);
      },
    );
  }

  Widget _buildItemCard(
      SelectedOrderItem item,
      ThemeData theme,
      bool isDark,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDark ? theme.cardColor : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color:
                            isDark ? Colors.white : Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.sku,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            if (item.hasSerialNumbers) ...[
                              SizedBox(width: 6),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 10,
                                      color: Colors.purple,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '${item.serialNumbersCount}x',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 6),
                      Tooltip(
                        message: 'order_summary.remove_item'.tr(),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              widget.formData.selectedItems.remove(item.id);
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    final orderTypeDisplayName =
        widget.formData.orderType.displayName;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryRow(
              'order_summary.items'.tr(),
              '${widget.formData.selectedItems.length}',
              theme,
              isDark,
            ),
            SizedBox(height: 8),
            _buildSummaryRow(
              'order_summary.quantity'.tr(),
              '${widget.formData.totalQuantity}',
              theme,
              isDark,
            ),
            if (widget.formData.orderType == OrderType.rental &&
                widget.formData.calculatedRentalDays != null) ...[
              SizedBox(height: 8),
              _buildSummaryRow(
                'order_summary.duration'.tr(),
                '${widget.formData.calculatedRentalDays} ${'order_summary.days'.tr()}',
                theme,
                isDark,
              ),
              if (widget.formData.dailyRateController.text.isNotEmpty) ...[
                SizedBox(height: 8),
                _buildSummaryRow(
                  'order_summary.daily_rate'.tr(),
                  '\$${widget.formData.dailyRateController.text}',
                  theme,
                  isDark,
                ),
              ],
              if (widget.formData.securityDepositController.text
                  .isNotEmpty) ...[
                SizedBox(height: 8),
                _buildSummaryRow(
                  'order_summary.security_deposit'.tr(),
                  '\$${widget.formData.securityDepositController.text}',
                  theme,
                  isDark,
                ),
              ],
            ],
            Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'order_summary.total'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '\$${widget.formData.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isCreating
                    ? null
                    : widget.onCreateOrder,
                icon: widget.isCreating
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
                    : Icon(Icons.check_circle, size: 20),
                label: Text(
                  widget.isCreating
                      ? 'order_summary.creating_button'.tr()
                      : 'order_summary.create_button'.tr(
                    namedArgs: {'type': orderTypeDisplayName},
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isCreating
                      ? Colors.grey
                      : widget.formData.orderType.typeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value,
      ThemeData theme,
      bool isDark,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  bool _hasRentalInfo() {
    return widget.formData.rentalStartDate != null ||
        widget.formData.rentalEndDate != null ||
        widget.formData.calculatedRentalDays != null;
  }

  String _formatDate(DateTime date, BuildContext context) {
    // ✅ Use locale-aware date formatting
    final locale = context.locale.toString();
    final formatter = intl.DateFormat.yMMMd(locale);
    return formatter.format(date);
  }
}
