// ✅ presentation/widgets/order/forms/customer_info_form.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/order_form_data.dart';

class CustomerInfoForm extends StatelessWidget {
  final OrderFormData formData;

  const CustomerInfoForm({Key? key, required this.formData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, isDark),
            SizedBox(height: 24),
            _buildInputField(
              context: context,
              controller: formData.customerNameController,
              label: 'customer_info_form.customer_name_required'.tr(),
              icon: Icons.person,
              isDark: isDark,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'customer_info_form.validation.name_required'.tr();
                }
                if (value.trim().length < 2) {
                  return 'customer_info_form.validation.name_min_length'.tr();
                }
                return null;
              },
            ),
            _buildInputField(
              context: context,
              controller: formData.customerEmailController,
              label: 'customer_info_form.customer_email'.tr(),
              icon: Icons.email,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'customer_info_form.validation.email_invalid'.tr();
                  }
                }
                return null;
              },
            ),
            _buildInputField(
              context: context,
              controller: formData.customerPhoneController,
              label: 'customer_info_form.customer_phone'.tr(),
              icon: Icons.phone,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final phoneRegex = RegExp(r'^[+]?[0-9\s\-\(\)]+$');
                  if (value.trim().length < 10) {
                    return 'customer_info_form.validation.phone_min_length'.tr();
                  }
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'customer_info_form.validation.phone_invalid'.tr();
                  }
                }
                return null;
              },
            ),
            _buildInputField(
              context: context,
              controller: formData.shippingAddressController,
              label: 'customer_info_form.shipping_address'.tr(),
              icon: Icons.location_on,
              isDark: isDark,
              maxLines: 2,
            ),
            _buildInputField(
              context: context,
              controller: formData.notesController,
              label: 'customer_info_form.order_notes'.tr(),
              icon: Icons.note,
              isDark: isDark,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
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
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'customer_info_form.title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'customer_info_form.subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          prefixIcon: Icon(
            icon,
            color: theme.primaryColor,
          ),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.white,
          errorMaxLines: 2,
          // ✅ Enhanced error styling
          errorStyle: TextStyle(
            fontSize: 12,
            height: 1.2,
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}
