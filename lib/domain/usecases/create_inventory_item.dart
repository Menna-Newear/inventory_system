// domain/usecases/create_inventory_item.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class CreateInventoryItem implements UseCase<InventoryItem, CreateInventoryItemParams> {
  final InventoryRepository repository;

  CreateInventoryItem(this.repository);

  @override
  Future<Either<Failure, InventoryItem>> call(CreateInventoryItemParams params) async {
    return await repository.createInventoryItem(params.item);
  }
}

class CreateInventoryItemParams extends Equatable {
  final InventoryItem item;

  const CreateInventoryItemParams(this.item);

  @override
  List<Object> get props => [item];
}
