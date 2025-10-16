import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/order_repository.dart';

class DeleteOrder {
  final OrderRepository repository;

  DeleteOrder(this.repository);

  Future<Either<Failure, void>> call(String orderId) async {
    return await repository.deleteOrder(orderId);
  }
}
