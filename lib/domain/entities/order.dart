// ✅ domain/entities/order.dart (COMPLETE UPDATED VERSION)
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ✅ Keep your existing OrderStatus - it's perfect
enum OrderStatus {
  draft,
  pending,
  approved,
  rejected,
  processing,
  shipped,
  delivered,
  cancelled,
  returned;

  String get displayName {
    switch (this) {
      case OrderStatus.draft:
        return 'Draft';
      case OrderStatus.pending:
        return 'Pending Approval';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  // ✅ Keep your existing color coding
  Color get statusColor {
    switch (this) {
      case OrderStatus.draft:
        return Colors.grey;
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.approved:
        return Colors.blue;
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.processing:
        return Colors.indigo;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red[700]!;
      case OrderStatus.returned:
        return Colors.amber[800]!;
    }
  }
}

// ✅ NEW: Replace OrderPriority with OrderType
enum OrderType {
  sell,
  rental;

  String get displayName {
    switch (this) {
      case OrderType.sell:
        return 'Sale';
      case OrderType.rental:
        return 'Rental';
    }
  }

  Color get typeColor {
    switch (this) {
      case OrderType.sell:
        return Colors.blue;
      case OrderType.rental:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.sell:
        return Icons.shopping_cart;
      case OrderType.rental:
        return Icons.access_time;
    }
  }

  String get description {
    switch (this) {
      case OrderType.sell:
        return 'One-time purchase';
      case OrderType.rental:
        return 'Time-based rental';
    }
  }
}

// ✅ Keep your existing OrderItem - it's perfect
class OrderItem extends Equatable {
  final String itemId;
  final String itemName;
  final String itemSku;
  final int quantity;
  final double? unitPrice;
  final double? totalPrice;
  final List<String>? serialNumbers; // For serial-tracked items
  final String? notes;


  const OrderItem({
    required this.itemId,
    required this.itemName,
    required this.itemSku,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.serialNumbers,
    this.notes,
  });

  // ✅ Keep your copyWith method - it's perfect
  OrderItem copyWith({
    String? itemId,
    String? itemName,
    String? itemSku,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<String>? serialNumbers,
    String? notes,
  }) {
    return OrderItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemSku: itemSku ?? this.itemSku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      serialNumbers: serialNumbers ?? this.serialNumbers,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    itemId,
    itemName,
    itemSku,
    quantity,
    unitPrice,
    totalPrice,
    serialNumbers,
    notes,
  ];
}

// ✅ UPDATED: Order class with OrderType and rental functionality
class Order extends Equatable {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final OrderType orderType; // ✅ NEW: Replace priority
  final List<OrderItem> items;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? shippingAddress;
  final String? notes;
  final double totalAmount;

  // ✅ NEW: Rental-specific fields
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final int? rentalDurationDays;
  final double? dailyRate;
  final double? securityDeposit;

  // ✅ Keep existing approval/rejection fields
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String createdBy;
  final String? createdByName;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.orderType, // ✅ NEW: Replace priority
    required this.items,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    this.notes,
    required this.totalAmount,
    // ✅ NEW: Rental fields
    this.rentalStartDate,
    this.rentalEndDate,
    this.rentalDurationDays,
    this.dailyRate,
    this.securityDeposit,
    // Keep existing fields
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ Keep your existing business logic methods
  bool get isPending => status == OrderStatus.pending;
  bool get isApproved => status == OrderStatus.approved;
  bool get isRejected => status == OrderStatus.rejected;
  bool get canBeApproved => status == OrderStatus.pending;
  bool get canBeRejected => status == OrderStatus.pending || status == OrderStatus.approved;
  bool get requiresApproval => status == OrderStatus.pending && totalAmount > 1000.0;

  // ✅ NEW: Rental-specific business logic
  bool get isRental => orderType == OrderType.rental;
  bool get isSale => orderType == OrderType.sell;

  bool get isRentalActive {
    if (!isRental || rentalStartDate == null || rentalEndDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(rentalStartDate!) && now.isBefore(rentalEndDate!.add(Duration(days: 1)));
  }

  bool get isRentalOverdue {
    if (!isRental || rentalEndDate == null) return false;
    return DateTime.now().isAfter(rentalEndDate!.add(Duration(days: 1)));
  }

  Duration? get rentalDuration {
    if (rentalStartDate != null && rentalEndDate != null) {
      return rentalEndDate!.difference(rentalStartDate!);
    }
    return null;
  }

  int get calculatedRentalDays {
    final duration = rentalDuration;
    return duration != null ? duration.inDays + 1 : (rentalDurationDays ?? 0);
  }

  double get totalRentalAmount {
    if (isRental && dailyRate != null) {
      final days = calculatedRentalDays;
      return (dailyRate! * days) + (securityDeposit ?? 0.0);
    }
    return totalAmount;
  }

  double get totalAmountWithDeposit {
    return totalAmount + (securityDeposit ?? 0.0);
  }

  String get statusDisplayText {
    // ✅ Enhanced status display for rentals
    if (isRental && status == OrderStatus.approved && rentalStartDate != null) {
      if (isRentalActive) {
        return 'Active Rental';
      } else if (isRentalOverdue) {
        return 'Overdue Rental';
      } else if (DateTime.now().isBefore(rentalStartDate!)) {
        return 'Rental Scheduled';
      }
    }

    if (status == OrderStatus.pending && requiresApproval) {
      return 'Pending Approval (High Value)';
    }
    return status.displayName;
  }

  String get orderSummary {
    final itemCount = items.length;
    final quantityCount = items.fold(0, (sum, item) => sum + item.quantity);

    if (isRental && rentalDurationDays != null) {
      return '$itemCount items ($quantityCount units) for $rentalDurationDays days';
    } else {
      return '$itemCount items ($quantityCount units)';
    }
  }

  // ✅ UPDATED: copyWith method with new fields
  Order copyWith({
    String? id,
    String? orderNumber,
    OrderStatus? status,
    OrderType? orderType, // ✅ NEW
    List<OrderItem>? items,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? shippingAddress,
    String? notes,
    double? totalAmount,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
    int? rentalDurationDays,
    double? dailyRate,
    double? securityDeposit,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? createdBy,
    String? createdByName,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType, // ✅ NEW
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      notes: notes ?? this.notes,
      totalAmount: totalAmount ?? this.totalAmount,
      // ✅ NEW: Rental fields
      rentalStartDate: rentalStartDate ?? this.rentalStartDate,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
      rentalDurationDays: rentalDurationDays ?? this.rentalDurationDays,
      dailyRate: dailyRate ?? this.dailyRate,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      // Keep existing fields
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ UPDATED: props list with new fields
  @override
  List<Object?> get props => [
    id,
    orderNumber,
    status,
    orderType,
    items,
    customerName,
    customerEmail,
    customerPhone,
    shippingAddress,
    notes,
    totalAmount,
    rentalStartDate,
    rentalEndDate,
    rentalDurationDays,
    dailyRate,
    securityDeposit,
    approvedBy,
    approvedAt,
    rejectedBy,
    rejectedAt,
    rejectionReason,
    createdBy,
    createdByName,
    createdAt,
    updatedAt,
  ];
}
