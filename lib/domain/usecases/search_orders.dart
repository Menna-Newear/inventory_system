import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class SearchOrders {
  final OrderRepository repository;

  SearchOrders(this.repository);

  Future<Either<Failure, List<Order>>> call(String query) async {
    return await repository.searchOrders(query);
  }
}
