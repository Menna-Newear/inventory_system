// blocs/serial/serial_number_event.dart
import '../../../domain/entities/inventory_item.dart';

abstract class SerialNumberEvent {}

class LoadSerialNumbers extends SerialNumberEvent {
  final String itemId;
  LoadSerialNumbers(this.itemId);
}

class AddSerialNumbers extends SerialNumberEvent {
  final String itemId;
  final List<SerialNumber> serialNumbers;
  AddSerialNumbers(this.itemId, this.serialNumbers);
}

class BulkUpdateSerialStatus extends SerialNumberEvent {
  final List<String> serialIds;
  final SerialStatus status;
  BulkUpdateSerialStatus(this.serialIds, this.status);
}

// ...other events for manual creation, deletion, etc.
