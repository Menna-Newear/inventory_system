// presentation/widgets/inventory/inventory_filter_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../common/custom_dropdown.dart';
import '../common/custom_text_field.dart';

class InventoryFilterPanel extends StatefulWidget {
  final VoidCallback onClose;

  const InventoryFilterPanel({Key? key, required this.onClose}) : super(key: key);

  @override
  State<InventoryFilterPanel> createState() => _InventoryFilterPanelState();
}

class _InventoryFilterPanelState extends State<InventoryFilterPanel> {
  String? _selectedCategory;
  bool _showLowStockOnly = false;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt),
                SizedBox(width: 8),
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Category',
                    value: _selectedCategory,
                    items: _getCategoryOptions(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    title: Text('Low Stock Only'),
                    value: _showLowStockOnly,
                    onChanged: (value) {
                      setState(() {
                        _showLowStockOnly = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _minPriceController,
                    label: 'Min Price',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _maxPriceController,
                    label: 'Max Price',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: Text('Apply Filters'),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getCategoryOptions() {
    // TODO: Get from category BLoC
    return ['All', 'Electronics', 'Clothing', 'Books', 'Home & Garden', 'Sports'];
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_selectedCategory != null && _selectedCategory != 'All') {
      filters['category_id'] = _selectedCategory;
    }

    if (_showLowStockOnly) {
      filters['low_stock'] = true;
    }

    if (_minPriceController.text.isNotEmpty) {
      filters['min_price'] = double.tryParse(_minPriceController.text);
    }

    if (_maxPriceController.text.isNotEmpty) {
      filters['max_price'] = double.tryParse(_maxPriceController.text);
    }

    context.read<InventoryBloc>().add(FilterInventoryItems(filters));
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _showLowStockOnly = false;
      _minPriceController.clear();
      _maxPriceController.clear();
    });

    context.read<InventoryBloc>().add(ClearFilters());
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}
