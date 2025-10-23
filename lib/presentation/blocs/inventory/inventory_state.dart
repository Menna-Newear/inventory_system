// ✅ presentation/blocs/inventory/inventory_state.dart
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

  // ✅ NEW: Update a single item without refetching all data
  InventoryLoaded updateSingleItem(InventoryItem updatedItem) {
    // Update in main items list
    final updatedItems = items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();

    // Update in filtered items list (if it exists there)
    final updatedFilteredItems = filteredItems.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();

    return InventoryLoaded(
      items: updatedItems,
      filteredItems: filteredItems.isNotEmpty ? updatedFilteredItems : [],
      hasReachedMax: hasReachedMax,
      searchQuery: searchQuery,
      activeFilters: activeFilters,
    );
  }

  // ✅ NEW: Remove a single item without refetching
  InventoryLoaded removeSingleItem(String itemId) {
    final updatedItems = items.where((item) => item.id != itemId).toList();
    final updatedFilteredItems = filteredItems.where((item) => item.id != itemId).toList();

    return InventoryLoaded(
      items: updatedItems,
      filteredItems: filteredItems.isNotEmpty ? updatedFilteredItems : [],
      hasReachedMax: hasReachedMax,
      searchQuery: searchQuery,
      activeFilters: activeFilters,
    );
  }

  // ✅ NEW: Add a single item without refetching
  InventoryLoaded addSingleItem(InventoryItem newItem) {
    final updatedItems = [...items, newItem];

    // Also add to filtered items if filters/search would include it
    // For simplicity, we'll just reload filtered items on next search/filter

    return InventoryLoaded(
      items: updatedItems,
      filteredItems: [], // Clear filtered items, will be repopulated on next filter
      hasReachedMax: hasReachedMax,
      searchQuery: null, // Clear search query
      activeFilters: {}, // Clear filters
    );
  }

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
