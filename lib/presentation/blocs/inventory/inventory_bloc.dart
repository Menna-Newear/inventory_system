// ✅ presentation/blocs/inventory/inventory_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/inventory_item.dart';

// Import use cases with aliases
import '../../../domain/usecases/get_inventory_items.dart' as get_items_usecase;
import '../../../domain/usecases/create_inventory_item.dart' as create_item_usecase;
import '../../../domain/usecases/update_inventory_item.dart' as update_item_usecase;
import '../../../domain/usecases/delete_inventory_item.dart' as delete_item_usecase;
import '../../../domain/usecases/search_inventory_items.dart' as search_items_usecase;
import '../../../domain/usecases/filter_inventory_items.dart' as filter_items_usecase;

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
    on<LoadInventoryItemsPage>(_onLoadInventoryItemsPage); // ✅ NEW
    on<LoadMoreInventoryItems>(_onLoadMoreInventoryItems); // ✅ NEW
    on<RefreshInventoryItems>(_onRefreshInventoryItems);
    on<RefreshSingleItem>(_onRefreshSingleItem);
    on<CreateInventoryItem>(_onCreateInventoryItem);
    on<UpdateInventoryItem>(_onUpdateInventoryItem);
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
    on<SearchInventoryItems>(_onSearchInventoryItems);
    on<FilterInventoryItems>(_onFilterInventoryItems);
    on<ClearFilters>(_onClearFilters);
  }

  // ✅ Original: Load all items (for backward compatibility)
  Future<void> _onLoadInventoryItems(
      LoadInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    emit(InventoryLoading());

    print('🔄 BLOC: Loading inventory with pagination (page 1)');

    // Start with first page
    add(LoadInventoryItemsPage(page: 1, pageSize: 50));
  }

  // ✅ NEW: Load specific page
  Future<void> _onLoadInventoryItemsPage(
      LoadInventoryItemsPage event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    // Show loading only for first page
    if (event.page == 1) {
      emit(InventoryLoading());
    } else if (currentState is InventoryLoaded) {
      // Show loading indicator at bottom for subsequent pages
      emit(currentState.copyWith(isLoadingMore: true));
    }

    print('🔄 BLOC: Loading page ${event.page} (size: ${event.pageSize})');

    try {
      // Get total count (only needed once)
      int totalCount = 0;
      if (event.page == 1) {
        final countResult = await getInventoryItems.repository.getTotalItemCount();
        totalCount = countResult.fold((l) => 0, (r) => r);
        print('📊 BLOC: Total items in database: $totalCount');
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
          print('❌ BLOC: Failed to load page - ${failure.message}');
          emit(InventoryError(failure.message));
        },
            (pageItems) {
          print('✅ BLOC: Loaded ${pageItems.length} items for page ${event.page}');

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

            print('📊 BLOC: Total loaded: ${allItems.length}/$totalCount');
          } else {
            // First load
            emit(InventoryLoaded(
              items: pageItems,
              currentPage: event.page,
              totalItems: totalCount,
              hasReachedMax: pageItems.length >= totalCount,
            ));

            print('📊 BLOC: Initial load: ${pageItems.length}/$totalCount');
          }
        },
      );
    } catch (e) {
      print('❌ BLOC: Error loading page - $e');
      emit(InventoryError('Failed to load items: $e'));
    }
  }

  // ✅ NEW: Load next page (infinite scroll)
  Future<void> _onLoadMoreInventoryItems(
      LoadMoreInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    if (currentState is! InventoryLoaded) {
      print('⚠️ BLOC: Not in loaded state');
      return;
    }

    if (currentState.hasReachedMax) {
      print('⚠️ BLOC: Already loaded all items');
      return;
    }

    if (currentState.isLoadingMore) {
      print('⚠️ BLOC: Already loading more items');
      return;
    }

    print('🔄 BLOC: Loading more items (page ${currentState.currentPage + 1})');

    final nextPage = currentState.currentPage + 1;
    add(LoadInventoryItemsPage(page: nextPage, pageSize: 50));
  }

  Future<void> _onRefreshInventoryItems(
      RefreshInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    print('🔄 BLOC: Refreshing inventory (reloading from page 1)');
    add(LoadInventoryItems());
  }

  Future<void> _onRefreshSingleItem(
      RefreshSingleItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    if (currentState is! InventoryLoaded) {
      print('⚠️ BLOC: Not in loaded state, triggering full reload');
      add(LoadInventoryItems());
      return;
    }

    print('🔄 BLOC: Refreshing single item: ${event.itemId}');

    final repository = getInventoryItems.repository;
    final result = await repository.getInventoryItem(event.itemId);

    result.fold(
          (failure) {
        print('❌ BLOC: Failed to refresh item - ${failure.message}');
      },
          (updatedItem) {
        print('✅ BLOC: Item refreshed with ${updatedItem.serialNumbers.length} serials');

        final newState = currentState.updateSingleItem(updatedItem);
        emit(newState);
        print('✅ BLOC: Table updated with new data');
      },
    );
  }

  Future<void> _onCreateInventoryItem(
      CreateInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    print('🔄 BLOC: Creating inventory item: ${event.item.nameEn}');

    final result = await createInventoryItem(
      create_item_usecase.CreateInventoryItemParams(event.item),
    );

    result.fold(
          (failure) {
        print('❌ BLOC: Failed to create item - ${failure.message}');
        emit(InventoryError(failure.message));
      },
          (newItem) {
        print('✅ BLOC: Item created successfully');
        emit(InventoryItemCreated(newItem));

        if (currentState is InventoryLoaded) {
          final newState = currentState.addSingleItem(newItem);
          emit(newState);
          print('✅ BLOC: Item added to state');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  Future<void> _onUpdateInventoryItem(
      UpdateInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    print('🔄 BLOC: Updating inventory item: ${event.item.id}');

    final result = await updateInventoryItem(
      update_item_usecase.UpdateInventoryItemParams(event.item),
    );

    result.fold(
          (failure) {
        print('❌ BLOC: Failed to update item - ${failure.message}');
        emit(InventoryError(failure.message));
      },
          (updatedItem) {
        print('✅ BLOC: Item updated successfully');
        emit(InventoryItemUpdated(updatedItem));

        if (currentState is InventoryLoaded) {
          final newState = currentState.updateSingleItem(updatedItem);
          emit(newState);
          print('✅ BLOC: State updated with single item');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  Future<void> _onDeleteInventoryItem(
      DeleteInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final currentState = state;

    print('🔄 BLOC: Deleting inventory item: ${event.itemId}');

    final result = await deleteInventoryItem(
      delete_item_usecase.DeleteInventoryItemParams(event.itemId),
    );

    result.fold(
          (failure) {
        print('❌ BLOC: Failed to delete item - ${failure.message}');
        emit(InventoryError(failure.message));
      },
          (_) {
        print('✅ BLOC: Item deleted successfully');
        emit(InventoryItemDeleted(event.itemId));

        if (currentState is InventoryLoaded) {
          final newState = currentState.removeSingleItem(event.itemId);
          emit(newState);
          print('✅ BLOC: Item removed from state');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }
// ✅ ENHANCED: Backend search with proper empty string handling
  Future<void> _onSearchInventoryItems(
      SearchInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is! InventoryLoaded) return;

    final currentState = state as InventoryLoaded;

    // ✅ FIX: Trim and check for empty
    final query = event.query.trim();

    if (query.isEmpty) {
      // Clear search - go back to paginated view
      emit(currentState.copyWith(
        filteredItems: [],
        searchQuery: null,  // ✅ Must be null, not empty string
      ));
      print('✅ BLOC: Search cleared (query was: "${event.query}")');
      return;
    }

    // ✅ Show loading state for search
    emit(currentState.copyWith(
      isLoadingMore: true,
      searchQuery: query,  // Set trimmed query
    ));

    print('🔍 BLOC: Searching ALL items for: "$query"');

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
        print('✅ BLOC: Search found ${searchResults.length} items (searched ${currentState.totalItems} total items)');
      },
    );
  }


  Future<void> _onFilterInventoryItems(
      FilterInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is! InventoryLoaded) return;

    final currentState = state as InventoryLoaded;

    print('🔍 BLOC: Applying filters: ${event.filters}');

    final result = await filterInventoryItems(
      filter_items_usecase.FilterInventoryItemsParams(event.filters),
    );

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (items) {
        emit(currentState.copyWith(
          filteredItems: items,
          activeFilters: event.filters,
        ));
        print('✅ BLOC: Filter found ${items.length} items');
      },
    );
  }

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
    print('✅ BLOC: Filters cleared');
  }
}
