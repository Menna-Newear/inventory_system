// presentation/viewmodels/serial_number_viewmodel.dart
import 'package:flutter/material.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/usecases/add_serial_numbers.dart';
import '../../domain/usecases/update_serial_status.dart';

class SerialNumberViewModel extends ChangeNotifier {
  final AddSerialNumbers _addSerialNumbers;
  final UpdateSerialStatus _updateSerialStatus;

  SerialNumberViewModel({
    required AddSerialNumbers addSerialNumbers,
    required UpdateSerialStatus updateSerialStatus,
  }) : _addSerialNumbers = addSerialNumbers,
        _updateSerialStatus = updateSerialStatus;

  bool _isLoading = false;
  String? _errorMessage;
  List<SerialNumber> _serialNumbers = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SerialNumber> get serialNumbers => _serialNumbers;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ✅ Generate serial numbers for an item
  List<SerialNumber> generateSerialNumbers(InventoryItem item, int quantity) {
    if (!item.isSerialTracked) {
      throw Exception('Item is not serial tracked');
    }

    final List<SerialNumber> newSerials = [];

    for (int i = 0; i < quantity; i++) {
      try {
        final serialNumber = item.generateNextSerialNumber();
        newSerials.add(SerialNumber(
          id: '', // Will be set by database
          itemId: item.id,
          serialNumber: serialNumber,
          status: SerialStatus.available,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      } catch (e) {
        throw Exception('Failed to generate serial number ${i + 1}: $e');
      }
    }

    return newSerials;
  }

  // ✅ Add serial numbers to item
  Future<bool> addSerialNumbers(String itemId, List<SerialNumber> serialNumbers) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _addSerialNumbers(AddSerialNumbersParams(
        itemId: itemId,
        serialNumbers: serialNumbers,
      ));

      return result.fold(
            (failure) {
          _setError('Failed to add serial numbers: ${failure.toString()}');
          return false;
        },
            (addedSerials) {
          _serialNumbers.addAll(addedSerials);
          notifyListeners();
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Update serial number status
  Future<bool> updateSerialStatus(
      String serialId,
      SerialStatus newStatus, {
        String? notes,
      }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _updateSerialStatus(UpdateSerialStatusParams(
        serialId: serialId,
        newStatus: newStatus,
        notes: notes,
      ));

      return result.fold(
            (failure) {
          _setError('Failed to update serial status: ${failure.toString()}');
          return false;
        },
            (updatedSerial) {
          // Update local list
          final index = _serialNumbers.indexWhere((s) => s.id == serialId);
          if (index != -1) {
            _serialNumbers[index] = updatedSerial;
            notifyListeners();
          }
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Bulk status update
  Future<bool> bulkUpdateStatus(
      List<String> serialIds,
      SerialStatus newStatus, {
        String? notes,
      }) async {
    try {
      _setLoading(true);
      _clearError();

      int successCount = 0;
      for (final serialId in serialIds) {
        final success = await updateSerialStatus(serialId, newStatus, notes: notes);
        if (success) successCount++;
      }

      if (successCount == serialIds.length) {
        return true;
      } else {
        _setError('Updated $successCount of ${serialIds.length} serial numbers');
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Validate serial number format
  bool validateSerialNumber(String serialNumber, InventoryItem item) {
    if (serialNumber.trim().isEmpty) return false;

    // Check prefix if required
    if (item.serialNumberPrefix != null && item.serialNumberPrefix!.isNotEmpty) {
      if (!serialNumber.startsWith(item.serialNumberPrefix!)) {
        return false;
      }
    }

    // Check length if specified
    if (item.serialNumberLength != null) {
      if (serialNumber.length != item.serialNumberLength!) {
        return false;
      }
    }

    // Check format
    switch (item.serialFormat) {
      case SerialNumberFormat.numeric:
        final numberPart = item.serialNumberPrefix != null
            ? serialNumber.substring(item.serialNumberPrefix!.length)
            : serialNumber;
        return RegExp(r'^\d+$').hasMatch(numberPart);

      case SerialNumberFormat.alphanumeric:
        return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(serialNumber);

      case SerialNumberFormat.custom:
        return true; // Custom validation would go here
    }
  }

  // ✅ Check for duplicate serial numbers
  bool isDuplicateSerial(String serialNumber, InventoryItem item) {
    return item.serialNumbers.any((s) => s.serialNumber == serialNumber);
  }
}
