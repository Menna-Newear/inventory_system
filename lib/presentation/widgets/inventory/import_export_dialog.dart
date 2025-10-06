// presentation/widgets/inventory/import_export_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../viewmodels/inventory_import_export_viewmodel.dart';

class ImportExportDialog extends StatelessWidget {
  const ImportExportDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ✅ FIXED - Create ViewModel with only InventoryBloc parameter
      create: (context) => InventoryImportExportViewModel(
        inventoryBloc: context.read<InventoryBloc>(),
      ),
      child: Consumer<InventoryImportExportViewModel>(
        builder: (context, viewModel, child) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.import_export, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text('Import/Export Data'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status display
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          viewModel.errorMessage != null
                              ? Icons.error
                              : viewModel.hasLastExport
                              ? Icons.check_circle
                              : Icons.info,
                          color: viewModel.errorMessage != null
                              ? Colors.red
                              : viewModel.hasLastExport
                              ? Colors.green
                              : Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.getCurrentStatus(),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (viewModel.isLoading) ...[
                    SizedBox(height: 16),
                    LinearProgressIndicator(value: viewModel.progress),
                    SizedBox(height: 8),
                    Text('${viewModel.progressPercentage} complete'),
                  ],

                  SizedBox(height: 20),

                  // Import section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.upload_file, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Import Data',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Import inventory items from CSV file'),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => _handleImport(context, viewModel),
                              icon: Icon(Icons.file_upload),
                              label: Text('Select CSV File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Export section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.download, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Export Data',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Export inventory data in various formats'),
                          SizedBox(height: 12),

                          // Export buttons
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () => _handleCsvExport(context, viewModel),
                                  icon: Icon(Icons.table_chart),
                                  label: Text('CSV Export (with category names)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),

                              SizedBox(height: 8),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () => _handlePdfReportExport(context, viewModel),
                                  icon: Icon(Icons.picture_as_pdf),
                                  label: Text('PDF Report'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),

                              SizedBox(height: 8),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () => _handlePdfBarcodeExport(context, viewModel),
                                  icon: Icon(Icons.qr_code),
                                  label: Text('PDF with Barcodes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (viewModel.hasLastExport) ...[
                TextButton(
                  onPressed: () => _showExportInfo(context, viewModel.lastExportPath!),
                  child: Text('View Export Info'),
                ),
              ],
              TextButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () {
                  viewModel.clearAll();
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, InventoryImportExportViewModel viewModel) async {
    final success = await viewModel.importFromCsv();

    if (success) {
      // Refresh inventory data
      context.read<InventoryBloc>().add(RefreshInventoryItems());

      _showSnackBar(
        context,
        'Import completed: ${viewModel.getImportSummary()}',
        Colors.green,
      );
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(context, viewModel.errorMessage!, Colors.red);
    }
  }

  Future<void> _handleCsvExport(BuildContext context, InventoryImportExportViewModel viewModel) async {
    final inventoryState = context.read<InventoryBloc>().state;

    if (inventoryState is! InventoryLoaded || inventoryState.displayItems.isEmpty) {
      _showSnackBar(context, 'No data to export', Colors.orange);
      return;
    }

    final filePath = await viewModel.exportToCsv(inventoryState.displayItems);

    if (filePath != null) {
      _showSnackBar(context, 'CSV exported successfully with category names', Colors.green);
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(context, viewModel.errorMessage!, Colors.red);
    }
  }

  Future<void> _handlePdfReportExport(BuildContext context, InventoryImportExportViewModel viewModel) async {
    final inventoryState = context.read<InventoryBloc>().state;

    if (inventoryState is! InventoryLoaded || inventoryState.displayItems.isEmpty) {
      _showSnackBar(context, 'No data to export', Colors.orange);
      return;
    }

    final filePath = await viewModel.exportToPdfReport(inventoryState.displayItems);

    if (filePath != null) {
      _showSnackBar(context, 'PDF report exported successfully', Colors.green);
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(context, viewModel.errorMessage!, Colors.red);
    }
  }

  Future<void> _handlePdfBarcodeExport(BuildContext context, InventoryImportExportViewModel viewModel) async {
    final inventoryState = context.read<InventoryBloc>().state;

    if (inventoryState is! InventoryLoaded || inventoryState.displayItems.isEmpty) {
      _showSnackBar(context, 'No data to export', Colors.orange);
      return;
    }

    final filePath = await viewModel.exportToPdfWithBarcodes(inventoryState.displayItems);

    if (filePath != null) {
      _showSnackBar(context, 'PDF with barcodes exported successfully', Colors.green);
    } else if (viewModel.errorMessage != null) {
      _showSnackBar(context, viewModel.errorMessage!, Colors.red);
    }
  }

  void _showExportInfo(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export completed successfully!'),
            SizedBox(height: 12),
            Text('File location:'),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                filePath,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
