// ✅ presentation/pages/dashboard/tabs/inventory_tab.dart
import 'package:flutter/material.dart';
import '../../../widgets/inventory/inventory_stats_cards.dart';
import '../../../widgets/inventory/inventory_search_bar.dart';
import '../../../widgets/inventory/inventory_filter_panel.dart';
import '../../../widgets/inventory/inventory_data_table.dart';
import '../../../widgets/inventory/import_export_dialog.dart';
import '../../inventory/add_edit_item_dialog.dart';

class InventoryTab extends StatefulWidget {
  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  bool _showFilterPanel = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InventoryStatsCards(),
        _buildActionBar(),
        if (_showFilterPanel)
          InventoryFilterPanel(
            onClose: () => setState(() => _showFilterPanel = false),
          ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            child: InventoryDataTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: InventorySearchBar()),
          SizedBox(width: 16),
          _buildFilterButton(),
          SizedBox(width: 8),
          _buildImportExportButton(),
          SizedBox(width: 8),
          _buildAddItemButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
      icon: Icon(_showFilterPanel ? Icons.filter_alt_off : Icons.filter_alt),
      label: Text(_showFilterPanel ? 'Hide Filters' : 'Filters'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _showFilterPanel ? Colors.orange : Colors.grey[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildImportExportButton() {
    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => ImportExportDialog(),
      ),
      icon: Icon(Icons.import_export),
      label: Text('Import/Export'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAddItemButton() {
    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AddEditItemDialog(),
      ),
      icon: Icon(Icons.add),
      label: Text('Add Item'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
