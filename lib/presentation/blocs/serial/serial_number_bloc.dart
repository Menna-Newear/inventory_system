// ✅ blocs/serial/serial_number_bloc.dart (COMPLETE WITH DATABASE DATE CHECKING)
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../domain/usecases/add_serial_usecase.dart' as add_serial_usecase;
import '../../../data/services/serial_number_cache_service.dart';
import 'serial_number_event.dart';
import 'serial_number_state.dart';

class SerialNumberBloc extends Bloc<SerialNumberEvent, SerialNumberState> {
  final add_serial_usecase.AddSerialNumbers addSerialNumbersUseCase;
  final InventoryRepository inventoryRepository;
  final SerialNumberCacheService cacheService;
  final SupabaseClient supabaseClient;  // ✅ ADD THIS

  SerialNumberBloc({
    required this.addSerialNumbersUseCase,
    required this.inventoryRepository,
    required this.cacheService,
    required this.supabaseClient,  // ✅ ADD THIS
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

    // ✅ NEW: Load with date-aware filtering using Supabase function
    on<LoadAvailableSerialsByDate>((event, emit) async {
      emit(SerialNumbersLoading());

      print('🔄 SERIAL BLOC: Loading serials with date check for item: ${event.itemId}');
      print('📅 Date range: ${event.startDate} to ${event.endDate}');

      try {
        if (event.startDate == null || event.endDate == null) {
          // No dates provided, use regular loading
          print('⚠️ No dates provided, falling back to regular load');
          add(LoadSerialNumbers(event.itemId));
          return;
        }

        // ✅ Call Supabase RPC function to check date availability
        final response = await supabaseClient.rpc(
          'check_serial_availability_by_date',
          params: {
            'p_item_id': event.itemId,
            'p_start_date': event.startDate!.toIso8601String(),
            'p_end_date': event.endDate!.toIso8601String(),
          },
        );

        print('✅ SERIAL BLOC: Got availability response from database');

        if (response == null || response.isEmpty) {
          print('⚠️ No serials found for item');
          emit(SerialNumbersLoaded([]));
          return;
        }

        // Parse the response into SerialNumber objects with availability info
        final List<SerialNumber> serials = [];
        final Map<String, SerialDateAvailability> availabilityMap = {};

        for (final row in response) {
          final serialId = row['serial_id'] as String;
          final serialNumber = row['serial_number'] as String;
          final status = _parseSerialStatus(row['status'] as String);
          final isAvailable = row['is_available_for_dates'] as bool;

          // Create SerialNumber object
          serials.add(SerialNumber(
            id: serialId,
            serialNumber: serialNumber,
            status: status,
            itemId: event.itemId,
            createdAt: DateTime.now(), updatedAt: DateTime.now(), // Not provided by function, use current time
          ));

          // Create availability info
          availabilityMap[serialId] = SerialDateAvailability(
            isAvailableForDates: isAvailable,
            conflictingOrderId: row['conflicting_order_id'] as String?,
            conflictStartDate: row['conflicting_start_date'] != null
                ? DateTime.parse(row['conflicting_start_date'] as String)
                : null,
            conflictEndDate: row['conflicting_end_date'] != null
                ? DateTime.parse(row['conflicting_end_date'] as String)
                : null,
          );
        }

        print('✅ SERIAL BLOC: Processed ${serials.length} serials with availability');
        print('📊 Available for dates: ${availabilityMap.values.where((a) => a.isAvailableForDates).length}');
        print('📊 Unavailable (conflicts): ${availabilityMap.values.where((a) => !a.isAvailableForDates).length}');

        emit(SerialNumbersLoaded(
          serials,
          availabilityMap: availabilityMap,
        ));
      } catch (e) {
        print('❌ SERIAL BLOC: Error checking date availability - $e');
        emit(SerialNumbersError('Failed to check serial availability: ${e.toString()}'));
      }
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
          cacheService.invalidateCache(event.itemId);
          print('🗑️ SERIAL BLOC: Cache invalidated for item: ${event.itemId}');
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

          if (state is SerialNumbersLoaded && (state as SerialNumbersLoaded).serials.isNotEmpty) {
            final itemId = (state as SerialNumbersLoaded).serials.first.itemId;
            cacheService.invalidateCache(itemId);
            print('🗑️ SERIAL BLOC: Cache invalidated for item: $itemId');
            add(LoadSerialNumbers(itemId));
          } else if (serials.isNotEmpty) {
            final itemId = serials.first.itemId;
            cacheService.invalidateCache(itemId);
            print('🗑️ SERIAL BLOC: Cache invalidated for item: $itemId');
            add(LoadSerialNumbers(itemId));
          }
        },
      );
    });
  }

  // ✅ Helper to parse serial status from string
  SerialStatus _parseSerialStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return SerialStatus.available;
      case 'rented':
        return SerialStatus.rented;
      case 'sold':
        return SerialStatus.sold;
      case 'damaged':
        return SerialStatus.damaged;
      case 'reserved':
        return SerialStatus.reserved;
      case 'returned':
        return SerialStatus.returned;
      case 'recalled':
        return SerialStatus.recalled;
      default:
        return SerialStatus.available;
    }
  }
}
