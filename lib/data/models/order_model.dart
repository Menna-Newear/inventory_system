// ✅ data/models/order_model.dart (FIXED - NO FOREIGN KEY JOIN)
import '../../domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.orderType,
    required super.items,
    super.customerName,
    super.customerEmail,
    super.customerPhone,
    super.shippingAddress,
    super.notes,
    required super.totalAmount,
    super.rentalStartDate,
    super.rentalEndDate,
    super.rentalDurationDays,
    super.dailyRate,
    super.securityDeposit,
    super.approvedBy,
    super.approvedAt,
    super.rejectedBy,
    super.rejectedAt,
    super.rejectionReason,
    required super.createdBy,
    super.createdByName,
    required super.createdAt,
    required super.updatedAt,
  });

  // ✅ FIXED: Convert from JSON without foreign key join
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // ✅ SIMPLE FIX: Just use the created_by value directly
    final createdByValue = json['created_by'] as String? ?? 'System';

    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.draft,
      ),
      orderType: OrderType.values.firstWhere(
            (e) => e.toString().split('.').last == json['order_type'],
        orElse: () => OrderType.sell,
      ),
      items: [], // Will be loaded separately via joins or separate queries
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      shippingAddress: json['shipping_address'],
      notes: json['notes'],
      totalAmount: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : 0.0,
      rentalStartDate: json['rental_start_date'] != null
          ? DateTime.parse(json['rental_start_date'])
          : null,
      rentalEndDate: json['rental_end_date'] != null
          ? DateTime.parse(json['rental_end_date'])
          : null,
      rentalDurationDays: json['rental_duration_days'] as int?,
      dailyRate: json['daily_rate'] != null
          ? (json['daily_rate'] as num).toDouble()
          : null,
      securityDeposit: json['security_deposit'] != null
          ? (json['security_deposit'] as num).toDouble()
          : null,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectedBy: json['rejected_by'],
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      createdBy: createdByValue,
      createdByName: createdByValue, // ✅ FIXED: Use the same text value
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // ✅ Convert to JSON (for database/API requests) - WITHOUT items
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'order_number': orderNumber,
      'status': status.toString().split('.').last,
      'order_type': orderType.toString().split('.').last,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'shipping_address': shippingAddress,
      'notes': notes,
      'total_amount': totalAmount,
      'rental_start_date': rentalStartDate?.toIso8601String().split('T')[0],
      'rental_end_date': rentalEndDate?.toIso8601String().split('T')[0],
      'rental_duration_days': rentalDurationDays,
      'daily_rate': dailyRate,
      'security_deposit': securityDeposit,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_by': rejectedBy,
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ✅ Convert from domain entity to model
  factory OrderModel.fromEntity(Order entity) {
    return OrderModel(
      id: entity.id,
      orderNumber: entity.orderNumber,
      status: entity.status,
      orderType: entity.orderType,
      items: entity.items,
      customerName: entity.customerName,
      customerEmail: entity.customerEmail,
      customerPhone: entity.customerPhone,
      shippingAddress: entity.shippingAddress,
      notes: entity.notes,
      totalAmount: entity.totalAmount,
      rentalStartDate: entity.rentalStartDate,
      rentalEndDate: entity.rentalEndDate,
      rentalDurationDays: entity.rentalDurationDays,
      dailyRate: entity.dailyRate,
      securityDeposit: entity.securityDeposit,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      rejectedBy: entity.rejectedBy,
      rejectedAt: entity.rejectedAt,
      rejectionReason: entity.rejectionReason,
      createdBy: entity.createdBy,
      createdByName: entity.createdByName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // ✅ Convert model to domain entity (inherited from Order)
  Order toEntity() => this;

  // ✅ Helper method to create model with items
  OrderModel copyWithItems(List<OrderItem> orderItems) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      status: status,
      orderType: orderType,
      items: orderItems,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      shippingAddress: shippingAddress,
      notes: notes,
      totalAmount: totalAmount,
      rentalStartDate: rentalStartDate,
      rentalEndDate: rentalEndDate,
      rentalDurationDays: rentalDurationDays,
      dailyRate: dailyRate,
      securityDeposit: securityDeposit,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      rejectedBy: rejectedBy,
      rejectedAt: rejectedAt,
      rejectionReason: rejectionReason,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
