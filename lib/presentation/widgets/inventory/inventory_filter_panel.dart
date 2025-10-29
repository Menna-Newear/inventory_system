// ✅ presentation/widgets/inventory/inventory_filter_panel.dart (FULLY THEME-AWARE)
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
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(theme, isDark),
        Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
        Expanded(
          child: BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, categoryState) {
              if (categoryState is CategoryLoading) {
                return _buildLoadingState(theme, isDark);
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickFilters(theme, isDark),
                    SizedBox(height: 20),
                    Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    SizedBox(height: 20),
                    _buildCategoryFilters(categoryState, theme, isDark),
                    SizedBox(height: 20),
                    Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    SizedBox(height: 20),
                    _buildPriceFilters(theme, isDark),
                    SizedBox(height: 20),
                    Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    SizedBox(height: 20),
                    _buildStockFilters(theme, isDark),
                  ],
                ),
              );
            },
          ),
        ),
        Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
        _buildActionButtons(theme, isDark),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Loading filter options...',
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we prepare your filters',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.8),
          ],
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

  Widget _buildQuickFilters(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: theme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Quick Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.blue[900]?.withOpacity(0.2) : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
            ),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Text('Low Stock Items',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                subtitle: Text('Show items below minimum stock level',
                    style: TextStyle(fontSize: 12)),
                value: _showLowStockOnly,
                onChanged: (value) => setState(() => _showLowStockOnly = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.purple[700], size: 20),
                    SizedBox(width: 8),
                    Text('Serial Tracked Only',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                subtitle: Text('Show only items with serial number tracking',
                    style: TextStyle(fontSize: 12)),
                value: _showSerialTrackedOnly,
                onChanged: (value) =>
                    setState(() => _showSerialTrackedOnly = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(CategoryState categoryState, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: theme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Category Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildCategoryDropdown(categoryState, theme, isDark),
        SizedBox(height: 12),
        _buildSubcategoryField(theme, isDark),
      ],
    );
  }

  Widget _buildCategoryDropdown(CategoryState categoryState, ThemeData theme, bool isDark) {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem<String>(
        value: null,
        child: Text('All Categories',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
      ),
    ];

    if (categoryState is CategoryLoaded) {
      items.addAll(
        categoryState.categories.map(
              (category) => DropdownMenuItem(
            value: category.id,
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 16, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(category.name, style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: categoryState is CategoryLoading
              ? Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : Icon(Icons.folder, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: isDark ? Colors.grey[850] : Colors.white,
        isExpanded: true,
        items: items,
        onChanged: categoryState is CategoryLoading
            ? null
            : (value) => setState(() => _selectedCategory = value),
      ),
    );
  }

  Widget _buildSubcategoryField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
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
        onChanged: (value) =>
            setState(() => _selectedSubcategory = value.isEmpty ? null : value),
      ),
    );
  }

  Widget _buildPriceFilters(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, color: theme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Price Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(
              controller: _minPriceController,
              label: 'Min Price',
              prefixText: '\$ ',
              icon: Icons.arrow_upward,
              iconColor: Colors.green,
              theme: theme,
              isDark: isDark,
              isDecimal: true,
            )),
            SizedBox(width: 12),
            Expanded(child: _buildTextField(
              controller: _maxPriceController,
              label: 'Max Price',
              prefixText: '\$ ',
              icon: Icons.arrow_downward,
              iconColor: Colors.red,
              theme: theme,
              isDark: isDark,
              isDecimal: true,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStockFilters(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, color: theme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Stock Quantity Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(
              controller: _minStockController,
              label: 'Min Stock',
              icon: Icons.minimize,
              iconColor: Colors.orange,
              theme: theme,
              isDark: isDark,
            )),
            SizedBox(width: 12),
            Expanded(child: _buildTextField(
              controller: _maxStockController,
              label: 'Max Stock',
              icon: Icons.add_box,
              iconColor: Colors.blue,
              theme: theme,
              isDark: isDark,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
    required bool isDark,
    bool isDecimal = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          prefixIcon: Icon(icon, size: 20, color: iconColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: isDecimal
            ? TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final bool isLoading = categoryState is CategoryLoading;

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            border: Border(
              top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _applyFilters,
                  icon: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(Icons.check),
                  label: Text(isLoading ? 'Loading...' : 'Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _clearFilters,
                  icon: Icon(Icons.clear_all),
                  label: Text('Clear All Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyLarge?.color,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_selectedCategory != null) filters['category_id'] = _selectedCategory;
    if (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty)
      filters['subcategory'] = _selectedSubcategory;
    if (_showLowStockOnly) filters['low_stock'] = true;
    if (_showSerialTrackedOnly) filters['serial_tracked'] = true;
    if (_minPriceController.text.isNotEmpty)
      filters['min_price'] = double.tryParse(_minPriceController.text);
    if (_maxPriceController.text.isNotEmpty)
      filters['max_price'] = double.tryParse(_maxPriceController.text);
    if (_minStockController.text.isNotEmpty)
      filters['min_stock'] = int.tryParse(_minStockController.text);
    if (_maxStockController.text.isNotEmpty)
      filters['max_stock'] = int.tryParse(_maxStockController.text);

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
