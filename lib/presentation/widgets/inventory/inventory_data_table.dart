// ✅ presentation/widgets/inventory/inventory_data_table.dart (FIXED WITH SMART REBUILDS)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system/presentation/dialogs/enhanced_barcode_dialog.dart';
import 'package:inventory_system/presentation/widgets/inventory/serial_number_dialog.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../blocs/serial/serial_number_bloc.dart';
import '../../blocs/serial/serial_number_event.dart';
import '../../pages/inventory/add_edit_item_dialog.dart';
import '../../../injection_container.dart';

class InventoryDataTable extends StatelessWidget {
  final NumberFormat currencyFormat = NumberFormat.currency(symbol: '\$');
  final DateFormat dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      // ✅ Only rebuild when InventoryLoaded state changes
      buildWhen: (previous, current) {
        // Don't rebuild for intermediate states
        if (current is InventoryItemCreated) return false;
        if (current is InventoryItemUpdated) return false;
        if (current is InventoryItemDeleted) return false;

        // Rebuild for loading, loaded, error, initial
        return true;
      },
      // ✅ Listen to state changes and update without rebuild
      listener: (context, state) {
        if (state is InventoryItemUpdated) {
          print('✅ TABLE: Item updated - state will refresh automatically');
        } else if (state is InventoryItemCreated) {
          print('✅ TABLE: Item created - state will refresh automatically');
        } else if (state is InventoryItemDeleted) {
          print('✅ TABLE: Item deleted - state will refresh automatically');
        }
      },
      builder: (context, inventoryState) {
        if (inventoryState is InventoryLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading inventory...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        if (inventoryState is InventoryLoaded) {
          return BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, categoryState) {
              Map<String, String> categoryNamesMap = {};

              if (categoryState is CategoryLoaded) {
                for (var category in categoryState.categories) {
                  categoryNamesMap[category.id] = category.name;
                }
              }

              return _buildDataTable(
                context,
                inventoryState.displayItems,
                categoryNamesMap,
              );
            },
          );
        }

