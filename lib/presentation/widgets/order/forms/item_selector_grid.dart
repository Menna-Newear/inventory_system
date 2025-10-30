// ✅ presentation/widgets/order/forms/item_selector_grid.dart (FULLY LOCALIZED!)
import 'package:easy_localization/easy_localization.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildSearchBar(theme, isDark),
        Expanded(child: _buildItemsList(theme, isDark)),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'item_selector.search_hint'.tr(),
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
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
            borderSide: BorderSide(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme, bool isDark) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return _buildLoadingView(theme);
        } else if (state is InventoryLoaded) {
          final filteredItems = _filterItems(state.items);

          if (filteredItems.isEmpty) {
            return _buildEmptyView(theme, isDark);
          }
          return _buildItemsGrid(filteredItems, theme, isDark);
        } else if (state is InventoryError) {
          return _buildErrorView(state.message, theme);
        }
        return _buildEmptyView(theme, isDark);
      },
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primaryColor),
          SizedBox(height: 16),
          Text(
            'item_selector.loading'.tr(),
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 72,
            color: theme.disabledColor,
          ),
          SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? 'item_selector.no_items'.tr()
                : 'item_selector.no_results'.tr(namedArgs: {'query': _searchQuery}),
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Text('item_selector.clear_search'.tr()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'item_selector.error_title'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<InventoryBloc>().add(LoadInventoryItems()),
            icon: Icon(Icons.refresh),
            label: Text('item_selector.retry'.tr()),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(
      List<InventoryItem> items, ThemeData theme, bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index], theme, isDark),
    );
  }

  Widget _buildItemCard(InventoryItem item, ThemeData theme, bool isDark) {
    final currentQuantity = _tempQuantities[item.id] ?? 1;
    final isInOrder = widget.formData.selectedItems.containsKey(item.id);

    return Card(
      elevation: isDark ? 2 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? theme.cardColor : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStockColor(item).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _getStockColor(item).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '${'item_selector.stock'.tr()} ${item.stockQuantity}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStockColor(item),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (item.isSerialTracked)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.purple[900]?.withOpacity(0.3)
                              : Colors.purple[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.purple[isDark ? 600 : 300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 13,
                              color: Colors.purple[isDark ? 300 : 700],
                            ),
                            SizedBox(width: 3),
                            Text(
                              'item_selector.serial_badge'.tr(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[isDark ? 300 : 700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isInOrder)
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameEn.isNotEmpty
                        ? item.nameEn
                        : 'item_selector.unknown_item'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${'item_selector.sku'.tr()} ${item.sku.isNotEmpty ? item.sku : 'N/A'}',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${'item_selector.price'.tr()} \$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      color: Colors.green[isDark ? 400 : 700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]?.withOpacity(0.5)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'item_selector.quantity'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Row(
                    children: [
                      _buildQuantityButton(
                        Icons.remove,
                            () => _decrementQuantity(item.id),
                        theme,
                      ),
                      Container(
                        width: 35,
                        child: Center(
                          child: Text(
                            '$currentQuantity',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        Icons.add,
                        currentQuantity < item.stockQuantity
                            ? () => _incrementQuantity(item.id)
                            : null,
                        theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToOrder(item, currentQuantity),
                icon: Icon(
                  isInOrder ? Icons.edit : Icons.add_shopping_cart,
                  size: 16,
                ),
                label: Text(
                  isInOrder
                      ? 'item_selector.update_order'.tr()
                      : 'item_selector.add_to_order'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInOrder ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(
      IconData icon,
      VoidCallback? onTap,
      ThemeData theme,
      ) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? (isDark ? Colors.grey[700] : Colors.grey[300])
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? theme.iconTheme.color : theme.disabledColor,
        ),
      ),
    );
  }

  List<InventoryItem> _filterItems(List<InventoryItem> items) {
    return items
        .where((item) =>
    item.stockQuantity > 0 &&
        (item.nameEn.toLowerCase().contains(_searchQuery) ||
            item.sku.toLowerCase().contains(_searchQuery)))
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
    List<String>? selectedSerialNumbers;

    if (item.isSerialTracked) {
      final isRentalOrder = widget.formData.orderType == OrderType.rental;
      final rentalStartDate = isRentalOrder ? widget.formData.rentalStartDate : null;
      final rentalEndDate = isRentalOrder ? widget.formData.rentalEndDate : null;

      selectedSerialNumbers = await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider(
          create: (_) {
            final bloc = di.getIt<SerialNumberBloc>();
            if (rentalStartDate != null && rentalEndDate != null) {
              bloc.add(LoadAvailableSerialsByDate(
                item.id,
                startDate: rentalStartDate,
                endDate: rentalEndDate,
              ));
            } else {
              bloc.add(LoadSerialNumbers(item.id));
            }
            return bloc;
          },
          child: SerialSelectionDialog(
            item: item,
            requiredQuantity: quantity,
            rentalStartDate: rentalStartDate,
            rentalEndDate: rentalEndDate,
          ),
        ),
      );

      if (selectedSerialNumbers == null ||
          selectedSerialNumbers.length != quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'item_selector.serial_required'
                        .tr(namedArgs: {'count': quantity.toString()}),
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      widget.formData.selectedItems[item.id] = SelectedOrderItem(
        id: item.id,
        name: item.nameEn.isNotEmpty
            ? item.nameEn
            : 'item_selector.unknown_item'.tr(),
        sku: item.sku.isNotEmpty ? item.sku : 'N/A',
        quantity: quantity,
        unitPrice: item.unitPrice ?? 0.0,
        totalPrice: (item.unitPrice ?? 0.0) * quantity,
        serialNumbers: selectedSerialNumbers,
      );
    });

    widget.onItemsChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedSerialNumbers != null
                    ? 'item_selector.added_with_serials'.tr(namedArgs: {
                  'name': item.nameEn,
                  'serials': selectedSerialNumbers.join(", ")
                })
                    : 'item_selector.added_to_order'
                    .tr(namedArgs: {'name': item.nameEn}),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
