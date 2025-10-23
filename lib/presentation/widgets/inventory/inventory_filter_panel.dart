// ✅ presentation/widgets/inventory/inventory_filter_panel.dart (ENHANCED)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/category/category_bloc.dart';

class InventoryFilterPanel extends StatefulWidget {
  final VoidCallback onClose;

  const InventoryFilterPanel({Key? key, required this.onClose}) : super(key: key);

  @override
  State<InventoryFilterPanel> createState() => _InventoryFilterPanelState();
}

class _InventoryFilterPanelState extends State<InventoryFilterPanel> {
  String? _selectedCategory;
  String? _selectedSubcategory;
  bool _showLowStockOnly = false;
  bool _showSerialTrackedOnly = false;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _maxStockController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Divider(height: 1, thickness: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickFilters(),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),
                _buildCategoryFilters(),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),
                _buildPriceFilters(),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 20),
                _buildStockFilters(),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.filter_alt, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Inventory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Refine your search',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: widget.onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Quick Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Text('Low Stock Items', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                subtitle: Text('Show items below minimum stock level', style: TextStyle(fontSize: 12)),
                value: _showLowStockOnly,
                onChanged: (value) => setState(() => _showLowStockOnly = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.purple[700], size: 20),
                    SizedBox(width: 8),
                    Text('Serial Tracked Only', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                subtitle: Text('Show only items with serial number tracking', style: TextStyle(fontSize: 12)),
                value: _showSerialTrackedOnly,
                onChanged: (value) => setState(() => _showSerialTrackedOnly = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Category Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            List<DropdownMenuItem<String>> items = [
              DropdownMenuItem<String>(
                value: null,
                child: Text('All Categories', style: TextStyle(color: Colors.grey[600])),
              ),
            ];

            // ✅ Use CategoryLoaded (your actual state name)
            if (state is CategoryLoaded) {
              items.addAll(
                state.categories.map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name, style: TextStyle(fontSize: 14)),
                )),
              );
            }

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.folder, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    isExpanded: true,
                    items: items,
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Subcategory',
                      prefixIcon: Icon(Icons.subdirectory_arrow_right, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Enter subcategory...',
                      hintStyle: TextStyle(fontSize: 13),
                    ),
                    onChanged: (value) => setState(() => _selectedSubcategory = value.isEmpty ? null : value),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Price Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _minPriceController,
                  decoration: InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.arrow_upward, size: 20, color: Colors.green),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _maxPriceController,
                  decoration: InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.arrow_downward, size: 20, color: Colors.red),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Stock Quantity Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _minStockController,
                  decoration: InputDecoration(
                    labelText: 'Min Stock',
                    prefixIcon: Icon(Icons.minimize, size: 20, color: Colors.orange),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _maxStockController,
                  decoration: InputDecoration(
                    labelText: 'Max Stock',
                    prefixIcon: Icon(Icons.add_box, size: 20, color: Colors.blue),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: Icon(Icons.check),
              label: Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.clear_all),
              label: Text('Clear All Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_selectedCategory != null) {
      filters['category_id'] = _selectedCategory;
    }

    if (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty) {
      filters['subcategory'] = _selectedSubcategory;
    }

    if (_showLowStockOnly) {
      filters['low_stock'] = true;
    }

    if (_showSerialTrackedOnly) {
      filters['serial_tracked'] = true;
    }

    if (_minPriceController.text.isNotEmpty) {
      filters['min_price'] = double.tryParse(_minPriceController.text);
    }

    if (_maxPriceController.text.isNotEmpty) {
      filters['max_price'] = double.tryParse(_maxPriceController.text);
    }

    if (_minStockController.text.isNotEmpty) {
      filters['min_stock'] = int.tryParse(_minStockController.text);
    }

    if (_maxStockController.text.isNotEmpty) {
      filters['max_stock'] = int.tryParse(_maxStockController.text);
    }

    context.read<InventoryBloc>().add(FilterInventoryItems(filters));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Filters applied successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSubcategory = null;
      _showLowStockOnly = false;
      _showSerialTrackedOnly = false;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minStockController.clear();
      _maxStockController.clear();
    });

    context.read<InventoryBloc>().add(ClearFilters());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('All filters cleared'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    super.dispose();
  }
}
