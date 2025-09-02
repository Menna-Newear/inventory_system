// presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../widgets/category/simple_category_manager.dart';
import '../../widgets/inventory/inventory_data_table.dart';
import '../../widgets/inventory/inventory_stats_cards.dart';
import '../../widgets/inventory/inventory_search_bar.dart';
import '../../widgets/inventory/inventory_filter_panel.dart';
import '../inventory/add_edit_item_dialog.dart';
import '../../../injection_container.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ✅ Provide both InventoryBloc and CategoryBloc
        BlocProvider(
          create: (_) => getIt<InventoryBloc>()..add(LoadInventoryItems()),
        ),
        BlocProvider(
          create: (_) => getIt<CategoryBloc>()..add(LoadCategories()),
        ),
      ],
      child: DashboardView(),
    );
  }
}

class DashboardView extends StatefulWidget {
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isFilterPanelVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: MultiBlocListener(
        listeners: [
          // ✅ Enhanced BlocListener for better user feedback
          BlocListener<InventoryBloc, InventoryState>(
            listener: (context, state) {
              if (state is InventoryError) {
                _showSnackBar(
                  context,
                  state.message,
                  Colors.red,
                  Icons.error,
                );
              } else if (state is InventoryItemCreated) {
                _showSnackBar(
                  context,
                  'Item created successfully',
                  Colors.green,
                  Icons.check_circle,
                );
              } else if (state is InventoryItemUpdated) {
                _showSnackBar(
                  context,
                  'Item updated successfully',
                  Colors.blue,
                  Icons.update,
                );
              } else if (state is InventoryItemDeleted) {
                _showSnackBar(
                  context,
                  'Item deleted successfully',
                  Colors.orange,
                  Icons.delete,
                );
              }
            },
          ),
          // ✅ CategoryBloc listener for category operations
          BlocListener<CategoryBloc, CategoryState>(
            listener: (context, state) {
              if (state is CategoryError) {
                _showSnackBar(
                  context,
                  'Category error: ${state.message}',
                  Colors.red,
                  Icons.error,
                );
              } else if (state is CategoryCreated) {
                _showSnackBar(
                  context,
                  'Category "${state.category.name}" created successfully',
                  Colors.green,
                  Icons.check_circle,
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: Column(
            children: [
              // Stats Cards
              InventoryStatsCards(),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: InventorySearchBar(),
              ),

              // Filter Panel (collapsible)
              if (_isFilterPanelVisible)
                InventoryFilterPanel(
                  onClose: () {
                    setState(() {
                      _isFilterPanelVisible = false;
                    });
                  },
                ),

              // Main Data Table with Inventory Item Data
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16.0),
                  padding: EdgeInsets.only(bottom: 45),
                  child: InventoryDataTable(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ✅ Enhanced AppBar with better styling
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory, color: Colors.white),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inventory Management System',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoaded) {
                    return Text(
                      '${state.totalItems} items • ${state.lowStockCount} low stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      actions: _buildAppBarActions(),
    );
  }

  // ✅ Enhanced AppBar actions
  List<Widget> _buildAppBarActions() {
    return [
      // Filter Toggle
      _buildActionButton(
        icon: _isFilterPanelVisible ? Icons.filter_alt : Icons.filter_alt_outlined,
        tooltip: _isFilterPanelVisible ? 'Hide Filters' : 'Show Filters',
        onPressed: () {
          setState(() {
            _isFilterPanelVisible = !_isFilterPanelVisible;
          });
        },
      ),

      // Refresh
      _buildActionButton(
        icon: Icons.refresh,
        tooltip: 'Refresh Data',
        onPressed: () {
          context.read<InventoryBloc>().add(RefreshInventoryItems());
          context.read<CategoryBloc>().add(LoadCategories());
        },
      ),

      // Import
      _buildActionButton(
        icon: Icons.upload_file,
        tooltip: 'Import Data',
        onPressed: () => _showImportDialog(context),
      ),

      // Export
      _buildActionButton(
        icon: Icons.download,
        tooltip: 'Export Data',
        onPressed: () => _showExportDialog(context),
      ),

      // More Options Menu
      _buildMenuButton(),

      SizedBox(width: 8),
    ];
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      tooltip: 'More Options',
      onSelected: (String value) {
        switch (value) {
          case 'manage_categories':
            _showCategoryManagement(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'manage_categories',
          child: Row(
            children: [
              Icon(Icons.category, size: 18),
              SizedBox(width: 8),
              Text('Manage Categories'),
            ],
          ),
        ),


      ],
      icon: Icon(Icons.more_vert, color: Colors.white),
    );
  }

  // ✅ Enhanced Floating Action Button
  Widget _buildFloatingActionButton() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        return FloatingActionButton.extended(
          onPressed: () => _showAddItemDialog(context),
          icon: Icon(Icons.add),
          label: Text('Add Item'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          extendedPadding: EdgeInsets.symmetric(horizontal: 20),
        );
      },
    );
  }

  // ✅ Enhanced Add Item Dialog with proper BLoC providers
  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: context.read<InventoryBloc>(),
          ),
          BlocProvider.value(
            value: context.read<CategoryBloc>(),
          ),
        ],
        child: AddEditItemDialog(),
      ),
    );
  }

  // ✅ Enhanced Import Dialog
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('Import Inventory Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import inventory data from a CSV file.'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CSV Format Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• SKU, Name (EN), Name (AR), Category, Subcategory'),
                  Text('• Stock Quantity, Unit Price, Min Stock Level'),
                  Text('• Width, Height, Depth (optional), Unit'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement CSV import functionality
              _showSnackBar(
                context,
                'CSV import functionality will be implemented',
                Colors.blue,
                Icons.info,
              );
            },
            icon: Icon(Icons.file_upload),
            label: Text('Select CSV File'),
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced Export Dialog
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('Export Inventory Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format for your inventory data:'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _exportToCsv(context);
                    },
                    icon: Icon(Icons.table_chart),
                    label: Text('CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _exportToPdf(context);
                    },
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportToCsv(BuildContext context) {
    // TODO: Implement CSV export
    _showSnackBar(
      context,
      'CSV export functionality will be implemented',
      Colors.green,
      Icons.file_download,
    );
  }

  void _exportToPdf(BuildContext context) {
    // TODO: Implement PDF export
    _showSnackBar(
      context,
      'PDF export functionality will be implemented',
      Colors.red,
      Icons.file_download,
    );
  }

  void _showCategoryManagement(BuildContext context) {
    final categoryBloc = context.read<CategoryBloc>();

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: categoryBloc,
        child: SimpleCategoryManager(),
      ),
    );
  }

  // ✅ Enhanced SnackBar helper
  void _showSnackBar(
      BuildContext context,
      String message,
      Color backgroundColor,
      IconData icon,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
