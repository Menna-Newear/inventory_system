// ✅ presentation/widgets/order/forms/rental_settings_form.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          SizedBox(height: 24),
          _buildDateSection(theme, isDark),
          if (formData.calculatedRentalDays != null) ...[
            SizedBox(height: 16),
            _buildDurationDisplay(theme),
          ],
          SizedBox(height: 24),
          _buildPricingSection(theme, isDark),
          if (_shouldShowCostBreakdown()) ...[
            SizedBox(height: 24),
            _buildCostBreakdown(theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
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
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_available,
              color: Colors.purple,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'rental_settings.title'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'rental_settings.subtitle'.tr(),
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

  Widget _buildDateSection(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Vertical layout
          return Column(
            children: [
              _buildDatePicker(
                theme: theme,
                isDark: isDark,
                title: 'rental_settings.start_date'.tr(),
                icon: Icons.calendar_today,
                date: formData.rentalStartDate,
                onTap: _selectStartDate,
              ),
              SizedBox(height: 16),
              _buildDatePicker(
                theme: theme,
                isDark: isDark,
                title: 'rental_settings.end_date'.tr(),
                icon: Icons.event_available,
                date: formData.rentalEndDate,
                onTap: _selectEndDate,
              ),
            ],
          );
        } else {
          // Desktop: Horizontal layout
          return Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  theme: theme,
                  isDark: isDark,
                  title: 'rental_settings.start_date'.tr(),
                  icon: Icons.calendar_today,
                  date: formData.rentalStartDate,
                  onTap: _selectStartDate,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  theme: theme,
                  isDark: isDark,
                  title: 'rental_settings.end_date'.tr(),
                  icon: Icons.event_available,
                  date: formData.rentalEndDate,
                  onTap: _selectEndDate,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDatePicker({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? Colors.purple
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: date != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? theme.cardColor : Colors.white,
          boxShadow: date != null
              ? [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.purple, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              date != null
                  ? _formatDate(date, context)
                  : 'rental_settings.select_date'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: date != null
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDisplay(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.access_time, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'rental_settings.duration'.tr(namedArgs: {
                'days': formData.calculatedRentalDays.toString()
              }),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Vertical layout
          return Column(
            children: [
              _buildPriceField(
                theme: theme,
                isDark: isDark,
                controller: formData.dailyRateController,
                label: 'rental_settings.daily_rate'.tr(),
                icon: Icons.attach_money,
                isRequired: true,
              ),
              SizedBox(height: 16),
              _buildPriceField(
                theme: theme,
                isDark: isDark,
                controller: formData.securityDepositController,
                label: 'rental_settings.security_deposit'.tr(),
                icon: Icons.security,
                isRequired: false,
              ),
            ],
          );
        } else {
          // Desktop: Horizontal layout
          return Row(
            children: [
              Expanded(
                child: _buildPriceField(
                  theme: theme,
                  isDark: isDark,
                  controller: formData.dailyRateController,
                  label: 'rental_settings.daily_rate'.tr(),
                  icon: Icons.attach_money,
                  isRequired: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildPriceField(
                  theme: theme,
                  isDark: isDark,
                  controller: formData.securityDepositController,
                  label: 'rental_settings.security_deposit'.tr(),
                  icon: Icons.security,
                  isRequired: false,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPriceField({
    required ThemeData theme,
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isRequired,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        prefixIcon: Icon(icon, color: theme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        fillColor: isDark ? theme.cardColor : Colors.white,
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'rental_settings.validation.required'.tr();
        }
        if (value != null && value.trim().isNotEmpty) {
          final amount = double.tryParse(value.trim());
          if (amount == null || amount < 0) {
            return 'rental_settings.validation.invalid_amount'.tr();
          }
        }
        return null;
      },
    );
  }

  Widget _buildCostBreakdown(ThemeData theme, bool isDark) {
    final dailyRate = double.tryParse(formData.dailyRateController.text) ?? 0.0;
    final deposit = double.tryParse(formData.securityDepositController.text) ?? 0.0;
    final days = formData.calculatedRentalDays ?? 0;
    final subtotal = dailyRate * days;
    final total = subtotal + deposit;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'rental_settings.cost_breakdown'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildCostRow(
            'rental_settings.cost_daily_rate'.tr(),
            '\$${dailyRate.toStringAsFixed(2)}',
            false,
          ),
          _buildCostRow(
            'rental_settings.cost_duration'.tr(),
            '$days ${'rental_settings.days_label'.tr()}',
            false,
          ),
          _buildCostRow(
            'rental_settings.cost_subtotal'.tr(),
            '\$${subtotal.toStringAsFixed(2)}',
            false,
          ),
          if (deposit > 0)
            _buildCostRow(
              'rental_settings.cost_deposit'.tr(),
              '\$${deposit.toStringAsFixed(2)}',
              false,
            ),
          Divider(color: Colors.green[400], thickness: 2, height: 24),
          _buildCostRow(
            'rental_settings.cost_total'.tr(),
            '\$${total.toStringAsFixed(2)}',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, bool isTotal) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green[900] : Colors.green[800],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green[900] : Colors.green[800],
            ),
          ),
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
      helpText: 'rental_settings.dialog_start_title'.tr(),
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
        (formData.rentalStartDate?.add(Duration(days: 1)) ??
            DateTime.now().add(Duration(days: 2)));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: formData.rentalStartDate?.add(Duration(days: 1)) ??
          DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      helpText: 'rental_settings.dialog_end_title'.tr(),
    );

    if (date != null) {
      setState(() {
        formData.rentalEndDate = date;
      });
    }
  }

  String _formatDate(DateTime date, BuildContext context) {
    // ✅ Use locale-aware date formatting
    final locale = context.locale.toString();
    final formatter = intl.DateFormat.yMMMd(locale);
    return formatter.format(date);
  }
}
