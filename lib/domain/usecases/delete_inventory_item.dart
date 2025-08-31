// domain/usecases/delete_inventory_item.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/inventory_repository.dart';

class DeleteInventoryItem implements UseCase<void, DeleteInventoryItemParams> {
  final InventoryRepository repository;

  DeleteInventoryItem(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteInventoryItemParams params) async {
    return await repository.deleteInventoryItem(params.itemId);
  }
}

class DeleteInventoryItemParams extends Equatable {
  final String itemId;

  const DeleteInventoryItemParams(this.itemId);

  @override
  List<Object> get props => [itemId];
}
