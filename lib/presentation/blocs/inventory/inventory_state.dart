// presentation/blocs/inventory/inventory_state.dart
part of 'inventory_bloc.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  final List<InventoryItem> filteredItems;
  final bool hasReachedMax;
  final String? searchQuery;
  final Map<String, dynamic> activeFilters;

  const InventoryLoaded({
    required this.items,
    this.filteredItems = const [],
    this.hasReachedMax = false,
    this.searchQuery,
    this.activeFilters = const {},
  });

  @override
  List<Object> get props => [
    items,
    filteredItems,
    hasReachedMax,
    searchQuery ?? '',
    activeFilters
  ];

  List<InventoryItem> get displayItems =>
      filteredItems.isNotEmpty ? filteredItems : items;

  int get totalItems => items.length;
  int get lowStockCount => items.where((item) => item.isLowStock).length;
  double get totalValue => items.fold(0.0, (sum, item) => sum + item.totalValue);

  InventoryLoaded copyWith({
    List<InventoryItem>? items,
    List<InventoryItem>? filteredItems,
    bool? hasReachedMax,
    String? searchQuery,
    Map<String, dynamic>? activeFilters,
  }) {
    return InventoryLoaded(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object> get props => [message];
}

class InventoryItemCreated extends InventoryState {
  final InventoryItem item;

  const InventoryItemCreated(this.item);

  @override
  List<Object> get props => [item];
}

class InventoryItemUpdated extends InventoryState {
  final InventoryItem item;

  const InventoryItemUpdated(this.item);

  @override
  List<Object> get props => [item];
}

class InventoryItemDeleted extends InventoryState {
  final String itemId;

  const InventoryItemDeleted(this.itemId);

  @override
  List<Object> get props => [itemId];
}
