// blocs/serial/serial_number_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../domain/usecases/add_serial_usecase.dart' as add_serial_usecase;
import 'serial_number_event.dart';
import 'serial_number_state.dart';

class SerialNumberBloc extends Bloc<SerialNumberEvent, SerialNumberState> {
  final add_serial_usecase.AddSerialNumbers addSerialNumbersUseCase;
  final InventoryRepository inventoryRepository;

  SerialNumberBloc({
    required this.addSerialNumbersUseCase,
    required this.inventoryRepository,
  }) : super(SerialNumbersLoading()) {

    on<LoadSerialNumbers>((event, emit) async {
      emit(SerialNumbersLoading());
      final response = await inventoryRepository.getSerialNumbers(event.itemId);
      emit(response.fold(
            (failure) => SerialNumbersError(failure.message),
            (serials) => SerialNumbersLoaded(serials),
      ));
    });

    on<AddSerialNumbers>((event, emit) async {
      emit(SerialNumbersLoading());
      final response = await addSerialNumbersUseCase(
        add_serial_usecase.AddSerialNumbersParams(
          itemId: event.itemId,
          serialNumbers: event.serialNumbers,
        ),
      );
      response.fold(
            (failure) => emit(SerialNumbersError(failure.message)),
            (_) => add(LoadSerialNumbers(event.itemId)),
      );
    });

    on<BulkUpdateSerialStatus>((event, emit) async {
      emit(SerialNumbersLoading());
      final response = await inventoryRepository.bulkUpdateSerialStatus(event.serialIds, event.status);
      response.fold(
            (failure) => emit(SerialNumbersError(failure.message)),
            (serials) {
          if (state is SerialNumbersLoaded && (state as SerialNumbersLoaded).serials.isNotEmpty) {
            add(LoadSerialNumbers((state as SerialNumbersLoaded).serials.first.itemId));
          }
        },
      );
    });
  }
}
