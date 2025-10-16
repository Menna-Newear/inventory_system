// ✅ presentation/widgets/order/panels/order_summary_panel.dart
import 'package:flutter/material.dart';
import '../../../../domain/entities/order.dart';
import '../models/order_form_data.dart';

class OrderSummaryPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (formData.orderType == OrderType.rental && _hasRentalInfo())
            _buildRentalInfo(),
          Expanded(child: _buildItemsList()),
          if (formData.selectedItems.isNotEmpty) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: formData.orderType.typeColor),
          SizedBox(width: 8),
          Text(
            '${formData.orderType.displayName} Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: formData.orderType.typeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(8),
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
              Icon(Icons.access_time, color: Colors.purple, size: 16),
              SizedBox(width: 6),
              Text('Rental Period', style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              )),
            ],
          ),
          if (formData.rentalStartDate != null) ...[
            SizedBox(height: 4),
            Text('From: ${_formatDate(formData.rentalStartDate!)}',
                style: TextStyle(fontSize: 11, color: Colors.purple[700])),
          ],
          if (formData.rentalEndDate != null) ...[
            Text('To: ${_formatDate(formData.rentalEndDate!)}',
                style: TextStyle(fontSize: 11, color: Colors.purple[700])),
          ],
          if (formData.calculatedRentalDays != null) ...[
            SizedBox(height: 4),
            Text('Duration: ${formData.calculatedRentalDays} days',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (formData.selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No items added', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text(
              'Select items to add them to this ${formData.orderType.displayName.toLowerCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: formData.selectedItems.length,
      itemBuilder: (context, index) {
        final item = formData.selectedItems.values.elementAt(index);
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(SelectedOrderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Text('${item.sku}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('Qty: ${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('\$${item.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  IconButton(
                    onPressed: () => _removeItem(item.id),
                    icon: Icon(Icons.delete, color: Colors.red, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Items:', '${formData.selectedItems.length}'),
          _buildSummaryRow('Quantity:', '${formData.totalQuantity}'),
          if (formData.orderType == OrderType.rental && formData.calculatedRentalDays != null) ...[
            _buildSummaryRow('Duration:', '${formData.calculatedRentalDays} days'),
            if (formData.dailyRateController.text.isNotEmpty)
              _buildSummaryRow('Daily Rate:', '\$${formData.dailyRateController.text}'),
            if (formData.securityDepositController.text.isNotEmpty)
              _buildSummaryRow('Security Deposit:', '\$${formData.securityDepositController.text}'),
          ],
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('\$${formData.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCreating ? null : onCreateOrder,
              icon: isCreating
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.check_circle, size: 20),
              label: Text(
                isCreating ? 'Creating...' : 'Create ${formData.orderType.displayName}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: formData.orderType.typeColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  bool _hasRentalInfo() {
    return formData.rentalStartDate != null ||
        formData.rentalEndDate != null ||
        formData.calculatedRentalDays != null;
  }

  void _removeItem(String itemId) {
    formData.selectedItems.remove(itemId);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
