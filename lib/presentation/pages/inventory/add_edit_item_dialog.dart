// presentation/pages/inventory/add_edit_item_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../injection_container.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/dynamic_category_dropdown.dart';

class AddEditItemDialog extends StatefulWidget {
  final InventoryItem? item;

  const AddEditItemDialog({Key? key, this.item}) : super(key: key);

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers (same as before)
  late TextEditingController _skuController;
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _subcategoryController;
  late TextEditingController _stockController;
  late TextEditingController _priceController;
  late TextEditingController _minStockController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _depthController;
  late TextEditingController _pixelWidthController;
  late TextEditingController _pixelHeightController;
  late TextEditingController _dpiController;

  // Dropdown values
  String? _selectedCategoryId;
  String _selectedUnit = 'cm';
  String _selectedColorSpace = 'RGB';

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (isEditing) {
      _populateFields();
    }
  }

  void _initializeControllers() {
    _skuController = TextEditingController();
    _nameEnController = TextEditingController();
    _nameArController = TextEditingController();
    _subcategoryController = TextEditingController();
    _stockController = TextEditingController();
    _priceController = TextEditingController();
    _minStockController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _depthController = TextEditingController();
    _pixelWidthController = TextEditingController();
    _pixelHeightController = TextEditingController();
    _dpiController = TextEditingController(text: '300');
  }

  void _populateFields() {
    final item = widget.item!;
    _skuController.text = item.sku;
    _nameEnController.text = item.nameEn;
    _nameArController.text = item.nameAr;
    _selectedCategoryId = item.categoryId;
    _subcategoryController.text = item.subcategory;
    _stockController.text = item.stockQuantity.toString();
    _priceController.text = item.unitPrice.toString();
    _minStockController.text = item.minStockLevel.toString();

    // Dimensions
    _widthController.text = item.dimensions.width.toString();
    _heightController.text = item.dimensions.height.toString();
    _depthController.text = item.dimensions.depth.toString();
    _selectedUnit = item.dimensions.unit;

    // Image properties
    _pixelWidthController.text = item.imageProperties.pixelWidth.toString();
    _pixelHeightController.text = item.imageProperties.pixelHeight.toString();
    _dpiController.text = item.imageProperties.dpi.toString();
    _selectedColorSpace = item.imageProperties.colorSpace;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use MultiBlocListener to listen to both blocs
    return MultiBlocListener(
      listeners: [
        // Listen to InventoryBloc
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryItemCreated) {
              print('🟢 Item created successfully in UI');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Item "${state.item.nameEn}" created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is InventoryItemUpdated) {
              print('🟢 Item updated successfully in UI');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Item "${state.item.nameEn}" updated successfully!'),
                  backgroundColor: Colors.blue,
                ),
              );
              Navigator.pop(context);
            } else if (state is InventoryError) {
              print('🔴 Error in UI: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error: ${state.message}'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          },
        ),
        // Listen to CategoryBloc
        BlocListener<CategoryBloc, CategoryState>(
          listener: (context, state) {
            if (state is CategoryCreated) {
              print('🟢 Category created in dialog: ${state.category.name}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Category "${state.category.name}" added!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is CategoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Category Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Dialog(
        child: Container(
          width: 800,
          height: 700,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildBasicInfoSection(),
                    SizedBox(height: 24),
                    _buildInventorySection(),
                    SizedBox(height: 24),
                    _buildDimensionsSection(),
                    SizedBox(height: 24),
                    _buildImagePropertiesSection(),
                    SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _skuController,
                    label: 'SKU',
                    validator: Validators.required,
                    enabled: !isEditing,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2, // ✅ Give more space to dropdown
                  child: DynamicCategoryDropdown(
                    selectedCategoryId: _selectedCategoryId,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _nameEnController,
              label: 'Name (English)',
              validator: Validators.required,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _nameArController,
              label: 'Name (Arabic)',
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _subcategoryController,
              label: 'Subcategory',
              validator: Validators.required,
            ),
          ],
        ),
      ),
    );
  }

  // ... (rest of your widget methods remain the same)

  Widget _buildInventorySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _stockController,
                    label: 'Stock Quantity',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveInteger,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _minStockController,
                    label: 'Minimum Stock Level',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.nonNegativeInteger,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              label: 'Unit Price (\$)',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: Validators.positiveDouble,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Dimensions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _widthController,
                    label: 'Width',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.positiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _heightController,
                    label: 'Height',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.positiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _depthController,
                    label: 'Depth',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.positiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Unit',
                    value: _selectedUnit,
                    items: ['cm', 'inch', 'm', 'mm', 'px'],
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePropertiesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Properties',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _pixelWidthController,
                    label: 'Pixel Width',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveInteger,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _pixelHeightController,
                    label: 'Pixel Height',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveInteger,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _dpiController,
                    label: 'DPI',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveInteger,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Color Space',
                    value: _selectedColorSpace,
                    items: ['RGB', 'CMYK', 'Grayscale', 'LAB'],
                    onChanged: (value) {
                      setState(() {
                        _selectedColorSpace = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        final isLoading = state is InventoryLoading;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _saveItem,
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(isEditing ? 'Update Item' : 'Create Item'),
            ),
          ],
        );
      },
    );
  }

  void _saveItem() {
    print('🟡 Save item button pressed');

    if (_formKey.currentState!.validate()) {
      print('🟡 Form validation passed');

      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      try {
        final item = _createInventoryItem();
        print('🟡 Created inventory item: ${item.nameEn}');

        if (isEditing) {
          print('🟡 Updating existing item');
          context.read<InventoryBloc>().add(UpdateInventoryItem(item));
        } else {
          print('🟡 Creating new item');
          context.read<InventoryBloc>().add(CreateInventoryItem(item));
        }
      } catch (e) {
        print('🔴 Error creating inventory item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('🔴 Form validation failed');
    }
  }

  InventoryItem _createInventoryItem() {
    return InventoryItem(
      id: isEditing ? widget.item!.id : '', // Let Supabase generate UUID
      sku: _skuController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      nameAr: _nameArController.text.trim(),
      categoryId: _selectedCategoryId!,
      subcategory: _subcategoryController.text.trim(),
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      unitPrice: double.tryParse(_priceController.text) ?? 0.0,
      minStockLevel: int.tryParse(_minStockController.text) ?? 0,
      dimensions: ProductDimensions(
        width: double.tryParse(_widthController.text) ?? 0.0,
        height: double.tryParse(_heightController.text) ?? 0.0,
        depth: double.tryParse(_depthController.text) ?? 0.0,
        unit: _selectedUnit,
      ),
      imageProperties: ImageProperties(
        pixelWidth: int.tryParse(_pixelWidthController.text) ?? 1920,
        pixelHeight: int.tryParse(_pixelHeightController.text) ?? 1080,
        dpi: int.tryParse(_dpiController.text) ?? 300,
        colorSpace: _selectedColorSpace,
      ),
      createdAt: isEditing ? widget.item!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _subcategoryController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _pixelWidthController.dispose();
    _pixelHeightController.dispose();
    _dpiController.dispose();
    super.dispose();
  }
}
