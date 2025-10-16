// ✅ presentation/widgets/order/forms/customer_info_form.dart
import 'package:flutter/material.dart';
import '../models/order_form_data.dart';

class CustomerInfoForm extends StatelessWidget {
  final OrderFormData formData;

  const CustomerInfoForm({Key? key, required this.formData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildInputField(
              controller: formData.customerNameController,
              label: 'Customer Name *',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Please enter customer name';
                if (value.trim().length < 2)
                  return 'Name must be at least 2 characters';
                return null;
              },
            ),
            _buildInputField(
              controller: formData.customerEmailController,
              label: 'Customer Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            _buildInputField(
              controller: formData.customerPhoneController,
              label: 'Customer Phone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final phoneRegex = RegExp(r'^[+]?[0-9\s\-\(\)]+$');
                  if (value.trim().length < 10 ||
                      !phoneRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            _buildInputField(
              controller: formData.shippingAddressController,
              label: 'Shipping Address',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            _buildInputField(
              controller: formData.notesController,
              label: 'Order Notes',
              icon: Icons.note,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        Text('Enter customer details for this order',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          errorMaxLines: 2,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}
