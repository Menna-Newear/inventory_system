// ✅ data/models/order_item_model.dart
import '../../domain/entities/order.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.itemId,
    required super.itemName,
    required super.itemSku,
    required super.quantity,
    super.unitPrice,
    super.totalPrice,
    super.serialNumbers,
    super.notes,
  });

  // ✅ Convert from JSON (database/API response)
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? '',
      itemSku: json['item_sku'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: json['unit_price'] != null
          ? (json['unit_price'] as num).toDouble()
          : null,
      totalPrice: json['total_price'] != null
          ? (json['total_price'] as num).toDouble()
          : null,
      serialNumbers: json['serial_numbers'] != null
          ? List<String>.from(json['serial_numbers'])
          : null,
      notes: json['notes'],
    );
  }

  // ✅ Convert to JSON (for database/API requests)
  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'item_sku': itemSku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'serial_numbers': serialNumbers,
      'notes': notes,
    };
  }

  // ✅ Convert from domain entity to model
  factory OrderItemModel.fromEntity(OrderItem entity) {
    return OrderItemModel(
      itemId: entity.itemId,
      itemName: entity.itemName,
      itemSku: entity.itemSku,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      serialNumbers: entity.serialNumbers,
      notes: entity.notes,
    );
  }

  // ✅ Convert model to domain entity (inherited from OrderItem)
  OrderItem toEntity() => this;
}
