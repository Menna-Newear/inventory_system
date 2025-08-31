// domain/usecases/filter_inventory_items.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class FilterInventoryItems implements UseCase<List<InventoryItem>, FilterInventoryItemsParams> {
  final InventoryRepository repository;

  FilterInventoryItems(this.repository);

  @override
  Future<Either<Failure, List<InventoryItem>>> call(FilterInventoryItemsParams params) async {
    if (params.filters.isEmpty) {
      return await repository.getAllInventoryItems();
    }
    return await repository.filterInventoryItems(params.filters);
  }
}

class FilterInventoryItemsParams extends Equatable {
  final Map<String, dynamic> filters;

  const FilterInventoryItemsParams(this.filters);

  @override
  List<Object> get props => [filters];
}
