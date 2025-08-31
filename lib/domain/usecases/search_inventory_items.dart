// domain/usecases/search_inventory_items.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class SearchInventoryItems implements UseCase<List<InventoryItem>, SearchInventoryItemsParams> {
  final InventoryRepository repository;

  SearchInventoryItems(this.repository);

  @override
  Future<Either<Failure, List<InventoryItem>>> call(SearchInventoryItemsParams params) async {
    if (params.query.trim().isEmpty) {
      return await repository.getAllInventoryItems();
    }
    return await repository.searchInventoryItems(params.query);
  }
}

class SearchInventoryItemsParams extends Equatable {
  final String query;

  const SearchInventoryItemsParams(this.query);

  @override
  List<Object> get props => [query];
}
