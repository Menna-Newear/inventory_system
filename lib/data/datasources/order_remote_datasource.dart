// ✅ data/datasources/order_remote_datasource.dart (WITH CREATOR NAME FIX!)
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/order.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

// ✅ ABSTRACT CLASS (Interface)
abstract class OrderRemoteDataSource {
  // Basic CRUD operations
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> createOrder(OrderModel order);
  Future<OrderModel> updateOrder(OrderModel order);
  Future<void> deleteOrder(String id);
  Future<OrderModel> getOrderById(String orderId);

  // Order approval/rejection
  Future<OrderModel> approveOrder({
    required String orderId,
    required String approvedBy,
    String? notes,
  });
  Future<OrderModel> rejectOrder({
    required String orderId,
    required String rejectedBy,
    required String reason,
  });

  // Search and filter
  Future<List<OrderModel>> searchOrders(String query);
  Future<List<OrderModel>> filterOrders(Map<String, dynamic> filters);

  // ✅ NEW: Rental-specific methods
  Future<List<OrderModel>> getActiveRentals();
  Future<List<OrderModel>> getOverdueRentals();
  Future<OrderModel> returnRental(String orderId);

  // ✅ NEW: Statistics
  Future<Map<String, dynamic>> getOrderStats();
}

// ✅ IMPLEMENTATION CLASS
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient supabase;

  OrderRemoteDataSourceImpl({required this.supabase});

  // ✅ UPDATED: getOrders with creator name join
  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      print('🔍 DEBUG: Loading orders with items, rental data, and creator info...');

      final response = await supabase
          .from('orders')
          .select('''
      *,
      order_items!fk_order_items_orders (
        id,
        item_id,
        item_name,
        item_sku,
        quantity,
        unit_price,
        total_price,
        serial_numbers,
        notes
      )
    ''')
          .order('created_at', ascending: false);
      print('🔍 DEBUG: Loaded ${response.length} orders from database');

      return (response as List).map<OrderModel>((json) {
        print('🔍 DEBUG: Processing order ${json['order_number']} (${json['order_type']})');

        final itemsData = json['order_items'] as List<dynamic>?;
        final items = itemsData
            ?.map((itemJson) {
          try {
            return OrderItemModel.fromJson(itemJson as Map<String, dynamic>);
          } catch (e) {
            print('❌ ERROR converting item: $e');
            return null;
          }
        })
            .where((item) => item != null)
            .cast<OrderItem>()
            .toList() ?? [];

        final orderModel = OrderModel.fromJson(json);
        return orderModel.copyWithItems(items);
      }).toList();
    } catch (e) {
      print('❌ ERROR loading orders: $e');
      throw Exception('Failed to load orders: $e');
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      print('🔍 DEBUG: Creating ${order.orderType.displayName} order with ${order.items.length} items');

      // ✅ Debug: Log each item and its serial numbers BEFORE saving
      for (var item in order.items) {
        print('📦 DEBUG: Item "${item.itemName}" (ID: ${item.itemId})');
        print('   - Quantity: ${item.quantity}');
        if (item.serialNumbers != null && item.serialNumbers!.isNotEmpty) {
          print('   - ✅ Has ${item.serialNumbers!.length} serial numbers');
          print('   - Serial IDs: ${item.serialNumbers}');
        } else {
          print('   - ℹ️ No serial numbers (non-serial-tracked item)');
        }
      }

      final orderData = {
        'order_number': order.orderNumber,
        'status': order.status.name,
        'order_type': order.orderType.name,
        'customer_name': order.customerName,
        'customer_email': order.customerEmail,
        'customer_phone': order.customerPhone,
        'shipping_address': order.shippingAddress,
        'notes': order.notes,
        'total_amount': order.totalAmount,
        if (order.isRental && order.rentalStartDate != null)
          'rental_start_date': order.rentalStartDate!.toIso8601String().split('T')[0],
        if (order.isRental && order.rentalEndDate != null)
          'rental_end_date': order.rentalEndDate!.toIso8601String().split('T')[0],
        if (order.isRental && order.rentalDurationDays != null)
          'rental_duration_days': order.rentalDurationDays,
        if (order.isRental && order.dailyRate != null)
          'daily_rate': order.dailyRate,
        if (order.isRental && order.securityDeposit != null)
          'security_deposit': order.securityDeposit,
        'created_by': order.createdBy,
        'created_at': order.createdAt.toIso8601String(),
        'updated_at': order.updatedAt.toIso8601String(),
      };

      print('📤 DEBUG: Inserting order into database...');
      final orderResponse = await supabase
          .from('orders')
          .insert(orderData)
          .select('*, creator:users!orders_created_by_fkey(id, name, email)')
          .single();

      final createdOrderId = orderResponse['id'] as String;
      print('✅ DEBUG: Order created with ID: $createdOrderId');

      if (order.items.isNotEmpty) {
        final orderItemsData = order.items.map((item) {
          final itemData = {
            'order_id': createdOrderId,
            'item_id': item.itemId,
            'item_name': item.itemName,
            'item_sku': item.itemSku,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'total_price': item.totalPrice,
            'serial_numbers': item.serialNumbers,
            'notes': item.notes,
            'created_at': DateTime.now().toIso8601String(),
          };

          print('📤 DEBUG: Inserting order item:');
          print('   - Item: ${item.itemName}');
          print('   - Serial numbers field: ${itemData['serial_numbers']}');

          return itemData;
        }).toList();

        print('📤 DEBUG: Inserting ${orderItemsData.length} order items...');
        await supabase
            .from('order_items')
            .insert(orderItemsData);

        print('✅ DEBUG: Order items inserted successfully');
      }

      final createdOrder = OrderModel.fromJson(orderResponse);
      print('✅ DEBUG: Order creation complete!');
      return createdOrder.copyWithItems(order.items);
    } catch (e, stackTrace) {
      print('❌ ERROR creating order: $e');
      print('❌ STACK TRACE: $stackTrace');
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Future<OrderModel> updateOrder(OrderModel order) async {
    try {
      final orderData = order.toJson();
      orderData['updated_at'] = DateTime.now().toIso8601String();

      final orderResponse = await supabase
          .from('orders')
          .update(orderData)
          .eq('id', order.id)
          .select('*, creator:users!orders_created_by_fkey(id, name, email)')
          .single();

      final updatedOrder = OrderModel.fromJson(orderResponse);

      await supabase
          .from('order_items')
          .delete()
          .eq('order_id', order.id);

      List<OrderItem> updatedItems = [];
      if (order.items.isNotEmpty) {
        final orderItems = order.items.map((item) {
          final itemModel = OrderItemModel.fromEntity(item);
          final itemData = itemModel.toJson();
          itemData['order_id'] = order.id;
          return itemData;
        }).toList();

        final itemsResponse = await supabase
            .from('order_items')
            .insert(orderItems)
            .select();

        updatedItems = (itemsResponse as List)
            .map((json) => OrderItemModel.fromJson(json))
            .cast<OrderItem>()
            .toList();
      }

      return updatedOrder.copyWithItems(updatedItems);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  @override
  Future<void> deleteOrder(String id) async {
    try {
      await supabase.from('orders').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  @override
  Future<OrderModel> approveOrder({
    required String orderId,
    required String approvedBy,
    String? notes,
  }) async {
    try {
      final response = await supabase
          .from('orders')
          .update({
        'status': 'approved',
        'approved_by': approvedBy,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      })
          .eq('id', orderId)
          .select('''
            *,
            order_items (
              item_id,
              item_name,
              item_sku,
              quantity,
              unit_price,
              total_price,
              serial_numbers,
              notes
            ),
            creator:users!orders_created_by_fkey(id, name, email)
          ''')
          .single();

      final orderModel = OrderModel.fromJson(response);
      final items = (response['order_items'] as List<dynamic>?)
          ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
          .cast<OrderItem>()
          .toList() ?? [];

      return orderModel.copyWithItems(items);
    } catch (e) {
      throw Exception('Failed to approve order: $e');
    }
  }

  @override
  Future<OrderModel> rejectOrder({
    required String orderId,
    required String rejectedBy,
    required String reason,
  }) async {
    try {
      final response = await supabase
          .from('orders')
          .update({
        'status': 'rejected',
        'rejected_by': rejectedBy,
        'rejected_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId)
          .select('''
            *,
            order_items (
              item_id,
              item_name,
              item_sku,
              quantity,
              unit_price,
              total_price,
              serial_numbers,
              notes
            ),
            creator:users!orders_created_by_fkey(id, name, email)
          ''')
          .single();

      final orderModel = OrderModel.fromJson(response);
      final items = (response['order_items'] as List<dynamic>?)
          ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
          .cast<OrderItem>()
          .toList() ?? [];

      return orderModel.copyWithItems(items);
    } catch (e) {
      throw Exception('Failed to reject order: $e');
    }
  }

  @override
  Future<List<OrderModel>> searchOrders(String query) async {
    try {
      final response = await supabase
          .from('orders')
          .select('''
            *,
            order_items (
              item_id,
              item_name,
              item_sku,
              quantity,
              unit_price,
              total_price,
              serial_numbers,
              notes
            ),
            creator:users!orders_created_by_fkey(id, name, email)
          ''')
          .or('order_number.ilike.%$query%,customer_name.ilike.%$query%,customer_email.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List).map<OrderModel>((json) {
        final orderModel = OrderModel.fromJson(json);
        final items = (json['order_items'] as List<dynamic>?)
            ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
            .cast<OrderItem>()
            .toList() ?? [];
        return orderModel.copyWithItems(items);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }

  @override
  Future<List<OrderModel>> filterOrders(Map<String, dynamic> filters) async {
    try {
      var query = supabase.from('orders').select('''
        *,
        order_items (
          item_id,
          item_name,
          item_sku,
          quantity,
          unit_price,
          total_price,
          serial_numbers,
          notes
        ),
        creator:users!orders_created_by_fkey(id, name, email)
      ''');

      filters.forEach((key, value) {
        if (value != null) {
          switch (key) {
            case 'status':
              query = query.eq('status', value);
              break;
            case 'order_type':
              query = query.eq('order_type', value);
              break;
            case 'min_amount':
              query = query.gte('total_amount', value);
              break;
            case 'max_amount':
              query = query.lte('total_amount', value);
              break;
            case 'created_after':
              query = query.gte('created_at', value);
              break;
            case 'created_before':
              query = query.lte('created_at', value);
              break;
            case 'rental_start_after':
              query = query.gte('rental_start_date', value);
              break;
            case 'rental_start_before':
              query = query.lte('rental_start_date', value);
              break;
            case 'rental_end_after':
              query = query.gte('rental_end_date', value);
              break;
            case 'rental_end_before':
              query = query.lte('rental_end_date', value);
              break;
            case 'min_daily_rate':
              query = query.gte('daily_rate', value);
              break;
            case 'max_daily_rate':
              query = query.lte('daily_rate', value);
              break;
            case 'customer_name':
              query = query.ilike('customer_name', '%$value%');
              break;
            case 'approved_by':
              query = query.eq('approved_by', value);
              break;
          }
        }
      });

      final response = await query.order('created_at', ascending: false);

      return (response as List).map<OrderModel>((json) {
        final orderModel = OrderModel.fromJson(json);
        final items = (json['order_items'] as List<dynamic>?)
            ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
            .cast<OrderItem>()
            .toList() ?? [];
        return orderModel.copyWithItems(items);
      }).toList();
    } catch (e) {
      throw Exception('Failed to filter orders: $e');
    }
  }

  @override
  Future<List<OrderModel>> getActiveRentals() async {
    try {
      final now = DateTime.now().toIso8601String().split('T')[0];

      final response = await supabase
          .from('orders')
          .select('''
            *,
            order_items (
              item_id,
              item_name,
              item_sku,
              quantity,
              unit_price,
              total_price,
              serial_numbers,
              notes
            ),
            creator:users!orders_created_by_fkey(id, name, email)
          ''')
          .eq('order_type', 'rental')
          .eq('status', 'approved')
          .lte('rental_start_date', now)
          .gte('rental_end_date', now)
          .order('rental_end_date', ascending: true);

      return (response as List).map<OrderModel>((json) {
        final orderModel = OrderModel.fromJson(json);
        final items = (json['order_items'] as List<dynamic>?)
            ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
            .cast<OrderItem>()
            .toList() ?? [];
        return orderModel.copyWithItems(items);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get active rentals: $e');
    }
  }

  @override
  Future<List<OrderModel>> getOverdueRentals() async {
    try {
      final now = DateTime.now().toIso8601String().split('T')[0];

      final response = await supabase
          .from('orders')
          .select('''
            *,
            order_items (
              item_id,
              item_name,
              item_sku,
              quantity,
              unit_price,
              total_price,
              serial_numbers,
              notes
            ),
            creator:users!orders_created_by_fkey(id, name, email)
          ''')
          .eq('order_type', 'rental')
          .eq('status', 'approved')
          .lt('rental_end_date', now)
          .order('rental_end_date', ascending: true);

      return (response as List).map<OrderModel>((json) {
        final orderModel = OrderModel.fromJson(json);
        final items = (json['order_items'] as List<dynamic>?)
            ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
            .cast<OrderItem>()
            .toList() ?? [];
        return orderModel.copyWithItems(items);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get overdue rentals: $e');
    }
  }

  @override
  Future<OrderModel> returnRental(String orderId) async {
    try {
      final response = await supabase
          .from('orders')
          .update({
        'status': 'returned',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId)
          .eq('order_type', 'rental')
          .select('''
            *,
            order_items (
              item_id,
              item_name,
              item_sku,
              quantity,
              unit_price,
              total_price,
              serial_numbers,
              notes
            ),
            creator:users!orders_created_by_fkey(id, name, email)
          ''')
          .single();

      final orderModel = OrderModel.fromJson(response);
      final items = (response['order_items'] as List<dynamic>?)
          ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
          .cast<OrderItem>()
          .toList() ?? [];

      return orderModel.copyWithItems(items);
    } catch (e) {
      throw Exception('Failed to return rental: $e');
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await supabase
          .from('orders')
          .select('''
            *,
            order_items (
              item_id,
              item_name,
              item_sku,
              quantity,
              unit_price,
              total_price,
              serial_numbers,
              notes
            ),
            creator:users!orders_created_by_fkey(id, name, email)
          ''')
          .eq('id', orderId)
          .single();

      final orderModel = OrderModel.fromJson(response);
      final items = (response['order_items'] as List<dynamic>?)
          ?.map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
          .cast<OrderItem>()
          .toList() ?? [];

      return orderModel.copyWithItems(items);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final statusStats = await supabase
          .from('orders')
          .select('status')
          .then((data) {
        final orders = data as List;
        final stats = <String, int>{};
        for (final order in orders) {
          final status = order['status'] as String;
          stats[status] = (stats[status] ?? 0) + 1;
        }
        return stats;
      });

      final typeStats = await supabase
          .from('orders')
          .select('order_type')
          .then((data) {
        final orders = data as List;
        final stats = <String, int>{};
        for (final order in orders) {
          final type = order['order_type'] as String;
          stats[type] = (stats[type] ?? 0) + 1;
        }
        return stats;
      });

      final totalStats = await supabase
          .from('orders')
          .select('total_amount, order_type')
          .then((data) {
        final orders = data as List;
        final totalOrders = orders.length;
        final totalRevenue = orders.fold<double>(
            0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

        final sellRevenue = orders
            .where((order) => order['order_type'] == 'sell')
            .fold<double>(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

        final rentalRevenue = orders
            .where((order) => order['order_type'] == 'rental')
            .fold<double>(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

        return {
          'total_orders': totalOrders,
          'total_revenue': totalRevenue,
          'sell_revenue': sellRevenue,
          'rental_revenue': rentalRevenue,
        };
      });

      return {
        'status_stats': statusStats,
        'type_stats': typeStats,
        ...totalStats,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }
}
