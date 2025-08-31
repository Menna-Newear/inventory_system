// presentation/widgets/inventory/import_export_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/import_export_service.dart';
import '../../blocs/inventory/inventory_bloc.dart';

class ImportExportDialog extends StatelessWidget {
  final ImportExportService _importExportService = ImportExportService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Import/Export Inventory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('Import from CSV'),
            subtitle: Text('Import inventory items from a CSV file'),
            onTap: () => _importFromCSV(context),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Export to CSV'),
            subtitle: Text('Export all inventory items to CSV'),
            onTap: () => _exportToCSV(context),
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Export to PDF'),
            subtitle: Text('Generate PDF inventory report'),
            onTap: () => _exportToPDF(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  void _importFromCSV(BuildContext context) async {
    try {
      final items = await _importExportService.importFromCSV();
      if (items != null && items.isNotEmpty) {
        // Add imported items to inventory
        for (final item in items) {
          context.read<InventoryBloc>().add(CreateInventoryItem(item));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${items.length} items'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportToCSV(BuildContext context) async {
    final state = context.read<InventoryBloc>().state;
    if (state is InventoryLoaded) {
      try {
        await _importExportService.exportToCSV(state.items);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportToPDF(BuildContext context) async {
    final state = context.read<InventoryBloc>().state;
    if (state is InventoryLoaded) {
      try {
        await _importExportService.exportToPDF(state.items);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
