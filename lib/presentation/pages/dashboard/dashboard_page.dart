// presentation/pages/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../data/services/import_export_service.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../viewmodels/inventory_import_export_viewmodel.dart';
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
  late InventoryImportExportViewModel _importExportViewModel;

  @override
  void initState() {
    super.initState();
    // ✅ FIXED - Initialize ViewModel in initState where context is available
    _importExportViewModel = InventoryImportExportViewModel(
      inventoryBloc: context.read<InventoryBloc>(),
    );
  }

  @override
  void dispose() {
    _importExportViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED - Provide the ViewModel instance using ChangeNotifierProvider.value
    return ChangeNotifierProvider<InventoryImportExportViewModel>.value(
      value: _importExportViewModel,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: MultiBlocListener(
          listeners: [
            BlocListener<InventoryBloc, InventoryState>(
              listener: (context, state) {
                if (state is InventoryError) {
                  _showSnackBar(context, state.message, Colors.red, Icons.error);
                } else if (state is InventoryItemCreated) {
                  _showSnackBar(context, 'Item created successfully', Colors.green, Icons.check_circle);
                } else if (state is InventoryItemUpdated) {
                  _showSnackBar(context, 'Item updated successfully', Colors.blue, Icons.update);
                } else if (state is InventoryItemDeleted) {
                  _showSnackBar(context, 'Item deleted successfully', Colors.orange, Icons.delete);
                }
              },
            ),
            BlocListener<CategoryBloc, CategoryState>(
              listener: (context, state) {
                if (state is CategoryError) {
                  _showSnackBar(context, 'Category error: ${state.message}', Colors.red, Icons.error);
                } else if (state is CategoryCreated) {
                  _showSnackBar(context, 'Category "${state.category.name}" created successfully', Colors.green, Icons.check_circle);
                }
              },
            ),
          ],
          child: SafeArea(
            child: Column(
              children: [
                InventoryStatsCards(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: InventorySearchBar(),
                ),
                if (_isFilterPanelVisible)
                  InventoryFilterPanel(
                    onClose: () => setState(() => _isFilterPanelVisible = false),
                  ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16.0),
                    padding: EdgeInsets.only(bottom: 100),
                    child: InventoryDataTable(),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoaded) {
                    return Text(
                      '${state.totalItems} items • ${state.lowStockCount} low stock',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
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

  List<Widget> _buildAppBarActions() {
    return [
      _buildActionButton(
        icon: _isFilterPanelVisible ? Icons.filter_alt : Icons.filter_alt_outlined,
        tooltip: _isFilterPanelVisible ? 'Hide Filters' : 'Show Filters',
        onPressed: () => setState(() => _isFilterPanelVisible = !_isFilterPanelVisible),
      ),
      _buildActionButton(
        icon: Icons.refresh,
        tooltip: 'Refresh Data',
        onPressed: () {
          context.read<InventoryBloc>().add(RefreshInventoryItems());
          context.read<CategoryBloc>().add(LoadCategories());
        },
      ),
      _buildActionButton(
        icon: Icons.upload_file,
        tooltip: 'Import Data',
        onPressed: () => _showImportDialog(context),
      ),
      _buildActionButton(
        icon: Icons.download,
        tooltip: 'Export Data',
        onPressed: () => _showExportDialog(context),
      ),
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

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<InventoryBloc>()),
          BlocProvider.value(value: context.read<CategoryBloc>()),
        ],
        child: AddEditItemDialog(),
      ),
    );
  }

  // ✅ FIXED - Import Dialog using Provider.of instead of Consumer
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ListenableBuilder(
        listenable: _importExportViewModel,
        builder: (context, child) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text('Import Inventory Data'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_importExportViewModel.isLoading) ...[
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 16),
                  if (_importExportViewModel.progress > 0) ...[
                    LinearProgressIndicator(value: _importExportViewModel.progress),
                    SizedBox(height: 8),
                    Center(child: Text('Importing... ${(_importExportViewModel.progress * 100).toInt()}%')),
                  ] else ...[
                    Center(child: Text('Selecting and processing CSV file...')),
                  ],
                ] else ...[
                  Text('Import inventory data from a CSV file.'),
                  SizedBox(height: 16),
                  _buildCsvFormatInfo(),
                  if (_importExportViewModel.errorMessage != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _importExportViewModel.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: _importExportViewModel.isLoading
              ? []
              : [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => _handleImport(dialogContext),
              icon: Icon(Icons.file_upload),
              label: Text('Select CSV File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED - Export Dialog using direct ViewModel access
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: _importExportViewModel,
        builder: (context, child) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.download, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text('Export Inventory Data'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_importExportViewModel.isLoading) ...[
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 16),
                  Text('Exporting data...'),
                ] else ...[
                  Text('Choose export format for your inventory data:'),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleCsvExport(dialogContext),
                          icon: Icon(Icons.table_chart),
                          label: Text('CSV Export'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handlePdfExport(dialogContext, false),
                          icon: Icon(Icons.picture_as_pdf),
                          label: Text('PDF Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handlePdfExport(dialogContext, true),
                          icon: Icon(Icons.qr_code),
                          label: Text('PDF with Barcodes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_importExportViewModel.errorMessage != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _importExportViewModel.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: _importExportViewModel.isLoading
              ? []
              : [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED - Direct ViewModel method calls
  Future<void> _handleImport(BuildContext dialogContext) async {
    try {
      final success = await _importExportViewModel.importFromCsv();

      if (success) {
        Navigator.pop(dialogContext);
        _showSnackBar(context, 'Import completed successfully', Colors.green, Icons.check_circle);
        context.read<InventoryBloc>().add(RefreshInventoryItems());
        _showImportSuccessDialog(context);
      }
    } catch (e) {
      if (_importExportViewModel.errorMessage == null) {
        _showSnackBar(context, 'Import failed: ${e.toString()}', Colors.red, Icons.error);
      }
    }
  }

  Future<void> _handleCsvExport(BuildContext dialogContext) async {
    final inventoryState = context.read<InventoryBloc>().state;

    if (inventoryState is! InventoryLoaded || inventoryState.displayItems.isEmpty) {
      _showSnackBar(context, 'No data to export', Colors.orange, Icons.warning);
      return;
    }

    try {
      final filePath = await _importExportViewModel.exportToCsv(inventoryState.displayItems);
      Navigator.pop(dialogContext);

      if (filePath != null) {
        _showSnackBar(context, 'CSV exported successfully', Colors.green, Icons.check_circle);
        _showExportSuccessDialog(context, filePath, 'CSV');
      }
    } catch (e) {
      _showSnackBar(context, 'Export failed: ${e.toString()}', Colors.red, Icons.error);
    }
  }

  Future<void> _handlePdfExport(BuildContext dialogContext, bool includeBarcodes) async {
    final inventoryState = context.read<InventoryBloc>().state;

    if (inventoryState is! InventoryLoaded || inventoryState.displayItems.isEmpty) {
      _showSnackBar(context, 'No data to export', Colors.orange, Icons.warning);
      return;
    }

    try {
      final filePath = await _importExportViewModel.exportToPdf(
        inventoryState.displayItems,
        includeBarcodes: includeBarcodes,
      );
      Navigator.pop(dialogContext);

      if (filePath != null) {
        final exportType = includeBarcodes ? 'PDF with Barcodes' : 'PDF Report';
        _showSnackBar(context, '$exportType exported successfully', Colors.green, Icons.check_circle);
        _showExportSuccessDialog(context, filePath, exportType);
      }
    } catch (e) {
      _showSnackBar(context, 'Export failed: ${e.toString()}', Colors.red, Icons.error);
    }
  }

  Widget _buildCsvFormatInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Text(
                'CSV Format Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('• SKU, Name (EN), Name (AR), Category ID, Subcategory'),
          Text('• Stock Quantity, Unit Price, Min Stock Level'),
          Text('• Width, Height, Depth (optional), Unit'),
          Text('• Pixel Width, Pixel Height, Other Sp., Color Space'),
        ],
      ),
    );
  }

  void _showImportSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Import Successful'),
          ],
        ),
        content: Text('Your inventory data has been imported successfully.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportSuccessDialog(BuildContext context, String filePath, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your inventory has been exported to $format format.'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(filePath, style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  void _showCategoryManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: SimpleCategoryManager(),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor, IconData icon) {
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
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}
