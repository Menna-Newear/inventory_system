// ✅ presentation/blocs/inventory/inventory_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/inventory_item.dart';
import '../../../core/usecases/usecase.dart';

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
    on<RefreshInventoryItems>(_onRefreshInventoryItems);
    on<RefreshSingleItem>(_onRefreshSingleItem); // ✅ NEW
    on<CreateInventoryItem>(_onCreateInventoryItem);
    on<UpdateInventoryItem>(_onUpdateInventoryItem);
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
    on<SearchInventoryItems>(_onSearchInventoryItems);
    on<FilterInventoryItems>(_onFilterInventoryItems);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadInventoryItems(
      LoadInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    emit(InventoryLoading());

    print('🔄 BLOC: Loading all inventory items');
    final result = await getInventoryItems(NoParams());

    result.fold(
          (failure) {
        print('❌ BLOC: Failed to load items - ${failure.message}');
        emit(InventoryError(failure.message));
      },
          (items) {
        print('✅ BLOC: Loaded ${items.length} inventory items');
        emit(InventoryLoaded(items: items));
      },
    );
  }

  Future<void> _onRefreshInventoryItems(
      RefreshInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    print('🔄 BLOC: Refreshing inventory items');
    final result = await getInventoryItems(NoParams());

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (items) {
        if (state is InventoryLoaded) {
          final currentState = state as InventoryLoaded;
          emit(currentState.copyWith(items: items));
          print('✅ BLOC: Refreshed ${items.length} items');
        } else {
          emit(InventoryLoaded(items: items));
        }
      },
    );
  }

  // ✅ NEW: Refresh single item after serial changes
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

    // Get the repository from the use case
    final repository = getInventoryItems.repository;

    // Fetch only the updated item with fresh serial numbers
    final result = await repository.getInventoryItem(event.itemId);

    result.fold(
          (failure) {
        print('❌ BLOC: Failed to refresh item - ${failure.message}');
        // Silently fail, keep current state
      },
          (updatedItem) {
        print('✅ BLOC: Item refreshed - ${updatedItem.nameEn}');
        print('📊 BLOC: Serial numbers: ${updatedItem.serialNumbers.length}');

        // Update only this item in state
        final newState = currentState.updateSingleItem(updatedItem);
        emit(newState);
        print('✅ BLOC: Table updated with new data - NO FULL RELOAD');
      },
    );
  }

  // ✅ OPTIMIZED: Add item to state without full reload
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

        // ✅ Add to current state if it exists
        if (currentState is InventoryLoaded) {
          final newState = currentState.addSingleItem(newItem);
          emit(newState);
          print('✅ BLOC: Item added to state - NO FULL RELOAD');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  // ✅ OPTIMIZED: Update single item without refetching all
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

        // ✅ Update single item in current state
        if (currentState is InventoryLoaded) {
          final newState = currentState.updateSingleItem(updatedItem);
          emit(newState);
          print('✅ BLOC: State updated with single item - NO FULL RELOAD');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  // ✅ OPTIMIZED: Remove item from state without refetching
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

        // ✅ Remove from current state
        if (currentState is InventoryLoaded) {
          final newState = currentState.removeSingleItem(event.itemId);
          emit(newState);
          print('✅ BLOC: Item removed from state - NO FULL RELOAD');
        } else {
          add(RefreshInventoryItems());
        }
      },
    );
  }

  Future<void> _onSearchInventoryItems(
      SearchInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;

      if (event.query.isEmpty) {
        emit(currentState.copyWith(
          filteredItems: [],
          searchQuery: null,
        ));
        print('✅ BLOC: Search cleared');
        return;
      }

      print('🔍 BLOC: Searching for: ${event.query}');

      final result = await searchInventoryItems(
        search_items_usecase.SearchInventoryItemsParams(event.query),
      );

      result.fold(
            (failure) => emit(InventoryError(failure.message)),
            (items) {
          emit(currentState.copyWith(
            filteredItems: items,
            searchQuery: event.query,
          ));
          print('✅ BLOC: Search found ${items.length} items');
        },
      );
    }
  }

  Future<void> _onFilterInventoryItems(
      FilterInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is InventoryLoaded) {
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
  }

  Future<void> _onClearFilters(
      ClearFilters event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      emit(currentState.copyWith(
        filteredItems: [],
        searchQuery: null,
        activeFilters: {},
      ));
      print('✅ BLOC: Filters cleared');
    }
  }
}
