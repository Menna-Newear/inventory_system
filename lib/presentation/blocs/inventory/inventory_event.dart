// presentation/blocs/inventory/inventory_event.dart
part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

class LoadInventoryItems extends InventoryEvent {}

class RefreshInventoryItems extends InventoryEvent {}

// ✅ NEW EVENT
class RefreshSingleItem extends InventoryEvent {
  final String itemId;

  const RefreshSingleItem(this.itemId);

  @override
  List<Object> get props => [itemId];
}

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
