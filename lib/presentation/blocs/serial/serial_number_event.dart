// ✅ blocs/serial/serial_number_event.dart (WITH DATE-AWARE EVENT)
import '../../../domain/entities/inventory_item.dart';

abstract class SerialNumberEvent {}

class LoadSerialNumbers extends SerialNumberEvent {
  final String itemId;
  LoadSerialNumbers(this.itemId);
}

// ✅ NEW: Load serials with date-awareness for rentals
class LoadAvailableSerialsByDate extends SerialNumberEvent {
  final String itemId;
  final DateTime? startDate;
  final DateTime? endDate;

  LoadAvailableSerialsByDate(
      this.itemId, {
        this.startDate,
        this.endDate,
      });
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
