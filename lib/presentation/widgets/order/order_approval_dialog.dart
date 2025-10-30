// ✅ presentation/widgets/order/dialogs/order_approval_dialog.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';

class OrderApprovalDialog extends StatefulWidget {
  final Order order;
  final bool isApproval;

  const OrderApprovalDialog({
    Key? key,
    required this.order,
    required this.isApproval,
  }) : super(key: key);

  @override
  State<OrderApprovalDialog> createState() => _OrderApprovalDialogState();
}

class _OrderApprovalDialogState extends State<OrderApprovalDialog> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    final isApproval = widget.isApproval;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: _buildHeader(theme, isDark, isApproval),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderDetailsCard(theme, isDark),
            SizedBox(height: 20),
            _buildAdditionalInfoCard(theme, isDark),
            SizedBox(height: 20),
            _buildInputSection(theme, isDark, isApproval),
          ],
        ),
      ),
      actions: _buildActions(theme, isApproval),
      elevation: 4,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, bool isApproval) {
    final color = isApproval ? Colors.green : Colors.red;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              isApproval ? Icons.check_circle : Icons.cancel,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              isApproval
                  ? 'order_approval_dialog.approve_title'.tr()
                  : 'order_approval_dialog.reject_title'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: theme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'order_approval_dialog.order_details'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildDetailRow(
            'order_approval_dialog.order_label'.tr(),
            widget.order.orderNumber,
            theme,
            isDark,
          ),
          SizedBox(height: 8),
          _buildDetailRow(
            'order_approval_dialog.customer_label'.tr(),
            widget.order.customerName ??
                'order_approval_dialog.unknown_customer'.tr(),
            theme,
            isDark,
          ),
          SizedBox(height: 8),
          _buildDetailRow(
            'order_approval_dialog.total_label'.tr(),
            '\$${widget.order.totalAmount.toStringAsFixed(2)}',
            theme,
            isDark,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'order_approval_dialog.additional_info'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildDetailRow(
            'order_approval_dialog.order_type_label'.tr(),
            widget.order.orderType.displayName,
            theme,
            isDark,
          ),
          SizedBox(height: 6),
          _buildDetailRow(
            'order_approval_dialog.items_count'.tr(
              namedArgs: {'count': widget.order.items.length.toString()},
            ),
            '',
            theme,
            isDark,
            hideValue: true,
          ),
          if (widget.order.orderType == OrderType.rental &&
              widget.order.rentalDurationDays != null) ...[
            SizedBox(height: 6),
            _buildDetailRow(
              'order_approval_dialog.rental_duration'.tr(
                namedArgs: {
                  'days': widget.order.rentalDurationDays.toString(),
                },
              ),
              '',
              theme,
              isDark,
              hideValue: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value,
      ThemeData theme,
      bool isDark, {
        bool isHighlight = false,
        bool hideValue = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
        if (!hideValue)
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? Colors.green[700]
                  : (isDark ? Colors.white : Colors.grey[800]),
            ),
          ),
      ],
    );
  }

  Widget _buildInputSection(ThemeData theme, bool isDark, bool isApproval) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isApproval
              ? 'order_approval_dialog.approval_notes'.tr()
              : 'order_approval_dialog.rejection_reason'.tr(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: isApproval ? _notesController : _reasonController,
          focusNode: _focusNode,
          maxLines: 3,
          minLines: 3,
          decoration: InputDecoration(
            hintText: isApproval
                ? 'order_approval_dialog.notes_hint'.tr()
                : 'order_approval_dialog.reason_hint'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
            contentPadding: EdgeInsets.all(12),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(ThemeData theme, bool isApproval) {
    final actionColor = isApproval ? Colors.green : Colors.red;

    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('order_approval_dialog.cancel_button'.tr()),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: _handleAction,
        icon: Icon(
          isApproval ? Icons.check_circle : Icons.cancel,
          size: 20,
        ),
        label: Text(
          isApproval
              ? 'order_approval_dialog.approve_button'.tr()
              : 'order_approval_dialog.reject_button'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: actionColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    ];
  }

  void _handleAction() {
    // ✅ Validation for rejection reason
    if (!widget.isApproval && _reasonController.text.trim().isEmpty) {
      _showValidationError(
        'order_approval_dialog.error_reason_required'.tr(),
      );
      _focusNode.requestFocus();
      return;
    }

    if (widget.isApproval) {
      // ✅ Approve order
      context.read<OrderBloc>().add(
        ApproveOrderEvent(
          orderId: widget.order.id,
          approvedBy: 'Current User', // TODO: Get from auth provider
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        ),
      );
    } else {
      // ✅ Reject order
      context.read<OrderBloc>().add(
        RejectOrderEvent(
          orderId: widget.order.id,
          rejectedBy: 'Current User', // TODO: Get from auth provider
          reason: _reasonController.text.trim(),
        ),
      );
    }

    Navigator.pop(context);
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
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
    _notesController.dispose();
    _reasonController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
