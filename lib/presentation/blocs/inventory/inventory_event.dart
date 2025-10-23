// ✅ presentation/blocs/inventory/inventory_event.dart
part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

class LoadInventoryItems extends InventoryEvent {}

class RefreshInventoryItems extends InventoryEvent {}

class RefreshSingleItem extends InventoryEvent {
  final String itemId;

  const RefreshSingleItem(this.itemId);

  @override
  List<Object> get props => [itemId];
}

// ✅ NEW: Pagination events
class LoadInventoryItemsPage extends InventoryEvent {
  final int page;
  final int pageSize;

  const LoadInventoryItemsPage({
    required this.page,
    this.pageSize = 50,
  });

  @override
  List<Object> get props => [page, pageSize];
}

class LoadMoreInventoryItems extends InventoryEvent {}

class CreateInventoryItem extends InventoryEvent {
  final InventoryItem item;

  const CreateInventoryItem(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateInventoryItem extends InventoryEvent {
  final InventoryItem item;

  const UpdateInventoryItem(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteInventoryItem extends InventoryEvent {
  final String itemId;

  const DeleteInventoryItem(this.itemId);

  @override
  List<Object> get props => [itemId];
}

class SearchInventoryItems extends InventoryEvent {
  final String query;

  const SearchInventoryItems(this.query);

  @override
  List<Object> get props => [query];
}

class FilterInventoryItems extends InventoryEvent {
  final Map<String, dynamic> filters;

  const FilterInventoryItems(this.filters);

  @override
  List<Object> get props => [filters];
}

class ClearFilters extends InventoryEvent {}
