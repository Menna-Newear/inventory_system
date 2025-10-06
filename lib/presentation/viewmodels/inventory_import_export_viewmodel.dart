// presentation/viewmodels/inventory_import_export_viewmodel.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/inventory_item.dart';
import '../../data/services/import_export_service.dart';
import '../blocs/inventory/inventory_bloc.dart';
import '../../injection_container.dart';

class InventoryImportExportViewModel extends ChangeNotifier {
  late final ImportExportService _importExportService;
  final InventoryBloc _inventoryBloc;

  // State management
  bool _isLoading = false;
  String? _errorMessage;
  double _progress = 0.0;
  String? _lastExportPath;
  int _importedItemsCount = 0;
  int _failedImportsCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get progress => _progress;
  String? get lastExportPath => _lastExportPath;
  int get importedItemsCount => _importedItemsCount;
  int get failedImportsCount => _failedImportsCount;
  bool get hasLastExport => _lastExportPath != null;

  // ✅ UPDATED - Constructor using GetIt for ImportExportService
  InventoryImportExportViewModel({
    required InventoryBloc inventoryBloc,
  }) : _inventoryBloc = inventoryBloc {
    // Get ImportExportService from dependency injection
    _importExportService = getIt<ImportExportService>();
  }

  // ✅ ENHANCED - Import CSV with detailed progress and error handling
  Future<bool> importFromCsv() async {
    try {
      _setLoading(true);
      _clearError();
      _resetImportCounters();

      final items = await _importExportService.importFromCSV();

      if (items == null || items.isEmpty) {
        _setError('No valid data found in CSV file. Please check the file format.');
        return false;
      }

      await _processImportItems(items);

      // Show summary of import results
      if (_failedImportsCount > 0) {
        _setError('Import completed with ${_importedItemsCount} success and ${_failedImportsCount} failures');
      } else {
        _clearError(); // Clear any previous errors on success
      }

      return _importedItemsCount > 0;

    } catch (e) {
      _setError('Import failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ ENHANCED - Export CSV with category names
  Future<String?> exportToCsv(List<InventoryItem> items) async {
    try {
      _setLoading(true);
      _clearError();
      _clearLastExport();

      if (items.isEmpty) {
        _setError('No items to export');
        return null;
      }

      final filePath = await _importExportService.exportToCSV(items);

      if (filePath != null) {
        _setLastExport(filePath);
        _clearError(); // Clear any previous errors on success
      }

      return filePath;

    } catch (e) {
      _setError('CSV export failed: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ ENHANCED - Export PDF with category names and full product names
  Future<String?> exportToPdf(List<InventoryItem> items, {bool includeBarcodes = false}) async {
    try {
      _setLoading(true);
      _clearError();
      _clearLastExport();

      if (items.isEmpty) {
        _setError('No items to export');
        return null;
      }

      String filePath;
      if (includeBarcodes) {
        filePath = await _importExportService.exportToPDFWithBarcodes(items);
      } else {
        filePath = await _importExportService.exportToPDF(items);
      }

      if (filePath.isNotEmpty) {
        _setLastExport(filePath);
        _clearError(); // Clear any previous errors on success
      }

      return filePath;

    } catch (e) {
      _setError('PDF export failed: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ NEW - Export only PDF with barcodes (convenience method)
  Future<String?> exportToPdfWithBarcodes(List<InventoryItem> items) async {
    return await exportToPdf(items, includeBarcodes: true);
  }

  // ✅ NEW - Export only PDF report (convenience method)
  Future<String?> exportToPdfReport(List<InventoryItem> items) async {
    return await exportToPdf(items, includeBarcodes: false);
  }

  // ✅ NEW - Get export format info
  Map<String, String> getExportFormats() {
    return {
      'csv': 'CSV Spreadsheet (with category names)',
      'pdf_report': 'PDF Report (table format)',
      'pdf_barcodes': 'PDF with Barcodes (printable labels)',
    };
  }

  // ✅ NEW - Validate items before export
  bool canExport(List<InventoryItem> items) {
    if (items.isEmpty) {
      _setError('No items available for export');
      return false;
    }

    _clearError();
    return true;
  }

  // ✅ ENHANCED - Process import items with detailed progress tracking
  Future<void> _processImportItems(List<InventoryItem> items) async {
    _importedItemsCount = 0;
    _failedImportsCount = 0;

    for (int i = 0; i < items.length; i++) {
      try {
        // Add item to inventory using BLoC
        _inventoryBloc.add(CreateInventoryItem(items[i]));

        _importedItemsCount++;
        _progress = (i + 1) / items.length;
        notifyListeners();

        // Prevent overwhelming the system
        await Future.delayed(Duration(milliseconds: 100));

      } catch (e) {
        _failedImportsCount++;
        debugPrint('Failed to import item ${items[i].sku}: $e');
      }
    }
  }

  // ✅ NEW - Reset import counters
  void _resetImportCounters() {
    _importedItemsCount = 0;
    _failedImportsCount = 0;
  }

  // ✅ NEW - Set last export path
  void _setLastExport(String path) {
    _lastExportPath = path;
    notifyListeners();
  }

  // ✅ NEW - Clear last export path
  void _clearLastExport() {
    _lastExportPath = null;
  }

  // ✅ ENHANCED - State management helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      _progress = 0.0;
    }
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ NEW - Clear all state
  void clearAll() {
    _clearError();
    _clearLastExport();
    _resetImportCounters();
    _progress = 0.0;
    notifyListeners();
  }

  // ✅ NEW - Get import summary
  String getImportSummary() {
    if (_importedItemsCount == 0 && _failedImportsCount == 0) {
      return 'No import performed yet';
    }

    return 'Imported: $_importedItemsCount items, Failed: $_failedImportsCount items';
  }

  // ✅ NEW - Check if currently processing
  bool get isProcessing => _isLoading && _progress > 0;

  // ✅ NEW - Get progress percentage
  String get progressPercentage => '${(_progress * 100).toInt()}%';

  // ✅ NEW - Get current operation status
  String getCurrentStatus() {
    if (!_isLoading) {
      if (_errorMessage != null) {
        return 'Error: $_errorMessage';
      }
      if (_lastExportPath != null) {
        return 'Export completed successfully';
      }
      if (_importedItemsCount > 0) {
        return 'Import completed: ${getImportSummary()}';
      }
      return 'Ready';
    }

    if (_progress > 0) {
      return 'Processing... ${progressPercentage}';
    }

    return 'Loading...';
  }

  @override
  void dispose() {
    // Clear any pending operations
    clearAll();
    super.dispose();
  }
}
