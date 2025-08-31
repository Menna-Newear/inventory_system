// presentation/widgets/inventory/inventory_data_table.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../pages/inventory/add_edit_item_dialog.dart';

class InventoryDataTable extends StatelessWidget {
  final NumberFormat currencyFormat = NumberFormat.currency(symbol: '\$');
  final DateFormat dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is InventoryLoaded) {
          return _buildDataTable(context, state.displayItems);
        }

        if (state is InventoryError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading inventory',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(state.message),
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

        return Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildDataTable(BuildContext context, List<InventoryItem> items) {
    return Card(
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        columns: [
          DataColumn2(label: Text('Name'), size: ColumnSize.L),
          DataColumn2(label: Text('Name (AR)'), size: ColumnSize.L),
          DataColumn2(label: Text('SKU'), size: ColumnSize.S),
          DataColumn2(label: Text('Category'), size: ColumnSize.M),
          DataColumn2(label: Text('Subcategory'), size: ColumnSize.M),
          DataColumn2(label: Text('Stock'), size: ColumnSize.S, numeric: true),
          DataColumn2(label: Text('Price'), size: ColumnSize.S, numeric: true),
          DataColumn2(
            label: Text('Total Value'),
            size: ColumnSize.S,
            numeric: true,
          ),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Updated'), size: ColumnSize.M),
          DataColumn2(label: Text('Actions'), size: ColumnSize.S),
        ],
        rows: items.map((item) => _buildDataRow(context, item)).toList(),
        empty: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            color: Colors.grey[50],
            child: Text('No items found'),
          ),
        ),
      ),
    );
  }

  DataRow2 _buildDataRow(BuildContext context, InventoryItem item) {
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
            child: Text(item.categoryId, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(item.subcategory)),
        DataCell(
          Text(
            item.stockQuantity.toString(),
            style: TextStyle(
              color: item.isLowStock ? Colors.red : null,
              fontWeight: item.isLowStock ? FontWeight.bold : null,
            ),
          ),
        ),
        DataCell(Text(currencyFormat.format(item.unitPrice))),
        DataCell(Text(currencyFormat.format(item.totalValue))),
        DataCell(_buildStatusChip(item)),
        DataCell(Text(dateFormat.format(item.updatedAt))),
        DataCell(_buildActionButtons(context, item)),
      ],
    );
  }

  Widget _buildStatusChip(InventoryItem item) {
    if (item.isLowStock) {
      return Chip(
        label: Text('Low Stock'),
        backgroundColor: Colors.red[100],
        labelStyle: TextStyle(color: Colors.red[800]),
        avatar: Icon(Icons.warning, size: 16, color: Colors.red[800]),
      );
    } else if (item.stockQuantity == 0) {
      return Chip(
        label: Text('Out of Stock'),
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(color: Colors.grey[800]),
      );
    } else {
      return Chip(
        label: Text('In Stock'),
        backgroundColor: Colors.green[100],
        labelStyle: TextStyle(color: Colors.green[800]),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, InventoryItem item) {
    return FittedBox(
      fit: BoxFit.scaleDown,

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, size: 18),
            onPressed: () => _editItem(context, item),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () => _deleteItem(context, item),
            tooltip: 'Delete',
          ),
          IconButton(
            icon: Icon(Icons.qr_code, size: 18),
            onPressed: () => _generateQRCode(context, item),
            tooltip: 'Generate QR Code',
          ),
        ],
      ),
    );
  }

  void _editItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AddEditItemDialog(item: item),
    );
  }

  void _deleteItem(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.nameEn}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<InventoryBloc>().add(DeleteInventoryItem(item.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _generateQRCode(BuildContext context, InventoryItem item) {
    // TODO: Implement QR code generation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR Code generation for ${item.nameEn}')),
    );
  }
}
