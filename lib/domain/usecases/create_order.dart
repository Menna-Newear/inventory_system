import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class CreateOrder {
  final OrderRepository repository;

  CreateOrder(this.repository);

  Future<Either<Failure, Order>> call(Order order) async {
    return await repository.createOrder(order);
  }
}
