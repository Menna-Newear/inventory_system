// presentation/pages/inventory/add_edit_item_dialog.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/entities/inventory_item.dart';
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
  late TextEditingController _unitController;
  late TextEditingController _pixelWidthController;
  late TextEditingController _pixelHeightController;
  late TextEditingController _dpiController;

  // Dropdown values
  String? _selectedCategoryId;
  String _selectedUnit = 'cm';
  String _selectedColorSpace = 'RGB';
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

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
    _unitController = TextEditingController(text: 'cm'); // Default unit
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
    _priceController.text = item.unitPrice?.toString() ?? '';
    _minStockController.text = item.minStockLevel.toString();

    // Dimensions
    _widthController.text = item.dimensions.width.toString();
    _heightController.text = item.dimensions.height.toString();
    _depthController.text = item.dimensions.depth?.toString() ?? '';
    _unitController.text = item.dimensions.unit ?? 'cm';

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
                  content: Text(
                    '✅ Item "${state.item.nameEn}" created successfully!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is InventoryItemUpdated) {
              print('🟢 Item updated successfully in UI');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Item "${state.item.nameEn}" updated successfully!',
                  ),
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
          width: 900,
          height: 750,
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
                    _buildImageSection(),
                    SizedBox(height: 24),
                    _buildInventorySection(),
                    SizedBox(height: 24),
                    _buildEnhancedDimensionsSection(),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Image',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                // Image preview
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : (widget.item?.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.item!.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(Icons.image, size: 48, color: Colors.grey)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.photo_library),
                        label: Text('Choose Image'),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Take Photo'),
                      ),
                      SizedBox(height: 8),
                      if (_selectedImage != null ||
                          widget.item?.imageUrl != null)
                        TextButton.icon(
                          onPressed: _clearImage,
                          icon: Icon(Icons.clear, color: Colors.red),
                          label: Text(
                            'Remove Image',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDimensionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Dimensions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _widthController,
                    label: 'Width *',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.positiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _heightController,
                    label: 'Height *',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.positiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _depthController,
                    label: 'Depth (Optional)',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        return Validators.positiveDouble(value);
                      }
                      return null; // Optional field
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Unit',
                    value: _unitController.text.isEmpty
                        ? 'cm'
                        : _unitController.text,
                    items: ['cm', 'inch', 'm', 'mm', 'px'],
                    onChanged: (value) {
                      setState(() {
                        _unitController.text = value ?? 'cm';
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

  Widget _buildInventorySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              label: 'Unit Price (Optional)',
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _widthController,
                    label: 'Width',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.positiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _heightController,
                    label: 'Height',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.positiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _depthController,
                    label: 'Depth',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  // Image handling methods
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
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
      id: isEditing ? widget.item!.id : '',
      // Let Supabase generate UUID
      sku: _skuController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      nameAr: _nameArController.text.trim(),
      categoryId: _selectedCategoryId!,
      subcategory: _subcategoryController.text.trim(),
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      unitPrice: _priceController.text.isEmpty
          ? null
          : double.tryParse(_priceController.text),
      minStockLevel: int.tryParse(_minStockController.text) ?? 0,
      dimensions: ProductDimensions(
        width: double.tryParse(_widthController.text) ?? 0.0,
        height: double.tryParse(_heightController.text) ?? 0.0,
        depth: _depthController.text.isEmpty
            ? null
            : double.tryParse(_depthController.text),
        unit: _unitController.text.isEmpty ? null : _unitController.text,
      ),
      imageProperties: ImageProperties(
        pixelWidth: int.tryParse(_pixelWidthController.text) ?? 1920,
        pixelHeight: int.tryParse(_pixelHeightController.text) ?? 1080,
        dpi: int.tryParse(_dpiController.text) ?? 300,
        colorSpace: _selectedColorSpace,
      ),
      imageUrl: _selectedImage?.path, // Will be uploaded to Supabase
      imageFileName: _selectedImage?.path.split('/').last,
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
