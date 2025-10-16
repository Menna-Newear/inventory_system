// ✅ presentation/widgets/order/forms/rental_settings_form.dart
import 'package:flutter/material.dart';
import '../models/order_form_data.dart';

class RentalSettingsForm extends StatefulWidget {
  final OrderFormData formData;

  const RentalSettingsForm({Key? key, required this.formData}) : super(key: key);

  @override
  State<RentalSettingsForm> createState() => _RentalSettingsFormState();
}

class _RentalSettingsFormState extends State<RentalSettingsForm> {
  OrderFormData get formData => widget.formData;

  @override
  void initState() {
    super.initState();
    formData.dailyRateController.addListener(() => setState(() {}));
    formData.securityDepositController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 20),
        _buildDateSection(),
        if (formData.calculatedRentalDays != null) ...[
          SizedBox(height: 16),
          _buildDurationDisplay(),
        ],
        SizedBox(height: 24),
        _buildPricingSection(),
        if (_shouldShowCostBreakdown()) ...[
          SizedBox(height: 24),
          _buildCostBreakdown(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rental Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        Text('Configure rental period and pricing',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDateSection() {
    return Row(
      children: [
        Expanded(child: _buildDatePicker(
          title: 'Start Date *',
          icon: Icons.calendar_today,
          date: formData.rentalStartDate,
          onTap: _selectStartDate,
        )),
        SizedBox(width: 16),
        Expanded(child: _buildDatePicker(
          title: 'End Date *',
          icon: Icons.event_available,
          date: formData.rentalEndDate,
          onTap: _selectEndDate,
        )),
      ],
    );
  }

  Widget _buildDatePicker({
    required String title,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.purple)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              date != null ? _formatDate(date) : 'Select date',
              style: TextStyle(
                fontSize: 16,
                color: date != null ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDisplay() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.blue[700], size: 20),
          SizedBox(width: 8),
          Text(
            'Rental Duration: ${formData.calculatedRentalDays} days',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Row(
      children: [
        Expanded(child: _buildPriceField(
          controller: formData.dailyRateController,
          label: 'Daily Rate *',
          icon: Icons.attach_money,
        )),
        SizedBox(width: 16),
        Expanded(child: _buildPriceField(
          controller: formData.securityDepositController,
          label: 'Security Deposit',
          icon: Icons.security,
        )),
      ],
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (label.contains('*') && (value == null || value.trim().isEmpty)) {
          return 'This field is required';
        }
        if (value != null && value.trim().isNotEmpty) {
          final amount = double.tryParse(value.trim());
          if (amount == null || amount < 0) {
            return 'Enter a valid amount';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCostBreakdown() {
    final dailyRate = double.tryParse(formData.dailyRateController.text) ?? 0.0;
    final deposit = double.tryParse(formData.securityDepositController.text) ?? 0.0;
    final days = formData.calculatedRentalDays ?? 0;
    final subtotal = dailyRate * days;
    final total = subtotal + deposit;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rental Cost Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
          SizedBox(height: 12),
          _buildCostRow('Daily Rate', '\$${dailyRate.toStringAsFixed(2)}', false),
          _buildCostRow('Duration', '$days days', false),
          _buildCostRow('Rental Subtotal', '\$${subtotal.toStringAsFixed(2)}', false),
          if (deposit > 0)
            _buildCostRow('Security Deposit', '\$${deposit.toStringAsFixed(2)}', false),
          Divider(color: Colors.green[300]),
          _buildCostRow('Total Amount', '\$${total.toStringAsFixed(2)}', true),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, bool isTotal) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green[800] : Colors.green[700],
          )),
          Text(value, style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.green[800] : Colors.green[700],
          )),
        ],
      ),
    );
  }

  bool _shouldShowCostBreakdown() {
    return formData.calculatedRentalDays != null &&
        formData.dailyRateController.text.isNotEmpty;
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: formData.rentalStartDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      helpText: 'Select Rental Start Date',
    );

    if (date != null) {
      setState(() {
        formData.rentalStartDate = date;
        if (formData.rentalEndDate != null && formData.rentalEndDate!.isBefore(date)) {
          formData.rentalEndDate = null;
        }
      });
    }
  }

  void _selectEndDate() async {
    final initialDate = formData.rentalEndDate ??
        (formData.rentalStartDate?.add(Duration(days: 1)) ?? DateTime.now().add(Duration(days: 2)));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: formData.rentalStartDate?.add(Duration(days: 1)) ?? DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      helpText: 'Select Rental End Date',
    );

    if (date != null) {
      setState(() {
        formData.rentalEndDate = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
