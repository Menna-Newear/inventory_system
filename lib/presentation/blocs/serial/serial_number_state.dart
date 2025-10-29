// ✅ blocs/serial/serial_number_state.dart (WITH DATE CONFLICT INFO)
import '../../../domain/entities/inventory_item.dart';

abstract class SerialNumberState {}

class SerialNumbersLoading extends SerialNumberState {}

class SerialNumbersLoaded extends SerialNumberState {
  final List<SerialNumber> serials;
  final Map<String, SerialDateAvailability>? availabilityMap; // ✅ NEW

  SerialNumbersLoaded(
      this.serials, {
        this.availabilityMap,
      });
}

class SerialNumbersError extends SerialNumberState {
  final String message;
  SerialNumbersError(this.message);
}

// ✅ NEW: Class to track serial availability by date
class SerialDateAvailability {
  final bool isAvailableForDates;
  final String? conflictingOrderId;
  final DateTime? conflictStartDate;
  final DateTime? conflictEndDate;

  SerialDateAvailability({
    required this.isAvailableForDates,
    this.conflictingOrderId,
    this.conflictStartDate,
    this.conflictEndDate,
  });
}
