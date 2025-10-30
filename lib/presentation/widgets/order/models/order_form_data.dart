// ✅ presentation/widgets/order/models/order_form_data.dart (FULLY LOCALIZED & ENHANCED!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/order.dart';

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

  // ✅ Track form state
  bool _isDisposed = false;

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

  // ✅ Enhanced validation with localized messages
  ValidationResult validate() {
    // Customer name validation
    if (customerNameController.text.trim().isEmpty) {
      return ValidationResult.error(
        'order_form_validation.customer_name_required'.tr(),
      );
    }

    // Items validation
    if (selectedItems.isEmpty) {
      return ValidationResult.error(
        'order_form_validation.items_required'.tr(),
      );
    }

    // Rental-specific validation
    if (orderType == OrderType.rental) {
      if (rentalStartDate == null) {
        return ValidationResult.error(
          'order_form_validation.rental_start_required'.tr(),
        );
      }

      if (rentalEndDate == null) {
        return ValidationResult.error(
          'order_form_validation.rental_end_required'.tr(),
        );
      }

      // ✅ Validate rental dates are in correct order
      if (rentalEndDate!.isBefore(rentalStartDate!)) {
        return ValidationResult.error(
          'End date must be after start date',
        );
      }

      if (dailyRateController.text.isEmpty) {
        return ValidationResult.error(
          'order_form_validation.daily_rate_required'.tr(),
        );
      }

      final rate = double.tryParse(dailyRateController.text);
      if (rate == null || rate <= 0) {
        return ValidationResult.error(
          'order_form_validation.daily_rate_invalid'.tr(),
        );
      }

      // ✅ Validate security deposit if provided
      if (securityDepositController.text.isNotEmpty) {
        final deposit = double.tryParse(securityDepositController.text);
        if (deposit == null || deposit < 0) {
          return ValidationResult.error(
            'Please enter a valid security deposit',
          );
        }
      }
    }

    // ✅ Validate email format if provided
    if (customerEmailController.text.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(customerEmailController.text.trim())) {
        return ValidationResult.error('Please enter a valid email address');
      }
    }

    // ✅ Validate phone format if provided
    if (customerPhoneController.text.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^[+]?[0-9\s\-\(\)]+$');
      if (customerPhoneController.text.trim().length < 10 ||
          !phoneRegex.hasMatch(customerPhoneController.text.trim())) {
        return ValidationResult.error('Please enter a valid phone number');
      }
    }

    return ValidationResult.success();
  }

  // ✅ Enhanced method to check if form has unsaved changes
  bool get hasChanges {
    return customerNameController.text.trim().isNotEmpty ||
        customerEmailController.text.trim().isNotEmpty ||
        customerPhoneController.text.trim().isNotEmpty ||
        shippingAddressController.text.trim().isNotEmpty ||
        notesController.text.trim().isNotEmpty ||
        dailyRateController.text.trim().isNotEmpty ||
        securityDepositController.text.trim().isNotEmpty ||
        selectedItems.isNotEmpty ||
        rentalStartDate != null ||
        rentalEndDate != null;
  }

  // ✅ Reset form to initial state
  void reset() {
    customerNameController.clear();
    customerEmailController.clear();
    customerPhoneController.clear();
    shippingAddressController.clear();
    notesController.clear();
    dailyRateController.clear();
    securityDepositController.clear();

    orderType = OrderType.sell;
    rentalStartDate = null;
    rentalEndDate = null;
    selectedItems.clear();
  }

  // ✅ Clone method for creating a copy
  OrderFormData clone() {
    final cloned = OrderFormData();

    cloned.customerNameController.text = customerNameController.text;
    cloned.customerEmailController.text = customerEmailController.text;
    cloned.customerPhoneController.text = customerPhoneController.text;
    cloned.shippingAddressController.text = shippingAddressController.text;
    cloned.notesController.text = notesController.text;
    cloned.dailyRateController.text = dailyRateController.text;
    cloned.securityDepositController.text = securityDepositController.text;

    cloned.orderType = orderType;
    cloned.rentalStartDate = rentalStartDate;
    cloned.rentalEndDate = rentalEndDate;
    cloned.selectedItems = Map.from(selectedItems);

    return cloned;
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
      rentalDurationDays:
      orderType == OrderType.rental ? calculatedRentalDays : null,
      dailyRate: orderType == OrderType.rental &&
          dailyRateController.text.isNotEmpty
          ? double.tryParse(dailyRateController.text)
          : null,
      securityDeposit: orderType == OrderType.rental &&
          securityDepositController.text.isNotEmpty
          ? double.tryParse(securityDepositController.text)
          : null,
      createdBy: 'Current User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ✅ Safe dispose with guard
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    customerNameController.dispose();
    customerEmailController.dispose();
    customerPhoneController.dispose();
    shippingAddressController.dispose();
    notesController.dispose();
    dailyRateController.dispose();
    securityDepositController.dispose();
  }
}

// ✅ Enhanced ValidationResult with additional info
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationErrorType? errorType;

  ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });

  factory ValidationResult.success() => ValidationResult._(isValid: true);

  factory ValidationResult.error(
      String message, {
        ValidationErrorType? type,
      }) =>
      ValidationResult._(
        isValid: false,
        errorMessage: message,
        errorType: type,
      );
}

// ✅ Error type enum for better error handling
enum ValidationErrorType {
  customerName,
  customerEmail,
  customerPhone,
  items,
  rentalStartDate,
  rentalEndDate,
  dailyRate,
  securityDeposit,
}

// ✅ Enhanced SelectedOrderItem with additional methods
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

  // ✅ Check if item has serial tracking
  bool get hasSerialNumbers => serialNumbers != null && serialNumbers!.isNotEmpty;

  // ✅ Get serial numbers count
  int get serialNumbersCount => serialNumbers?.length ?? 0;

  // ✅ Create a copy with updated values
  SelectedOrderItem copyWith({
    String? id,
    String? name,
    String? sku,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<String>? serialNumbers,
  }) {
    return SelectedOrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      serialNumbers: serialNumbers ?? this.serialNumbers,
    );
  }

  // ✅ Convert to JSON for debugging/logging
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'serialNumbers': serialNumbers,
    };
  }

  @override
  String toString() {
    return 'SelectedOrderItem(id: $id, name: $name, sku: $sku, qty: $quantity, price: $unitPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedOrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
