import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class GetOrders {
  final OrderRepository repository;

  GetOrders(this.repository);

  Future<Either<Failure, List<Order>>> call() async {
    return await repository.getOrders();
  }
}
