// domain/usecases/update_inventory_item.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class UpdateInventoryItem implements UseCase<InventoryItem, UpdateInventoryItemParams> {
  final InventoryRepository repository;

  UpdateInventoryItem(this.repository);

  @override
  Future<Either<Failure, InventoryItem>> call(UpdateInventoryItemParams params) async {
    return await repository.updateInventoryItem(params.item);
  }
}

class UpdateInventoryItemParams extends Equatable {
  final InventoryItem item;

  const UpdateInventoryItemParams(this.item);

  @override
  List<Object> get props => [item];
}
