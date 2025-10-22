// ✅ presentation/widgets/order/models/order_form_data.dart
import 'package:flutter/material.dart';
import '../../../../domain/entities/order.dart';
import '../../../../domain/entities/inventory_item.dart';

class OrderFormData {
  // Controllers
  final customerNameController = TextEditingController();
  final customerEmailController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final shippingAddressController = TextEditingController();
  final notesController = TextEditingController();
  final dailyRateController = TextEditingController();
  final securityDepositController = TextEditingController();

  // Order settings
  OrderType orderType = OrderType.sell;
  DateTime? rentalStartDate;
  DateTime? rentalEndDate;

  // Selected items
  Map<String, SelectedOrderItem> selectedItems = {};

  // Computed properties
  int? get calculatedRentalDays {
    if (rentalStartDate == null || rentalEndDate == null) return null;
    return rentalEndDate!.difference(rentalStartDate!).inDays + 1;
  }

  double get totalAmount {
    if (orderType == OrderType.rental && calculatedRentalDays != null) {
      final dailyRate = double.tryParse(dailyRateController.text) ?? 0.0;
      final deposit = double.tryParse(securityDepositController.text) ?? 0.0;
      return (dailyRate * calculatedRentalDays!) + deposit;
    }
    return selectedItems.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalQuantity {
    return selectedItems.values.fold(0, (sum, item) => sum + item.quantity);
  }

  // Validation
  ValidationResult validate() {
    if (customerNameController.text.trim().isEmpty) {
      return ValidationResult.error('Customer name is required');
    }

    if (selectedItems.isEmpty) {
      return ValidationResult.error('Please add at least one item');
    }

    if (orderType == OrderType.rental) {
      if (rentalStartDate == null) {
        return ValidationResult.error('Rental start date is required');
      }
      if (rentalEndDate == null) {
        return ValidationResult.error('Rental end date is required');
      }
      if (dailyRateController.text.isEmpty) {
        return ValidationResult.error('Daily rate is required');
      }
      final rate = double.tryParse(dailyRateController.text);
      if (rate == null || rate <= 0) {
        return ValidationResult.error('Please enter a valid daily rate');
      }
    }

    return ValidationResult.success();
  }

  // Convert to Order entity
  Order toOrder() {
    final orderItems = selectedItems.values.map((selected) {
      return OrderItem(
        itemId: selected.id,
        itemName: selected.name,
        itemSku: selected.sku,
        quantity: selected.quantity,
        unitPrice: selected.unitPrice,
        totalPrice: selected.totalPrice,
        serialNumbers: selected.serialNumbers,

      );
    }).toList();

    return Order(
      id: '',
      orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      status: OrderStatus.draft,
      orderType: orderType,
      items: orderItems,
      customerName: customerNameController.text.trim(),
      customerEmail: customerEmailController.text.trim().isEmpty
          ? null
          : customerEmailController.text.trim(),
      customerPhone: customerPhoneController.text.trim().isEmpty
          ? null
          : customerPhoneController.text.trim(),
      shippingAddress: shippingAddressController.text.trim().isEmpty
          ? null
          : shippingAddressController.text.trim(),
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      totalAmount: totalAmount,
      rentalStartDate: orderType == OrderType.rental ? rentalStartDate : null,
      rentalEndDate: orderType == OrderType.rental ? rentalEndDate : null,
      rentalDurationDays: orderType == OrderType.rental ? calculatedRentalDays : null,
      dailyRate: orderType == OrderType.rental && dailyRateController.text.isNotEmpty
          ? double.tryParse(dailyRateController.text)
          : null,
      securityDeposit: orderType == OrderType.rental && securityDepositController.text.isNotEmpty
          ? double.tryParse(securityDepositController.text)
          : null,
      createdBy: 'Current User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void dispose() {
    customerNameController.dispose();
    customerEmailController.dispose();
    customerPhoneController.dispose();
    shippingAddressController.dispose();
    notesController.dispose();
    dailyRateController.dispose();
    securityDepositController.dispose();
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.success() => ValidationResult._(true, null);
  factory ValidationResult.error(String message) => ValidationResult._(false, message);
}

class SelectedOrderItem {
  final String id;
  final String name;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<String>? serialNumbers;


  const SelectedOrderItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.serialNumbers,

  });
}
