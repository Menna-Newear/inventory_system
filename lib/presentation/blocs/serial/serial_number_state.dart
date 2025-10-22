// blocs/serial/serial_number_state.dart
import '../../../domain/entities/inventory_item.dart';

abstract class SerialNumberState {}

class SerialNumbersLoading extends SerialNumberState {}

class SerialNumbersLoaded extends SerialNumberState {
  final List<SerialNumber> serials;
  SerialNumbersLoaded(this.serials);
}

class SerialNumbersError extends SerialNumberState {
  final String message;
  SerialNumbersError(this.message);
}
