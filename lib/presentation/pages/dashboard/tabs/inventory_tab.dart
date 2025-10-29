// ✅ presentation/pages/dashboard/tabs/inventory_tab.dart (WITH PERMISSIONS!)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../../domain/entities/user.dart';
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // ✅ Get current user for permission checks
        final currentUser = authState is Authenticated ? authState.user : null;

        return Stack(
          children: [
            Column(
              children: [
                // Stats cards
                BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    return InventoryStatsCards();
                  },
                ),
                _buildActionBar(currentUser),
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
      },
    );
  }

  Widget _buildActionBar(User? currentUser) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    print('🔍 DEBUG: Current user: ${currentUser?.name}');
    print('🔍 DEBUG: Role: ${currentUser?.role.displayName}');
    print('🔍 DEBUG: Permissions: ${currentUser?.permissions.map((p) => p.name).toList()}');
    print('🔍 DEBUG: Has inventoryCreate? ${currentUser?.hasPermission(Permission.inventoryCreate)}');
    print('🔍 DEBUG: Has serialManage? ${currentUser?.hasPermission(Permission.serialManage)}');

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
          // Search bar - always visible
          Expanded(flex: 3, child: InventorySearchBar()),
          SizedBox(width: 16),

          // Filter button - always visible
          _buildFilterButton(isDark),
          SizedBox(width: 8),

          // Import/Export - only if has permission
          if (currentUser?.hasPermission(Permission.inventoryExport) == true) ...[
            _buildImportExportButton(currentUser!, isDark),
            SizedBox(width: 8),
          ],

          // Add button - only if has permission
          if (currentUser?.hasPermission(Permission.inventoryCreate) == true)
            _buildAddItemButton(currentUser!, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterButton(bool isDark) {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
      icon: Icon(_showFilterPanel ? Icons.filter_alt_off : Icons.filter_alt),
      label: Text(_showFilterPanel ? 'Hide Filters' : 'Filters'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _showFilterPanel
            ? (isDark ? Colors.orange[700] : Colors.orange)
            : (isDark ? Colors.grey[700] : Colors.grey[600]),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildImportExportButton(User currentUser, bool isDark) {
    return ElevatedButton.icon(
      onPressed: () {
        // ✅ Double-check permission before opening dialog
        if (!currentUser.hasPermission(Permission.inventoryExport)) {
          _showPermissionDeniedMessage('export data');
          return;
        }

        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: context.read<InventoryBloc>(),
            child: ImportExportDialog(),
          ),
        );
      },
      icon: Icon(Icons.import_export),
      label: Text('Import/Export'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAddItemButton(User currentUser, bool isDark) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: () {
        // ✅ Double-check permission before opening dialog
        if (!currentUser.hasPermission(Permission.inventoryCreate)) {
          _showPermissionDeniedMessage('add items');
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => BlocProvider.value(
            value: context.read<InventoryBloc>(),
            child: AddEditItemDialog(),
          ),
        );
      },
      icon: Icon(Icons.add),
      label: Text('Add Item'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            onTap: () {}, // Prevent closing when tapping inside
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

  // ✅ Helper method to show permission denied message
  void _showPermissionDeniedMessage(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You don\'t have permission to $action',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
