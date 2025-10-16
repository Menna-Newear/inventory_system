import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class FilterOrders {
  final OrderRepository repository;

  FilterOrders(this.repository);

  Future<Either<Failure, List<Order>>> call(Map<String, dynamic> filters) async {
    return await repository.filterOrders(filters);
  }
}
