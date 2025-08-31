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
    return BlocProvider(
      create: (_) => getIt<InventoryBloc>()..add(LoadInventoryItems()),
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
      appBar: AppBar(
        title: Text('Inventory Management System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Wrap each IconButton with MouseRegion to prevent tracker issues
          MouseRegion(
            onEnter: (_) {},
            onExit: (_) {},
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isFilterPanelVisible = !_isFilterPanelVisible;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.filter_alt),
                ),
              ),
            ),
          ),
          MouseRegion(
            onEnter: (_) {},
            onExit: (_) {},
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  context.read<InventoryBloc>().add(RefreshInventoryItems());
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.refresh),
                ),
              ),
            ),
          ),
          MouseRegion(
            onEnter: (_) {},
            onExit: (_) {},
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => _showImportDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.upload_file),
                ),
              ),
            ),
          ),
          MouseRegion(
            onEnter: (_) {},
            onExit: (_) {},
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => _showExportDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.download),
                ),
              ),
            ),
          ),
          // Replace PopupMenuButton with custom implementation
          MouseRegion(
            onEnter: (_) {},
            onExit: (_) {},
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => _showMenuOptions(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.more_vert),
                ),
              ),
            ),
          ),
          SizedBox(width: 8), // Add some padding
        ],
      ),
      body: BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is InventoryItemCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Item created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is InventoryItemUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Item updated successfully'),
                backgroundColor: Colors.blue,
              ),
            );
          } else if (state is InventoryItemDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Item deleted successfully'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
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

              // Main Data Table
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16.0),
                  child: InventoryDataTable(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: MouseRegion(
        onEnter: (_) {},
        onExit: (_) {},
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemDialog(context),
          icon: Icon(Icons.add),
          label: Text('Add Item'),
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.category),
                title: Text('Manage Categories'),
                onTap: () {
                  Navigator.pop(context);
                  _showCategoryManagement(context);
                },
              ),
              // Add more menu items here as needed
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: context.read<InventoryBloc>(),
          ),
          BlocProvider(
            create: (_) => getIt<CategoryBloc>()..add(LoadCategories()),
          ),
        ],
        child: AddEditItemDialog(),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Data'),
        content: Text('CSV import functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data'),
        content: Text('Export functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCategoryManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleCategoryManager(),
    );
  }
}
