// ✅ domain/usecases/get_inventory_items.dart
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryItems implements UseCase<List<InventoryItem>, NoParams> {
  final InventoryRepository repository;

  GetInventoryItems(this.repository);

  @override
  Future<Either<Failure, List<InventoryItem>>> call(NoParams params) async {
    return await repository.getAllInventoryItems();
  }
}
