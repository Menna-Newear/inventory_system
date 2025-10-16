import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class UpdateOrder {
  final OrderRepository repository;

  UpdateOrder(this.repository);

  Future<Either<Failure, Order>> call(Order order) async {
    return await repository.updateOrder(order);
  }
}
