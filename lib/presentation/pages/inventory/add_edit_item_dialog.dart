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

  // ✅ EXISTING - Basic controllers
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

  // ✅ NEW - Serial number controllers
  late TextEditingController _serialPrefixController;
  late TextEditingController _serialLengthController;
  bool _isSerialTracked = false;
  SerialNumberFormat _serialFormat = SerialNumberFormat.numeric;

  // ✅ EXISTING - Dropdown values
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
    _unitController = TextEditingController(text: 'mm'); // Default unit
    _depthController = TextEditingController();

    // ✅ NEW - Serial number controllers
    _serialPrefixController = TextEditingController();
    _serialLengthController = TextEditingController();
  }

  void _populateFields() {
    final item = widget.item!;

    // ✅ EXISTING - Basic fields
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

    // Dimensions
    _widthController.text = item.dimensions.width?.toString() ?? '';
    _heightController.text = item.dimensions.height?.toString() ?? '';
    _depthController.text = item.dimensions.depth ?? '';
    _unitController.text = item.dimensions.unit ?? 'cm';

    // Image properties
    _pixelWidthController.text = item.imageProperties.pixelWidth?.toString() ?? '';
    _pixelHeightController.text = item.imageProperties.pixelHeight?.toString() ?? '';
    _otherSpController.text = item.imageProperties.otherSp ?? '';
    _selectedColorSpace = item.imageProperties.colorSpace;

    // ✅ NEW - Serial tracking fields
    _isSerialTracked = item.isSerialTracked;
    _serialPrefixController.text = item.serialNumberPrefix ?? '';
    _serialLengthController.text = item.serialNumberLength?.toString() ?? '';
    _serialFormat = item.serialFormat;
  }

  @override
  Widget build(BuildContext context) {
    // Use MultiBlocListener to listen to both blocs
    return MultiBlocListener(
      listeners: [
        // Listen to InventoryBloc
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryItemCreated) {
              print('✅ Item created successfully in UI...');
              Navigator.pop(context);
            } else if (state is InventoryItemUpdated) {
              print('✅ Item updated successfully in UI');
              Navigator.pop(context);
            } else if (state is InventoryError) {
              print('❌ Error in UI: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
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
              print('✅ Category created in dialog: ${state.category.name}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "${state.category.name}" added!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is CategoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category Error: ${state.message}'),
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
            body: Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildImageSection(),
                          SizedBox(height: 24),
                          _buildBasicInfoSection(),
                          SizedBox(height: 24),
                          _buildInventorySection(),
                          SizedBox(height: 24),
                          // ✅ NEW - Serial tracking section
                          _buildSerialTrackingSection(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ EXISTING SECTIONS (unchanged)
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
                  flex: 2, // Give more space to dropdown
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
              controller: _subcategoryController,
              label: 'Subcategory',
              validator: Validators.required,
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
              controller: _descriptionEnController,
              label: 'Description (English)',
              maxLines: 2,
            ),
            SizedBox(height: 16),
            CustomTextField(
              maxLines: 2,
              controller: _descriptionArController,
              label: 'Description (Arabic)',
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
                    label: _isSerialTracked ? 'Initial Stock Quantity' : 'Stock Quantity',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.positiveInteger,
                    helperText: _isSerialTracked
                        ? 'Will be managed via serial numbers'
                        : null,
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

  // ✅ NEW - Serial number tracking section
  Widget _buildSerialTrackingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Serial Number Tracking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // ✅ Enable Serial Tracking Switch
            SwitchListTile(
              title: Text('Enable Serial Number Tracking'),
              subtitle: Text('Track individual items with unique serial numbers'),
              value: _isSerialTracked,
              onChanged: (value) {
                setState(() {
                  _isSerialTracked = value;
                  if (!value) {
                    // Clear serial settings when disabled
                    _serialPrefixController.clear();
                    _serialLengthController.clear();
                    _serialFormat = SerialNumberFormat.numeric;
                  }
                });
              },
            ),

            // ✅ Serial Configuration (only show when enabled)
            if (_isSerialTracked) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),

              Text(
                'Serial Number Configuration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  // Serial Prefix
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _serialPrefixController,
                      label: 'Serial Prefix (Optional)',
                      placeholder: 'e.g., LAM, HK, AC',
                      validator: (value) {
                        if (value != null && value.length > 5) {
                          return 'Prefix too long (max 5 characters)';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),

                  // Serial Length
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      controller: _serialLengthController,
                      label: 'Total Length',
                      placeholder: '6-12',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final length = int.tryParse(value);
                          if (length == null || length < 4 || length > 20) {
                            return 'Length must be 4-20';
                          }
                          // Check if length is greater than prefix
                          final prefix = _serialPrefixController.text.trim();
                          if (prefix.isNotEmpty && length <= prefix.length) {
                            return 'Must be > prefix (${prefix.length})';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),

                  // Serial Format
                  Expanded(
                    flex: 2,
                    child: CustomDropdown<SerialNumberFormat>(
                      label: 'Format',
                      value: _serialFormat,
                      items: SerialNumberFormat.values,
                      itemBuilder: (format) => Text(format.displayName),
                      onChanged: (value) {
                        setState(() => _serialFormat = value ?? SerialNumberFormat.numeric);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // ✅ Preview
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.preview, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Preview: ${_generatePreviewSerial()}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Spacer(),
                    Text(
                      _serialFormat.displayName,
                      style: TextStyle(color: Colors.blue[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // ✅ Information box
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Serial numbers will be generated automatically or can be added manually after item creation.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ EXISTING SECTIONS (unchanged)
  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildSmartImagePreview(), // Use smart preview
                  ),
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

  Widget _buildSmartImagePreview() {
    // Priority 1: Show selected local image
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image: $error');
          return Icon(Icons.broken_image, size: 48, color: Colors.red);
        },
      );
    }

    // Priority 2: Show existing image from database
    if (widget.item?.imageUrl != null && widget.item!.imageUrl!.isNotEmpty) {
      final imageUrl = widget.item!.imageUrl!;

      // Check if it's a network URL (starts with http/https)
      if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 32, color: Colors.red),
                Text('Failed to load', style: TextStyle(fontSize: 10)),
              ],
            );
          },
        );
      } else {
        // It's a local file path - try to load as file
        print('Warning: Found local path in database: $imageUrl');
        final file = File(imageUrl);
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data == true) {
              return Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading file: $error');
                  return Icon(Icons.broken_image, size: 48, color: Colors.red);
                },
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 32, color: Colors.orange),
                  Text('File not found', style: TextStyle(fontSize: 10)),
                ],
              );
            }
          },
        );
      }
    }

    // Priority 3: Show placeholder
    return Icon(Icons.image, size: 48, color: Colors.grey);
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
                Expanded(
                  child: CustomTextField(
                    controller: _depthController,
                    label: 'Depth (Optional)',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Unit',
                    value: _getValidUnitValue(), // ✅ Use helper method to ensure valid value
                    items: ['cm', 'inch', 'm', 'mm', 'l', 'na'].toSet().toList(), // ✅ Remove duplicates
                    onChanged: (value) {
                      setState(() {
                        _unitController.text = value ?? 'na';
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _commentController,
              label: 'Comment',
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
                Expanded(
                  child: CustomTextField(
                    controller: _otherSpController,
                    label: 'Other Sp. (Optional)',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Color Space',
                    value: _getValidColorSpaceValue(),
                    items: ['RGB', 'CMYK', 'Grayscale', 'LAB', 'NA'].toSet().toList(), // ✅ Remove duplicates
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

  String _getValidColorSpaceValue() {
    const validValues = ['RGB', 'CMYK', 'Grayscale', 'LAB', 'NA'];
    // If current value is valid, use it
    if (validValues.contains(_selectedColorSpace)) {
      return _selectedColorSpace;
    }
    // Otherwise, return default
    return 'NA';
  }
  // Add this method to your _AddEditItemDialogState class:
  String _getValidUnitValue() {
    const validUnits = ['cm', 'inch', 'm', 'mm', 'l', 'na'];

    final currentValue = _unitController.text.isEmpty ? 'na' : _unitController.text;

    // If current value is valid, use it
    if (validUnits.contains(currentValue)) {
      return currentValue;
    }

    // Otherwise, return default
    return 'na';
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

  // ✅ NEW - Helper method to generate preview serial
  String _generatePreviewSerial() {
    final prefix = _serialPrefixController.text.trim();
    final length = int.tryParse(_serialLengthController.text.trim()) ?? 8;

    switch (_serialFormat) {
      case SerialNumberFormat.numeric:
        final numberLength = (length - prefix.length).clamp(1, 15);
        return '$prefix${'001'.padLeft(numberLength, '0')}';
      case SerialNumberFormat.alphanumeric:
        return '${prefix}ABC001';
      case SerialNumberFormat.custom:
        return '${prefix}CUSTOM';
    }
  }

  // ✅ EXISTING - Image handling methods (unchanged)
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

  void _clearImage() async {
    print('🗑️ Clear image button pressed...');

    // Show confirmation dialog for existing images
    if (isEditing && widget.item?.imageUrl != null && widget.item!.imageUrl!.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove Image'),
          content: Text('Are you sure you want to remove this image? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return; // User cancelled
    }

    // Clear local selected image
    setState(() {
      _selectedImage = null;
    });

    // If editing existing item, update database to clear image fields
    if (isEditing) {
      try {
        print('📝 Updating item to remove image from database...');
        // Create updated item with image fields cleared
        final updatedItem = _createInventoryItemWithClearedImage();

        // Dispatch update event to clear image in database
        context.read<InventoryBloc>().add(UpdateInventoryItem(updatedItem));
        print('✅ Image removal update dispatched...');

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('❌ Failed to remove image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove image: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // For new items, just show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image removed'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  InventoryItem _createInventoryItemWithClearedImage() {
    return InventoryItem(
      id: widget.item!.id,
      sku: _skuController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      nameAr: _nameArController.text.trim(),
      descriptionEn: _descriptionEnController.text.trim().isEmpty
          ? null
          : _descriptionEnController.text.trim(),
      descriptionAr: _descriptionArController.text.trim().isEmpty
          ? null
          : _descriptionArController.text.trim(),
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      categoryId: _selectedCategoryId!,
      subcategory: _subcategoryController.text.trim(),
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      unitPrice: _priceController.text.isEmpty
          ? null
          : double.tryParse(_priceController.text),
      minStockLevel: int.tryParse(_minStockController.text) ?? 0,
      dimensions: ProductDimensions(
        width: _widthController.text.trim().isEmpty
            ? null
            : double.tryParse(_widthController.text),
        height: _heightController.text.trim().isEmpty
            ? null
            : double.tryParse(_heightController.text),
        depth: _depthController.text.trim().isEmpty
            ? null
            : _depthController.text.trim(),
        unit: _unitController.text.isEmpty ? null : _unitController.text,
      ),
      imageProperties: ImageProperties(
        pixelWidth: _pixelWidthController.text.trim().isEmpty
            ? null
            : int.tryParse(_pixelWidthController.text),
        pixelHeight: _pixelHeightController.text.trim().isEmpty
            ? null
            : int.tryParse(_pixelHeightController.text),
        otherSp: _otherSpController.text.trim().isEmpty
            ? null
            : _otherSpController.text.trim(),
        colorSpace: _selectedColorSpace,
      ),
      imageUrl: null, // ✅ Clear image URL
      imageFileName: null, // ✅ Clear image filename
      createdAt: widget.item!.createdAt,
      updatedAt: DateTime.now(),
      // ✅ NEW - Serial tracking fields
      isSerialTracked: _isSerialTracked,
      serialNumberPrefix: _serialPrefixController.text.trim().isEmpty
          ? null
          : _serialPrefixController.text.trim(),
      serialNumberLength: _serialLengthController.text.trim().isEmpty
          ? null
          : int.tryParse(_serialLengthController.text),
      serialFormat: _serialFormat,
      serialNumbers: widget.item!.serialNumbers, // Preserve existing serials
    );
  }

  void _saveItem() {
    print('💾 Save item button pressed');
    if (_formKey.currentState!.validate()) {
      print('✅ Form validation passed');

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
        print('📦 Created inventory item: ${item.nameEn}');

        if (isEditing) {
          print('📝 Updating existing item');
          context.read<InventoryBloc>().add(UpdateInventoryItem(item));
        } else {
          print('➕ Creating new item');
          context.read<InventoryBloc>().add(CreateInventoryItem(item));
        }
      } catch (e) {
        print('❌ Error creating inventory item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('❌ Form validation failed');
    }
  }

  // ✅ ENHANCED - Create inventory item with serial tracking
  InventoryItem _createInventoryItem() {
    return InventoryItem(
      id: isEditing ? widget.item!.id : '', // Let Supabase generate UUID
      sku: _skuController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      nameAr: _nameArController.text.trim(),
      descriptionEn: _descriptionEnController.text.trim().isEmpty
          ? null
          : _descriptionEnController.text.trim(),
      descriptionAr: _descriptionArController.text.trim().isEmpty
          ? null
          : _descriptionArController.text.trim(),
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      categoryId: _selectedCategoryId!,
      subcategory: _subcategoryController.text.trim(),
      stockQuantity: int.tryParse(_stockController.text) ?? 0,
      unitPrice: _priceController.text.isEmpty
          ? null
          : double.tryParse(_priceController.text),
      minStockLevel: int.tryParse(_minStockController.text) ?? 0,
      dimensions: ProductDimensions(
        width: double.tryParse(_widthController.text),
        height: double.tryParse(_heightController.text),
        depth: _depthController.text.trim().isEmpty
            ? null
            : _depthController.text.trim(),
        unit: _unitController.text.isEmpty ? null : _unitController.text,
      ),
      imageProperties: ImageProperties(
        pixelWidth: int.tryParse(_pixelWidthController.text),
        pixelHeight: int.tryParse(_pixelHeightController.text),
        otherSp: _otherSpController.text.trim().isEmpty
            ? null
            : _otherSpController.text.trim(),
        colorSpace: _selectedColorSpace,
      ),
      imageUrl: _selectedImage?.path,
      imageFileName: _selectedImage?.path.split('/').last,
      createdAt: isEditing ? widget.item!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      // ✅ NEW - Serial tracking fields
      isSerialTracked: _isSerialTracked,
      serialNumberPrefix: _serialPrefixController.text.trim().isEmpty
          ? null
          : _serialPrefixController.text.trim(),
      serialNumberLength: _serialLengthController.text.trim().isEmpty
          ? null
          : int.tryParse(_serialLengthController.text),
      serialFormat: _serialFormat,
      serialNumbers: isEditing ? widget.item!.serialNumbers : [], // Preserve existing or empty for new
    );
  }

  @override
  void dispose() {
    // ✅ EXISTING - Basic controllers
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

    // ✅ NEW - Serial number controllers
    _serialPrefixController.dispose();
    _serialLengthController.dispose();

    super.dispose();
  }
}
