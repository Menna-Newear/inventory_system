// presentation/widgets/order/forms/item_selector_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/inventory_item.dart';
import '../../../../domain/entities/order.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/serial/serial_number_bloc.dart';
import '../../../blocs/serial/serial_number_event.dart';
import '../models/order_form_data.dart';
import '../serial_selection_dialog.dart';
import '../../../../injection_container.dart' as di;

class ItemSelectorGrid extends StatefulWidget {
  final OrderFormData formData;
  final VoidCallback onItemsChanged;

  const ItemSelectorGrid({
    Key? key,
    required this.formData,
    required this.onItemsChanged,
  }) : super(key: key);

  @override
  State<ItemSelectorGrid> createState() => _ItemSelectorGridState();
}

class _ItemSelectorGridState extends State<ItemSelectorGrid> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, int> _tempQuantities = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search items by name or SKU...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return _buildLoadingView();
        } else if (state is InventoryLoaded) {
          final filteredItems = _filterItems(state.displayItems);
          if (filteredItems.isEmpty) {
            return _buildEmptyView();
          }
          return _buildItemsGrid(filteredItems);
        } else if (state is InventoryError) {
          return _buildErrorView(state.message);
        }
        return _buildEmptyView();
      },
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading inventory items...'),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No items available in stock'
                : 'No items found for "$_searchQuery"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Error loading inventory', style: TextStyle(fontSize: 16)),
          Text(message, style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<InventoryBloc>().add(LoadInventoryItems()),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(List<InventoryItem> items) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    final currentQuantity = _tempQuantities[item.id] ?? 1;
    final isInOrder = widget.formData.selectedItems.containsKey(item.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stock, status, and serial indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStockColor(item).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stock: ${item.stockQuantity}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStockColor(item),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // ✅ NEW: Serial tracking indicator
                    if (item.isSerialTracked)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_2, size: 12, color: Colors.purple[700]),
                            SizedBox(width: 2),
                            Text(
                              'Serial',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isInOrder)
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                  ],
                ),
              ],
            ),

            SizedBox(height: 8),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameEn.isNotEmpty ? item.nameEn : 'Unknown Item',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text('SKU: ${item.sku.isNotEmpty ? item.sku : 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  Text('Price: \$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Quantity controls
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildQuantityButton(Icons.remove, () => _decrementQuantity(item.id)),
                      Container(
                        width: 30,
                        child: Center(
                          child: Text('$currentQuantity', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      _buildQuantityButton(Icons.add,
                          currentQuantity < item.stockQuantity ? () => _incrementQuantity(item.id) : null),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addToOrder(item, currentQuantity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInOrder ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  isInOrder ? 'Update' : 'Add',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.grey[200] : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: onTap != null ? Colors.black87 : Colors.grey),
      ),
    );
  }

  List<InventoryItem> _filterItems(List<InventoryItem> items) {
    return items
        .where((item) =>
    item.stockQuantity > 0 &&
        (item.nameEn.toLowerCase().contains(_searchQuery) || item.sku.toLowerCase().contains(_searchQuery)))
        .toList();
  }

  void _incrementQuantity(String itemId) {
    setState(() {
      _tempQuantities[itemId] = (_tempQuantities[itemId] ?? 1) + 1;
    });
  }

  void _decrementQuantity(String itemId) {
    setState(() {
      final current = _tempQuantities[itemId] ?? 1;
      if (current > 1) {
        _tempQuantities[itemId] = current - 1;
      }
    });
  }

  Future<void> _addToOrder(InventoryItem item, int quantity) async {
    List<String>? selectedSerialNumbers; // ✅ These will now be serial number strings, not IDs

    if (item.isSerialTracked) {
      selectedSerialNumbers = await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider(
          create: (_) => di.getIt<SerialNumberBloc>()..add(LoadSerialNumbers(item.id)),
          child: SerialSelectionDialog(
            item: item,
            requiredQuantity: quantity,
          ),
        ),
      );

      if (selectedSerialNumbers == null || selectedSerialNumbers.length != quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Serial selection is required for this item. Please select ${quantity} serial number(s).',
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      widget.formData.selectedItems[item.id] = SelectedOrderItem(
        id: item.id,
        name: item.nameEn.isNotEmpty ? item.nameEn : 'Unknown Item',
        sku: item.sku.isNotEmpty ? item.sku : 'N/A',
        quantity: quantity,
        unitPrice: item.unitPrice ?? 0.0,
        totalPrice: (item.unitPrice ?? 0.0) * quantity,
        serialNumbers: selectedSerialNumbers, // ✅ Now contains actual serial numbers like "7071-0001"
      );
    });

    widget.onItemsChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedSerialNumbers != null
                    ? '✅ Added ${item.nameEn} with serials: ${selectedSerialNumbers.join(", ")}'
                    : '✅ Added ${item.nameEn} to order',
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStockColor(InventoryItem item) {
    if (item.stockQuantity <= 0) return Colors.red;
    if (item.stockQuantity < item.minStockLevel) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
