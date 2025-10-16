import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class ApproveOrder {
  final OrderRepository repository;

  ApproveOrder(this.repository);

  Future<Either<Failure, Order>> call({
    required String orderId,
    required String approvedBy,
    String? notes,
  }) async {
    return await repository.approveOrder(
      orderId: orderId,
      approvedBy: approvedBy,
      notes: notes,
    );
  }
}
