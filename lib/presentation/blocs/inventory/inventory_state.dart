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
  final int currentPage;
  final int totalItems;
  final bool isLoadingMore;

  const InventoryLoaded({
    required this.items,
    this.filteredItems = const [],
    this.hasReachedMax = false,
    this.searchQuery,
    this.activeFilters = const {},
    this.currentPage = 1,
    this.totalItems = 0,
    this.isLoadingMore = false,
  });

  @override
  List<Object> get props => [
    items,
    filteredItems,
    hasReachedMax,
    searchQuery ?? '',
    activeFilters,
    currentPage,
    totalItems,
    isLoadingMore,
  ];

  List<InventoryItem> get displayItems =>
      filteredItems.isNotEmpty ? filteredItems : items;

  int get totalItemsCount => items.length;
  int get lowStockCount => items.where((item) => item.isLowStock).length;
  double get totalValue => items.fold(0.0, (sum, item) => sum + item.totalValue);

  double get loadProgress => totalItems > 0 ? items.length / totalItems : 0.0;

  InventoryLoaded updateSingleItem(InventoryItem updatedItem) {
    final updatedItems = items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();

    final updatedFilteredItems = filteredItems.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();

    return InventoryLoaded(
      items: updatedItems,
      filteredItems: filteredItems.isNotEmpty ? updatedFilteredItems : [],
      hasReachedMax: hasReachedMax,
      searchQuery: searchQuery,
      activeFilters: activeFilters,
      currentPage: currentPage,
      totalItems: totalItems,
      isLoadingMore: isLoadingMore,
    );
  }

  InventoryLoaded removeSingleItem(String itemId) {
    final updatedItems = items.where((item) => item.id != itemId).toList();
    final updatedFilteredItems = filteredItems.where((item) => item.id != itemId).toList();

    return InventoryLoaded(
      items: updatedItems,
      filteredItems: filteredItems.isNotEmpty ? updatedFilteredItems : [],
      hasReachedMax: hasReachedMax,
      searchQuery: searchQuery,
      activeFilters: activeFilters,
      currentPage: currentPage,
      totalItems: totalItems - 1,
      isLoadingMore: isLoadingMore,
    );
  }

  InventoryLoaded addSingleItem(InventoryItem newItem) {
    final updatedItems = [...items, newItem];

    return InventoryLoaded(
      items: updatedItems,
      filteredItems: [],
      hasReachedMax: hasReachedMax,
      searchQuery: null,
      activeFilters: {},
      currentPage: currentPage,
      totalItems: totalItems + 1,
      isLoadingMore: isLoadingMore,
    );
  }

  InventoryLoaded copyWith({
    List<InventoryItem>? items,
    List<InventoryItem>? filteredItems,
    bool? hasReachedMax,
    String? searchQuery,
    Map<String, dynamic>? activeFilters,
    int? currentPage,
    int? totalItems,
    bool? isLoadingMore,
  }) {
    return InventoryLoaded(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilters: activeFilters ?? this.activeFilters,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
