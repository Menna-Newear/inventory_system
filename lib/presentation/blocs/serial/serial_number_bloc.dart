// ✅ blocs/serial/serial_number_bloc.dart (WITH CACHE INVALIDATION)
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../domain/usecases/add_serial_usecase.dart' as add_serial_usecase;
import '../../../data/services/serial_number_cache_service.dart'; // ✅ ADD
import 'serial_number_event.dart';
import 'serial_number_state.dart';

class SerialNumberBloc extends Bloc<SerialNumberEvent, SerialNumberState> {
  final add_serial_usecase.AddSerialNumbers addSerialNumbersUseCase;
  final InventoryRepository inventoryRepository;
  final SerialNumberCacheService cacheService; // ✅ ADD

  SerialNumberBloc({
    required this.addSerialNumbersUseCase,
    required this.inventoryRepository,
    required this.cacheService, // ✅ ADD
  }) : super(SerialNumbersLoading()) {

    on<LoadSerialNumbers>((event, emit) async {
      emit(SerialNumbersLoading());

      print('🔄 SERIAL BLOC: Loading serial numbers for item: ${event.itemId}');

      final response = await inventoryRepository.getSerialNumbers(event.itemId);
      emit(response.fold(
            (failure) {
          print('❌ SERIAL BLOC: Failed to load serials - ${failure.message}');
          return SerialNumbersError(failure.message);
        },
            (serials) {
          print('✅ SERIAL BLOC: Loaded ${serials.length} serial numbers');
          return SerialNumbersLoaded(serials);
        },
      ));
    });

    on<AddSerialNumbers>((event, emit) async {
      emit(SerialNumbersLoading());

      print('🔄 SERIAL BLOC: Adding ${event.serialNumbers.length} serial numbers to item: ${event.itemId}');

      final response = await addSerialNumbersUseCase(
        add_serial_usecase.AddSerialNumbersParams(
          itemId: event.itemId,
          serialNumbers: event.serialNumbers,
        ),
      );

      response.fold(
            (failure) {
          print('❌ SERIAL BLOC: Failed to add serials - ${failure.message}');
          emit(SerialNumbersError(failure.message));
        },
            (_) {
          print('✅ SERIAL BLOC: Serials added successfully');

          // ✅ Invalidate cache after adding serials
          cacheService.invalidateCache(event.itemId);
          print('🗑️ SERIAL BLOC: Cache invalidated for item: ${event.itemId}');

          // Reload the serials to show updated list
          add(LoadSerialNumbers(event.itemId));
        },
      );
    });

    on<BulkUpdateSerialStatus>((event, emit) async {
      emit(SerialNumbersLoading());

      print('🔄 SERIAL BLOC: Bulk updating ${event.serialIds.length} serial statuses to ${event.status}');

      final response = await inventoryRepository.bulkUpdateSerialStatus(
        event.serialIds,
        event.status,
      );

      response.fold(
            (failure) {
          print('❌ SERIAL BLOC: Failed to update serial statuses - ${failure.message}');
          emit(SerialNumbersError(failure.message));
        },
            (serials) {
          print('✅ SERIAL BLOC: Updated ${serials.length} serial statuses');

          // ✅ Invalidate cache for affected item
          if (state is SerialNumbersLoaded && (state as SerialNumbersLoaded).serials.isNotEmpty) {
            final itemId = (state as SerialNumbersLoaded).serials.first.itemId;
            cacheService.invalidateCache(itemId);
            print('🗑️ SERIAL BLOC: Cache invalidated for item: $itemId');

            // Reload serials to show updated list
            add(LoadSerialNumbers(itemId));
          } else if (serials.isNotEmpty) {
            // Fallback: use itemId from response
            final itemId = serials.first.itemId;
            cacheService.invalidateCache(itemId);
            print('🗑️ SERIAL BLOC: Cache invalidated for item: $itemId');

            // Reload serials
            add(LoadSerialNumbers(itemId));
          }
        },
      );
    });
  }
}
