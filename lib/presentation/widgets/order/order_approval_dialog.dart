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

  @override
  Widget build(BuildContext context) {
    final isApproval = widget.isApproval;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isApproval ? Icons.check_circle : Icons.cancel,
            color: isApproval ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Text(isApproval ? 'Approve Order' : 'Reject Order'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order: ${widget.order.orderNumber}'),
          Text('Customer: ${widget.order.customerName ?? "Unknown"}'),
          Text('Total: \$${widget.order.totalAmount.toStringAsFixed(2)}'),
          SizedBox(height: 16),

          if (isApproval) ...[
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Approval Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ] else ...[
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: isApproval ? Colors.green : Colors.red,
          ),
          child: Text(
            isApproval ? 'Approve' : 'Reject',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _handleAction() {
    if (!widget.isApproval && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rejection reason')),
      );
      return;
    }

    if (widget.isApproval) {
      context.read<OrderBloc>().add(ApproveOrderEvent(
        orderId: widget.order.id,
        approvedBy: 'Current User', // TODO: Get from auth
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      ));
    } else {
      context.read<OrderBloc>().add(RejectOrderEvent(
        orderId: widget.order.id,
        rejectedBy: 'Current User', // TODO: Get from auth
        reason: _reasonController.text.trim(),
      ));
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
