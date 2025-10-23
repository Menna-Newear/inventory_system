// ✅ presentation/pages/dashboard/tabs/inventory_tab.dart (THEME-AWARE)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
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
    return Stack(
      children: [
        Column(
          children: [
            // ✅ Wrap InventoryStatsCards in BlocBuilder to rebuild on changes
            BlocBuilder<InventoryBloc, InventoryState>(
              builder: (context, state) {
                return InventoryStatsCards();
              },
            ),
            _buildActionBar(),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: InventoryDataTable(),
              ),
            ),
          ],
        ),
        if (_showFilterPanel) _buildFilterDrawer(),
      ],
    );
  }

  Widget _buildActionBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
      icon: Icon(_showFilterPanel ? Icons.filter_alt_off : Icons.filter_alt),
      label: Text(_showFilterPanel ? 'Hide Filters' : 'Filters'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _showFilterPanel
            ? (isDark ? Colors.orange[700] : Colors.orange)
            : (isDark ? Colors.grey[700] : Colors.grey[600]),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildImportExportButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => ImportExportDialog(),
      ),
      icon: Icon(Icons.import_export),
      label: Text('Import/Export'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
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

  Widget _buildFilterDrawer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _showFilterPanel = false),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 450,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.26),
                    blurRadius: 10,
                    offset: Offset(-5, 0),
                  ),
                ],
              ),
              child: InventoryFilterPanel(
                onClose: () => setState(() => _showFilterPanel = false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
