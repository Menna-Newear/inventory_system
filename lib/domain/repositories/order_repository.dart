import 'package:dartz/dartz.dart' hide Order;

import '../../core/error/failures.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<Order>>> getOrders();
  Future<Either<Failure, Order>> createOrder(Order order);
  Future<Either<Failure, Order>> updateOrder(Order order);
  Future<Either<Failure, void>> deleteOrder(String id);
  Future<Either<Failure, Order>> approveOrder({
    required String orderId,
    required String approvedBy,
    String? notes,
  });
  Future<Either<Failure, Order>> rejectOrder({
    required String orderId,
    required String rejectedBy,
    required String reason,
  });
  Future<Either<Failure, List<Order>>> searchOrders(String query);
  Future<Either<Failure, List<Order>>> filterOrders(Map<String, dynamic> filters);
}
