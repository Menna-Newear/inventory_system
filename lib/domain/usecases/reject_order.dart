import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class RejectOrder {
  final OrderRepository repository;

  RejectOrder(this.repository);

  Future<Either<Failure, Order>> call({
    required String orderId,
    required String rejectedBy,
    required String reason,
  }) async {
    return await repository.rejectOrder(
      orderId: orderId,
      rejectedBy: rejectedBy,
      reason: reason,
    );
  }
}