        if (inventoryState is InventoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading inventory', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 8),
                Text(inventoryState.message),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<InventoryBloc>().add(LoadInventoryItems());
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataTable(
      BuildContext context,
      List<InventoryItem> items,
      Map<String, String> categoryNamesMap,
      ) {
    return Card(
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1200,
        columns: [
          DataColumn2(label: Text('SKU'), size: ColumnSize.S),
          DataColumn2(label: Text('Name'), size: ColumnSize.L),
          DataColumn2(label: Text('Name (AR)'), size: ColumnSize.L),
          DataColumn2(label: Text('Category'), size: ColumnSize.M),
          DataColumn2(label: Text('Subcategory'), size: ColumnSize.M),
          DataColumn2(label: Text('Stock'), size: ColumnSize.S, numeric: true),
          DataColumn2(label: Text('Serials'), size: ColumnSize.S, numeric: true),
          DataColumn2(label: Text('Price'), size: ColumnSize.S, numeric: true),
          DataColumn2(label: Text('Total Value'), size: ColumnSize.S, numeric: true),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Updated'), size: ColumnSize.M),
          DataColumn2(label: Text('Actions'), size: ColumnSize.M),
        ],
        rows: items.map((item) => _buildDataRow(context, item, categoryNamesMap)).toList(),
        empty: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            color: Colors.grey[50],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('No items found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'N/A';
    return currencyFormat.format(amount);
  }

  String _formatTotalValue(InventoryItem item) {
    if (item.unitPrice == null) return 'N/A';
    final totalValue = item.unitPrice! * item.stockQuantity;
    return currencyFormat.format(totalValue);
  }

  String _getCategoryName(String categoryId, Map<String, String> categoryNamesMap) {
    return categoryNamesMap[categoryId] ?? 'Unknown Category';
  }

  String _formatSerialInfo(InventoryItem item) {
    if (!item.isSerialTracked) {
      return 'N/A';
    }

    final total = item.serialNumbers.length;

    if (total == 0) {
      return 'No Serials';
    }

    final available = item.serialNumbers.where((s) => s.status == SerialStatus.available).length;
    return '$available/$total';
  }

  DataRow2 _buildDataRow(
      BuildContext context,
      InventoryItem item,
      Map<String, String> categoryNamesMap,
      ) {
    return DataRow2(
      cells: [
        DataCell(Text(item.sku, style: TextStyle(fontWeight: FontWeight.w500))),
        DataCell(
          Container(
            constraints: BoxConstraints(maxWidth: 250),
            child: Text(
              item.nameEn,
              style: TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(
          Container(
            constraints: BoxConstraints(maxWidth: 250),
            child: Text(
              item.nameAr.isNotEmpty ? item.nameAr : '-',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(
          Container(
            constraints: BoxConstraints(maxWidth: 150),
            child: Tooltip(
              message: 'Category ID: ${item.categoryId}',
              child: Text(
                _getCategoryName(item.categoryId, categoryNamesMap),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: categoryNamesMap.containsKey(item.categoryId) ? null : Colors.red,
                ),
              ),
            ),
          ),
        ),
        DataCell(Text(item.subcategory)),
        DataCell(
          Text(
            item.stockQuantity.toString(),
            style: TextStyle(
              color: item.needsRestock ? Colors.red : null,
              fontWeight: item.needsRestock ? FontWeight.bold : null,
            ),
          ),
        ),
        DataCell(
          GestureDetector(
            onTap: item.isSerialTracked ? () => _showSerialDialog(context, item) : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.isSerialTracked ? Colors.blue[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: item.isSerialTracked ? Colors.blue[200]! : Colors.grey[300]!,
                ),
              ),
              child: Text(
                _formatSerialInfo(item),
                style: TextStyle(
                  color: item.isSerialTracked ? Colors.blue[700] : Colors.grey[600],
                  fontWeight: item.isSerialTracked ? FontWeight.w500 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            _formatCurrency(item.unitPrice),
            style: TextStyle(
              color: item.unitPrice == null ? Colors.grey : null,
              fontStyle: item.unitPrice == null ? FontStyle.italic : null,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatTotalValue(item),
            style: TextStyle(
              color: item.unitPrice == null ? Colors.grey : null,
              fontStyle: item.unitPrice == null ? FontStyle.italic : null,
            ),
          ),
        ),
        DataCell(_buildStatusChip(item)),
        DataCell(Text(dateFormat.format(item.updatedAt))),
        DataCell(_buildActionButtons(context, item)),
      ],
    );
  }

  Widget _buildStatusChip(InventoryItem item) {
    if (item.stockQuantity == 0) {
      return Chip(
        label: Text('Out of Stock'),
        backgroundColor: Colors.red[100],
        labelStyle: TextStyle(color: Colors.red[800]),
        avatar: Icon(Icons.cancel, size: 16, color: Colors.red[800]),
      );
    } else if (item.needsRestock) {
      return Chip(
        label: Text('Low Stock'),
        backgroundColor: Colors.orange[100],
        labelStyle: TextStyle(color: Colors.orange[800]),
        avatar: Icon(Icons.warning, size: 16, color: Colors.orange[800]),
      );
    } else {
      return Chip(
        label: Text(item.isSerialTracked ? 'Serial Tracked' : 'In Stock'),
        backgroundColor: item.isSerialTracked ? Colors.blue[100] : Colors.green[100],
        labelStyle: TextStyle(
          color: item.isSerialTracked ? Colors.blue[800] : Colors.green[800],
        ),
        avatar: Icon(
          item.isSerialTracked ? Icons.qr_code_2 : Icons.check_circle,
          size: 16,
          color: item.isSerialTracked ? Colors.blue[800] : Colors.green[800],
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, InventoryItem item) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            child: IconButton(
              icon: Icon(Icons.edit, size: 16),
              onPressed: () => _editItem(context, item),
              tooltip: 'Edit Item',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          SizedBox(width: 4),
          if (item.isSerialTracked) ...[
            Container(
              width: 32,
              height: 32,
              child: IconButton(
                icon: Icon(Icons.qr_code_scanner, size: 16),
                onPressed: () => _showSerialDialog(context, item),
                tooltip: 'Manage Serials',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  foregroundColor: Colors.purple,
                ),
              ),
            ),
            SizedBox(width: 4),
          ],
          Container(
            width: 32,
            height: 32,
            child: IconButton(
              icon: Icon(Icons.delete, size: 16),
              onPressed: () => _deleteItem(context, item),
              tooltip: 'Delete Item',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
              ),
            ),
          ),
          SizedBox(width: 4),
          Container(
            width: 32,
            height: 32,
            child: IconButton(
              icon: Icon(Icons.qr_code, size: 16),
              onPressed: () => _showQrCode(context, item),
              tooltip: 'Show QR Code',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
              ),
            ),
          ),
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
            SizedBox(width: 4),
            Container(
              width: 32,
              height: 32,
              child: IconButton(
                icon: Icon(Icons.image, size: 16),
                onPressed: () => _viewImage(context, item),
                tooltip: 'View Image',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ FIXED - Don't reload all items
  void _showSerialDialog(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => getIt<SerialNumberBloc>()..add(LoadSerialNumbers(item.id)),
        child: SerialNumberDialog(
          item: item,
          onUpdated: () {
            // ✅ Refresh only this single item
            context.read<InventoryBloc>().add(RefreshSingleItem(item.id));
            print('🔄 TABLE: Requesting refresh for item: ${item.id}');
          },        ),
      ),
    );
  }

  void _editItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<InventoryBloc>()),
          BlocProvider(create: (_) => getIt<CategoryBloc>()..add(LoadCategories())),
        ],
        child: AddEditItemDialog(item: item),
      ),
    );
  }

  void _deleteItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this item?'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Item: ${item.nameEn}', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('SKU: ${item.sku}'),
                  Text('Stock: ${item.stockQuantity}'),
                  if (item.unitPrice != null) Text('Price: ${_formatCurrency(item.unitPrice)}'),
                  if (item.isSerialTracked)
                    Text(
                      'Serial Numbers: ${item.serialNumbers.length} will be deleted',
                      style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<InventoryBloc>().add(DeleteInventoryItem(item.id));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Item "${item.nameEn}" deleted successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQrCode(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => EnhancedBarcodeDialog(item: item),
    );
  }

  void _viewImage(BuildContext context, InventoryItem item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            constraints: BoxConstraints(maxWidth: 700, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Product Image - ${item.nameEn}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, size: 48, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text('Failed to load image', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
