// presentation/blocs/inventory/inventory_bloc.dart
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

    final result = await getInventoryItems(NoParams());

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (items) => emit(InventoryLoaded(items: items)),
    );
  }

  Future<void> _onRefreshInventoryItems(
      RefreshInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    final result = await getInventoryItems(NoParams());

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (items) {
        if (state is InventoryLoaded) {
          final currentState = state as InventoryLoaded;
          emit(currentState.copyWith(items: items));
        } else {
          emit(InventoryLoaded(items: items));
        }
      },
    );
  }

  Future<void> _onCreateInventoryItem(
      CreateInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final result = await createInventoryItem(
      create_item_usecase.CreateInventoryItemParams(event.item),
    );

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (item) {
        emit(InventoryItemCreated(item));
        add(RefreshInventoryItems());
      },
    );
  }

  Future<void> _onUpdateInventoryItem(
      UpdateInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final result = await updateInventoryItem(
      update_item_usecase.UpdateInventoryItemParams(event.item),
    );

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (item) {
        emit(InventoryItemUpdated(item));
        add(RefreshInventoryItems());
      },
    );
  }

  Future<void> _onDeleteInventoryItem(
      DeleteInventoryItem event,
      Emitter<InventoryState> emit,
      ) async {
    final result = await deleteInventoryItem(
      delete_item_usecase.DeleteInventoryItemParams(event.itemId),
    );

    result.fold(
          (failure) => emit(InventoryError(failure.message)),
          (_) {
        emit(InventoryItemDeleted(event.itemId));
        add(RefreshInventoryItems());
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
        return;
      }

      final result = await searchInventoryItems(
        search_items_usecase.SearchInventoryItemsParams(event.query),
      );

      result.fold(
            (failure) => emit(InventoryError(failure.message)),
            (items) => emit(currentState.copyWith(
          filteredItems: items,
          searchQuery: event.query,
        )),
      );
    }
  }

  Future<void> _onFilterInventoryItems(
      FilterInventoryItems event,
      Emitter<InventoryState> emit,
      ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;

      final result = await filterInventoryItems(
        filter_items_usecase.FilterInventoryItemsParams(event.filters),
      );

      result.fold(
            (failure) => emit(InventoryError(failure.message)),
            (items) => emit(currentState.copyWith(
          filteredItems: items,
          activeFilters: event.filters,
        )),
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
    }
  }
}
