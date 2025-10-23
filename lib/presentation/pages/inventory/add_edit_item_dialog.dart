// ✅ presentation/pages/inventory/add_edit_item_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/entities/inventory_item.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../blocs/serial/serial_number_bloc.dart';
import '../../blocs/serial/serial_number_event.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/dynamic_category_dropdown.dart';
import '../../../injection_container.dart';

class AddEditItemDialog extends StatefulWidget {
  final InventoryItem? item;

  const AddEditItemDialog({Key? key, this.item}) : super(key: key);

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();

  // Basic controllers
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
  late TextEditingController _otherSpController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _commentController;

  // ✅ Serial tracking options
  bool _isSerialTracked = false;
  bool _autoGenerateSerials = false; // ✅ NEW

  // Dropdown values
  String? _selectedCategoryId;
  String _selectedUnit = 'mm';
  String _selectedColorSpace = 'NA';
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (isEditing) _populateFields();
  }

  void _initializeControllers() {
    _skuController = TextEditingController();
    _nameEnController = TextEditingController();
    _nameArController = TextEditingController();
    _subcategoryController = TextEditingController();
    _stockController = TextEditingController();
    _descriptionEnController = TextEditingController();
    _descriptionArController = TextEditingController();
    _commentController = TextEditingController();
    _priceController = TextEditingController();
    _minStockController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _otherSpController = TextEditingController();
    _pixelWidthController = TextEditingController();
    _pixelHeightController = TextEditingController();
    _unitController = TextEditingController(text: 'mm');
    _depthController = TextEditingController();
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
    _descriptionEnController.text = item.descriptionEn ?? '';
    _descriptionArController.text = item.descriptionAr ?? '';
    _commentController.text = item.comment ?? '';
    _widthController.text = item.dimensions.width?.toString() ?? '';
    _heightController.text = item.dimensions.height?.toString() ?? '';
    _depthController.text = item.dimensions.depth ?? '';
    _unitController.text = item.dimensions.unit ?? 'cm';
    _pixelWidthController.text = item.imageProperties.pixelWidth?.toString() ?? '';
    _pixelHeightController.text = item.imageProperties.pixelHeight?.toString() ?? '';
    _otherSpController.text = item.imageProperties.otherSp ?? '';
    _selectedColorSpace = item.imageProperties.colorSpace;
    _isSerialTracked = item.isSerialTracked;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryItemCreated) {
              // ✅ Auto-generate serials after item creation
              if (_isSerialTracked && _autoGenerateSerials) {
                _generateSerialNumbers(state.item.id);
              } else {
                Navigator.pop(context);
              }
            } else if (state is InventoryItemUpdated) {
              Navigator.pop(context);
            } else if (state is InventoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<CategoryBloc, CategoryState>(
          listener: (context, state) {
            if (state is CategoryCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "${state.category.name}" added!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ],
      child: Dialog(
        child: Container(
          width: 900,
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
                    _buildImageSection(),
                    SizedBox(height: 20),
                    _buildBasicInfoSection(),
                    SizedBox(height: 20),
                    _buildInventorySection(),
                    SizedBox(height: 20),
                    _buildSerialTrackingSection(),
                    SizedBox(height: 20),
                    _buildDimensionsSection(),
                    SizedBox(height: 20),
                    _buildImagePropertiesSection(),
                    SizedBox(height: 24),
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
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  flex: 2,
                  child: DynamicCategoryDropdown(
                    selectedCategoryId: _selectedCategoryId,
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            CustomTextField(controller: _subcategoryController, label: 'Subcategory', validator: Validators.required),
            SizedBox(height: 16),
            CustomTextField(controller: _nameEnController, label: 'Name (English)', validator: Validators.required),
            SizedBox(height: 16),
            CustomTextField(controller: _nameArController, label: 'Name (Arabic)'),
            SizedBox(height: 16),
            CustomTextField(controller: _descriptionEnController, label: 'Description (English)', maxLines: 2),
            SizedBox(height: 16),
            CustomTextField(controller: _descriptionArController, label: 'Description (Arabic)', maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              validator: Validators.positiveDouble,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerialTrackingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text('Serial Number Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Enable Serial Number Tracking', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Track individual items with unique serial numbers'),
                    value: _isSerialTracked,
                    onChanged: (value) {
                      setState(() {
                        _isSerialTracked = value;
                        if (!value) _autoGenerateSerials = false; // Reset if disabled
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_isSerialTracked) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.purple[700], size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Serial Format: SKU-000001',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: Colors.purple[900],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Serial numbers will be auto-generated based on SKU',
                                      style: TextStyle(fontSize: 12, color: Colors.purple[800]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // ✅ NEW: Auto-generate option
                          if (!isEditing) ...[
                            SizedBox(height: 12),
                            CheckboxListTile(
                              value: _autoGenerateSerials,
                              onChanged: (value) => setState(() => _autoGenerateSerials = value ?? false),
                              title: Text(
                                'Auto-generate serial numbers on creation',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: Text(
                                'Generate ${_stockController.text.isEmpty ? "X" : _stockController.text} serial numbers automatically',
                                style: TextStyle(fontSize: 12),
                              ),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Dimensions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _widthController,
                    label: 'Width (Optional)',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.optionalPositiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _heightController,
                    label: 'Height (Optional)',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.optionalPositiveDouble,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(child: CustomTextField(controller: _depthController, label: 'Depth (Optional)')),
                SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Unit',
                    value: _getValidUnitValue(),
                    items: ['cm', 'inch', 'm', 'mm', 'l', 'na'],
                    onChanged: (value) => setState(() => _unitController.text = value ?? 'na'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            CustomTextField(controller: _commentController, label: 'Comment'),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePropertiesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _pixelWidthController,
                    label: 'Pixel Width (Optional)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.optionalPositiveInteger,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _pixelHeightController,
                    label: 'Pixel Height (Optional)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.optionalPositiveInteger,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: _otherSpController, label: 'Other Sp. (Optional)')),
                SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Color Space',
                    value: _getValidColorSpaceValue(),
                    items: ['RGB', 'CMYK', 'Grayscale', 'LAB', 'NA'],
                    onChanged: (value) => setState(() => _selectedColorSpace = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildImagePreview()),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(onPressed: _pickImage, icon: Icon(Icons.photo_library), label: Text('Choose Image')),
                      SizedBox(height: 8),
                      ElevatedButton.icon(onPressed: _takePhoto, icon: Icon(Icons.camera_alt), label: Text('Take Photo')),
                      if (_selectedImage != null || widget.item?.imageUrl != null) ...[
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _clearImage,
                          icon: Icon(Icons.clear, color: Colors.red),
                          label: Text('Remove Image', style: TextStyle(color: Colors.red)),
                        ),
                      ],
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

  Widget _buildImagePreview() {
    if (_selectedImage != null) return Image.file(_selectedImage!, fit: BoxFit.cover);
    if (widget.item?.imageUrl != null && widget.item!.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.item!.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 48, color: Colors.red),
      );
    }
    return Icon(Icons.image, size: 48, color: Colors.grey);
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
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Update Item' : 'Create Item'),
            ),
          ],
        );
      },
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category'), backgroundColor: Colors.red),
      );
      return;
    }

    final item = InventoryItem(
      id: isEditing ? widget.item!.id : '',
      sku: _skuController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      nameAr: _nameArController.text.trim(),
      descriptionEn: _descriptionEnController.text.trim().isEmpty ? null : _descriptionEnController.text.trim(),
      descriptionAr: _descriptionArController.text.trim().isEmpty ? null : _descriptionArController.text.trim(),
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      categoryId: _selectedCategoryId!,
      subcategory: _subcategoryController.text.trim(),
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      unitPrice: _priceController.text.isEmpty ? null : double.tryParse(_priceController.text),
      minStockLevel: int.tryParse(_minStockController.text) ?? 0,
      dimensions: ProductDimensions(
        width: double.tryParse(_widthController.text),
        height: double.tryParse(_heightController.text),
        depth: _depthController.text.trim().isEmpty ? null : _depthController.text.trim(),
        unit: _unitController.text.isEmpty ? null : _unitController.text,
      ),
      imageProperties: ImageProperties(
        pixelWidth: int.tryParse(_pixelWidthController.text),
        pixelHeight: int.tryParse(_pixelHeightController.text),
        otherSp: _otherSpController.text.trim().isEmpty ? null : _otherSpController.text.trim(),
        colorSpace: _selectedColorSpace,
      ),
      imageUrl: _selectedImage?.path,
      imageFileName: _selectedImage?.path.split('/').last,
      createdAt: isEditing ? widget.item!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      isSerialTracked: _isSerialTracked,
      serialNumberPrefix: _isSerialTracked ? _skuController.text.trim() : null,
      serialNumberLength: _isSerialTracked ? 6 : null,
      serialFormat: _isSerialTracked ? SerialNumberFormat.numeric : SerialNumberFormat.numeric,
      serialNumbers: isEditing ? widget.item!.serialNumbers : [],
    );

    if (isEditing) {
      context.read<InventoryBloc>().add(UpdateInventoryItem(item));
    } else {
      context.read<InventoryBloc>().add(CreateInventoryItem(item));
    }
  }

  // ✅ NEW: Generate serial numbers after item creation
  void _generateSerialNumbers(String itemId) {
    final quantity = int.tryParse(_stockController.text) ?? 0;
    if (quantity <= 0) {
      Navigator.pop(context);
      return;
    }

    final serials = List.generate(quantity, (i) {
      final serialNumber = i + 1;
      final formattedSerial = '${_skuController.text.trim()}-${serialNumber.toString().padLeft(6, '0')}';

      return SerialNumber(
        id: '',
        itemId: itemId,
        serialNumber: formattedSerial,
        status: SerialStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Use SerialNumberBloc to add serials
    final serialBloc = getIt<SerialNumberBloc>();
    serialBloc.add(AddSerialNumbers(itemId, serials));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Item created and $quantity serial numbers generated!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  String _getValidUnitValue() {
    const validUnits = ['cm', 'inch', 'm', 'mm', 'l', 'na'];
    final currentValue = _unitController.text.isEmpty ? 'na' : _unitController.text;
    return validUnits.contains(currentValue) ? currentValue : 'na';
  }

  String _getValidColorSpaceValue() {
    const validValues = ['RGB', 'CMYK', 'Grayscale', 'LAB', 'NA'];
    return validValues.contains(_selectedColorSpace) ? _selectedColorSpace : 'NA';
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  void _clearImage() => setState(() => _selectedImage = null);

  @override
  void dispose() {
    _skuController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    _commentController.dispose();
    _subcategoryController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    _minStockController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _otherSpController.dispose();
    _pixelWidthController.dispose();
    _pixelHeightController.dispose();
    _depthController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}
