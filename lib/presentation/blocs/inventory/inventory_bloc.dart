// ✅ presentation/blocs/inventory/inventory_bloc.dart (COMPLETE WITH SPECIFIC ITEM REFRESH)
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/inventory_item.dart';
import '../../../domain/usecases/get_inventory_items.dart' as get_items_usecase;
import '../../../domain/usecases/create_inventory_item.dart' as create_item_usecase;
import '../../../domain/usecases/update_inventory_item.dart' as update_item_usecase;
import '../../../domain/usecases/delete_inventory_item.dart' as delete_item_usecase;
import '../../../domain/usecases/search_inventory_items.dart' as search_items_usecase;
import '../../../domain/usecases/filter_inventory_items.dart' as filter_items_usecase;
import '../../../data/services/stock_management_service.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final get_items_usecase.GetInventoryItems getInventoryItems;
  final create_item_usecase.CreateInventoryItem createInventoryItem;
  final update_item_usecase.UpdateInventoryItem updateInventoryItem;
  final delete_item_usecase.DeleteInventoryItem deleteInventoryItem;
  final search_items_usecase.SearchInventoryItems searchInventoryItems;
  final filter_items_usecase.FilterInventoryItems filterInventoryItems;

  InventoryBloc({
    required this.getInventoryItems,
    required this.createInventoryItem,
    required this.updateInventoryItem,
    required this.deleteInventoryItem,
    required this.searchInventoryItems,
    required this.filterInventoryItems,
  }) : super(InventoryInitial()) {
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<LoadInventoryItemsPage>(_onLoadInventoryItemsPage);
    on<LoadMoreInventoryItems>(_onLoadMoreInventoryItems);
    on<RefreshInventoryItems>(_onRefreshInventoryItems);
    on<RefreshSingleItem>(_onRefreshSingleItem);
    on<RefreshMultipleItems>(_onRefreshMultipleItems);
    on<CreateInventoryItem>(_onCreateInventoryItem);
    on<UpdateInventoryItem>(_onUpdateInventoryItem);
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
    on<SearchInventoryItems>(_onSearchInventoryItems);
    on<FilterInventoryItems>(_onFilterInventoryItems);
    on<ClearFilters>(_onClearFilters);

    // ✅ Setup listener for stock updates from orders
    _setupStockUpdateListener();
  }

  /// ✅ Listen for specific item updates from StockManagementService
  void _setupStockUpdateListener() {
    InventoryRefreshNotifier().addSpecificItemListener((itemIds) {
      debugPrint('🔄 INVENTORY BLOC: Stock service requested refresh for ${itemIds.length} items');
      add(RefreshMultipleItems(itemIds));
    });
  }

  @override
  Future<void> close() {
    debugPrint('🔄 INVENTORY BLOC: Closing bloc');
    return super.close();
  }

  // ==================== LOAD INVENTORY ====================

  /// Load inventory items (starts with first page)
  Future<void> _onLoadInventoryItems(
      LoadInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    emit(InventoryLoading());
    debugPrint('🔄 INVENTORY BLOC: Loading inventory with pagination (page 1)');
    add(LoadInventoryItemsPage(page: 1, pageSize: 50));
  }

  /// Load specific page of inventory items
  Future<void> _onLoadInventoryItemsPage(
      LoadInventoryItemsPage event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    // Show loading only for first page
    if (event.page == 1) {
      emit(InventoryLoading());
    } else if (currentState is InventoryLoaded) {
      emit(currentState.copyWith(isLoadingMore: true));
    }

    debugPrint('🔄 INVENTORY BLOC: Loading page ${event.page} (size: ${event.pageSize})');

    try {
      // Get total count (only needed once)
      int totalCount = 0;
      if (event.page == 1) {
        final countResult = await getInventoryItems.repository.getTotalItemCount();
        totalCount = countResult.fold((l) => 0, (r) => r);
        debugPrint('📊 INVENTORY BLOC: Total items in database: $totalCount');
      } else if (currentState is InventoryLoaded) {
        totalCount = currentState.totalItems;
      }

      // Get page items
      final result = await getInventoryItems.repository.getInventoryItemsPaginated(
        page: event.page,
        pageSize: event.pageSize,
      );

      result.fold(
            (failure) {
          debugPrint('❌ INVENTORY BLOC: Failed to load page - ${failure.message}');
          emit(InventoryError(failure.message));
        },
            (pageItems) {
          debugPrint('✅ INVENTORY BLOC: Loaded ${pageItems.length} items for page ${event.page}');

          if (currentState is InventoryLoaded && event.page > 1) {
            // Append to existing items
            final allItems = [...currentState.items, ...pageItems];

            emit(currentState.copyWith(
              items: allItems,
              currentPage: event.page,
              totalItems: totalCount,
              hasReachedMax: allItems.length >= totalCount,
              isLoadingMore: false,
            ));

            debugPrint('📊 INVENTORY BLOC: Total loaded: ${allItems.length}/$totalCount');
          } else {
            // First load
            emit(InventoryLoaded(
              items: pageItems,
              currentPage: event.page,
              totalItems: totalCount,
              hasReachedMax: pageItems.length >= totalCount,
            ));

            debugPrint('📊 INVENTORY BLOC: Initial load: ${pageItems.length}/$totalCount');
          }
        },
      );
    } catch (e) {
      debugPrint('❌ INVENTORY BLOC: Error loading page - $e');
      emit(InventoryError('Failed to load items: $e'));
    }
  }

  /// Load next page (infinite scroll)
  Future<void> _onLoadMoreInventoryItems(
      LoadMoreInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    if (currentState is! InventoryLoaded) {
      debugPrint('⚠️ INVENTORY BLOC: Not in loaded state');
      return;
    }

    if (currentState.hasReachedMax) {
      debugPrint('⚠️ INVENTORY BLOC: Already loaded all items');
      return;
    }

    if (currentState.isLoadingMore) {
      debugPrint('⚠️ INVENTORY BLOC: Already loading more items');
      return;
    }

    debugPrint('🔄 INVENTORY BLOC: Loading more items (page ${currentState.currentPage + 1})');

    final nextPage = currentState.currentPage + 1;
    add(LoadInventoryItemsPage(page: nextPage, pageSize: 50));
  }

  // ==================== REFRESH OPERATIONS ====================

  /// Refresh all inventory items
  Future<void> _onRefreshInventoryItems(
      RefreshInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    debugPrint('🔄 INVENTORY BLOC: Refreshing inventory (reloading from page 1)');
    add(LoadInventoryItems());
  }

  /// Refresh single inventory item
  Future<void> _onRefreshSingleItem(
      RefreshSingleItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    if (currentState is! InventoryLoaded) {
      debugPrint('⚠️ INVENTORY BLOC: Not in loaded state, triggering full reload');
      add(LoadInventoryItems());
      return;
    }

    debugPrint('🔄 INVENTORY BLOC: Refreshing single item: ${event.itemId}');

    final repository = getInventoryItems.repository;
    final result = await repository.getInventoryItem(event.itemId);

    result.fold(
          (failure) {
        debugPrint('❌ INVENTORY BLOC: Failed to refresh item - ${failure.message}');
      },
          (updatedItem) {
        debugPrint('✅ INVENTORY BLOC: Item refreshed - ${updatedItem.nameEn} with ${updatedItem.serialNumbers.length} serials');

        final newState = currentState.updateSingleItem(updatedItem);
        emit(newState);
        debugPrint('✅ INVENTORY BLOC: Table updated with new data');
      },
    );
  }

  /// ✅ NEW: Refresh multiple items efficiently (called by StockManagementService)
  /// Refresh multiple items efficiently (called by StockManagementService)
  Future<void> _onRefreshMultipleItems(
      RefreshMultipleItems event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    if (currentState is! InventoryLoaded) {
      debugPrint('⚠️ INVENTORY BLOC: Not in loaded state, skipping multi-refresh');
      return;
    }

    debugPrint('🔄 INVENTORY BLOC: Refreshing ${event.itemIds.length} items');

    try {
      final repository = getInventoryItems.repository;
      var updatedState = currentState;
      bool stateChanged = false;

      // Refresh each item
      for (final itemId in event.itemIds) {
        final result = await repository.getInventoryItem(itemId);

        result.fold(
              (failure) {
            debugPrint('⚠️ INVENTORY BLOC: Failed to refresh item $itemId - ${failure.message}');
          },
              (updatedItem) {
            debugPrint('✅ INVENTORY BLOC: Refreshed ${updatedItem.nameEn} (stock: ${updatedItem.stockQuantity})');
            updatedState = updatedState.updateSingleItem(updatedItem);
            stateChanged = true;
          },
        );
      }

      // Emit final state with all updates
      if (stateChanged) {
        emit(updatedState);
        debugPrint('✅ INVENTORY BLOC: ${event.itemIds.length} items updated - UI should refresh now');
      } else {
        debugPrint('⚠️ INVENTORY BLOC: No items were updated');
      }
    } catch (e) {
      debugPrint('❌ INVENTORY BLOC: Exception during multi-refresh: $e');
    }
  }


  // ==================== CRUD OPERATIONS ====================

  /// Create inventory item
  Future<void> _onCreateInventoryItem(
      CreateInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    debugPrint('🔄 INVENTORY BLOC: Creating inventory item: ${event.item.nameEn}');

    final result = await createInventoryItem(
      create_item_usecase.CreateInventoryItemParams(event.item),
    );

    result.fold(
          (failure) {
        debugPrint('❌ INVENTORY BLOC: Failed to create item - ${failure.message}');
        emit(InventoryError(failure.message));
      },
          (newItem) {
        debugPrint('✅ INVENTORY BLOC: Item created successfully');
        emit(InventoryItemCreated(newItem));

        if (currentState is InventoryLoaded) {
          final newState = currentState.addSingleItem(newItem);
          emit(newState);
          debugPrint('✅ INVENTORY BLOC: Item added to state');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  /// Update inventory item
  Future<void> _onUpdateInventoryItem(
      UpdateInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    debugPrint('🔄 INVENTORY BLOC: Updating inventory item: ${event.item.id}');

    final result = await updateInventoryItem(
      update_item_usecase.UpdateInventoryItemParams(event.item),
    );

    result.fold(
          (failure) {
        debugPrint('❌ INVENTORY BLOC: Failed to update item - ${failure.message}');
        emit(InventoryError(failure.message));
      },
          (updatedItem) {
        debugPrint('✅ INVENTORY BLOC: Item updated successfully');
        emit(InventoryItemUpdated(updatedItem));

        if (currentState is InventoryLoaded) {
          final newState = currentState.updateSingleItem(updatedItem);
          emit(newState);
          debugPrint('✅ INVENTORY BLOC: State updated with single item');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  /// Delete inventory item
  Future<void> _onDeleteInventoryItem(
      DeleteInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    debugPrint('🔄 INVENTORY BLOC: Deleting inventory item: ${event.itemId}');

    final result = await deleteInventoryItem(
      delete_item_usecase.DeleteInventoryItemParams(event.itemId),
    );

    result.fold(
          (failure) {
        debugPrint('❌ INVENTORY BLOC: Failed to delete item - ${failure.message}');
        emit(InventoryError(failure.message));
      },
          (_) {
        debugPrint('✅ INVENTORY BLOC: Item deleted successfully');
        emit(InventoryItemDeleted(event.itemId));

        if (currentState is InventoryLoaded) {
          final newState = currentState.removeSingleItem(event.itemId);
          emit(newState);
          debugPrint('✅ INVENTORY BLOC: Item removed from state');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  // ==================== SEARCH & FILTER ====================

  /// Search inventory items
  Future<void> _onSearchInventoryItems(
      SearchInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is! InventoryLoaded) return;

    final currentState = state as InventoryLoaded;
    final query = event.query.trim();

    if (query.isEmpty) {
      // Clear search
      emit(currentState.copyWith(
        filteredItems: [],
        searchQuery: null,
      ));
      debugPrint('✅ INVENTORY BLOC: Search cleared');
      return;
    }

    // Show loading state
    emit(currentState.copyWith(
      isLoadingMore: true,
      searchQuery: query,
    ));

    debugPrint('🔍 INVENTORY BLOC: Searching ALL items for: "$query"');

    final result = await searchInventoryItems(
      search_items_usecase.SearchInventoryItemsParams(query),
    );

    result.fold(
          (failure) {
        emit(InventoryError(failure.message));
      },
          (searchResults) {
        emit(currentState.copyWith(
          filteredItems: searchResults,
          searchQuery: query,
          isLoadingMore: false,
        ));
        debugPrint('✅ INVENTORY BLOC: Search found ${searchResults.length} items');
      },
    );
  }

  /// Filter inventory items
  Future<void> _onFilterInventoryItems(
      FilterInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is! InventoryLoaded) return;

    final currentState = state as InventoryLoaded;

    debugPrint('🔍 INVENTORY BLOC: Applying filters: ${event.filters}');

    // ✅ Show loading state while filtering
    emit(currentState.copyWith(
      isLoadingMore: true,
      activeFilters: event.filters,
    ));

    final result = await filterInventoryItems(
      filter_items_usecase.FilterInventoryItemsParams(event.filters),
    );

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (items) {
        emit(currentState.copyWith(
          filteredItems: items,
          activeFilters: event.filters,
          isLoadingMore: false, // ✅ Turn off loading
        ));
        debugPrint('✅ INVENTORY BLOC: Filter found ${items.length} items');
      },
    );
  }


  /// Clear all filters
  Future<void> _onClearFilters(
      ClearFilters event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is! InventoryLoaded) return;

    final currentState = state as InventoryLoaded;
    emit(currentState.copyWith(
      filteredItems: [],
      searchQuery: null,
      activeFilters: {},
    ));
    debugPrint('✅ INVENTORY BLOC: Filters cleared');
  }
}
