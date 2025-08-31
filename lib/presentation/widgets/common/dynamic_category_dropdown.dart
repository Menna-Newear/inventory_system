// presentation/widgets/common/dynamic_category_dropdown.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../../domain/entities/category.dart';

class DynamicCategoryDropdown extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;
  final String? label;

  const DynamicCategoryDropdown({
    Key? key,
    this.selectedCategoryId,
    required this.onChanged,
    this.label = 'Category',
  }) : super(key: key);

  // ✅ Safe value validator to prevent "_add_new" as selected value
  String? _getSafeSelectedValue(String? currentValue, List<Category> categories) {
    // Never allow "_add_new" as the selected value
    if (currentValue == null || currentValue == '_add_new') {
      return null;
    }

    // Only return the value if it exists in the categories list
    final exists = categories.any((category) => category.id == currentValue);
    return exists ? currentValue : null;
  }

  InputDecoration _getConsistentDecoration(BuildContext context) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[600]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void showAddCategoryDialog() {
      final nameController = TextEditingController();

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Add New Category'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final category = Category(
                    id: '',
                    name: nameController.text.trim(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  context.read<CategoryBloc>().add(CreateCategoryEvent(category));
                  Navigator.pop(dialogContext);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      );
    }

    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryCreated) {
          print('🟢 UI received category created: ${state.category.name}');
          // ✅ Use post-frame callback to ensure proper timing
          SchedulerBinding.instance.addPostFrameCallback((_) {
            onChanged(state.category.id);
          });
        }
      },
      builder: (context, state) {
        if (state is CategoryLoading) {
          return _buildLoadingDropdown(context);
        }

        if (state is CategoryLoaded) {
          print('🔄 UI rebuilding with ${state.categories.length} categories');
          return _buildCategoryDropdown(context, state.categories, showAddCategoryDialog);
        }

        if (state is CategoryError) {
          return _buildErrorDropdown(context, state.message);
        }

        return _buildEmptyDropdown(context);
      },
    );
  }

  Widget _buildCategoryDropdown(
      BuildContext context,
      List<Category> categories,
      VoidCallback showAddDialog,
      ) {
    // ✅ CRITICAL FIX: Get safe selected value that excludes "_add_new"
    final safeSelectedValue = _getSafeSelectedValue(selectedCategoryId, categories);

    print('🔍 Debug Info:');
    print('   - selectedCategoryId: $selectedCategoryId');
    print('   - safeSelectedValue: $safeSelectedValue');
    print('   - categories count: ${categories.length}');
    print('   - category IDs: ${categories.map((c) => c.id).toList()}');

    // ✅ Build items list ensuring no duplicates
    final items = <DropdownMenuItem<String>>[
      // Null option for "Select Category"
      DropdownMenuItem<String>(
        value: null,
        child: Text(
          'Select Category',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
      // Category options
      ...categories
          .where((category) => category.id != null && category.id.isNotEmpty)
          .map((category) => DropdownMenuItem<String>(
        value: category.id,
        child: Text(
          category.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: Colors.white70),
        ),
      )),
      // Add new option (exactly one instance)
      DropdownMenuItem<String>(
        value: '_add_new',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add New Category',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ];

    return DropdownButtonFormField<String>(
      // ✅ Force widget rebuild when categories list changes
      key: ValueKey('category_dropdown_${categories.length}_${safeSelectedValue ?? 'null'}'),
      value: safeSelectedValue, // ✅ Use safe validated value
      decoration: _getConsistentDecoration(context),
      style: TextStyle(color: Colors.white70, fontSize: 16),
      dropdownColor: Colors.grey[850],
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: 24),
      isExpanded: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
      items: items,
      onChanged: (value) {
        print('🔄 Dropdown value changed: $value');
        if (value == '_add_new') {
          // ✅ CRITICAL: Don't call onChanged with "_add_new"
          // Just show the dialog, don't change the selected value
          showAddDialog();
        } else {
          // ✅ Only call onChanged for actual category IDs or null
          onChanged(value);
        }
      },
    );
  }

  Widget _buildLoadingDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: _getConsistentDecoration(context),
      style: TextStyle(color: Colors.white70, fontSize: 16),
      dropdownColor: Colors.grey[850],
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: 24),
      isExpanded: true,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  )
              ),
              SizedBox(width: 10),
              Text('Loading categories...', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        )
      ],
      onChanged: null,
    );
  }

  Widget _buildErrorDropdown(BuildContext context, String message) {
    return DropdownButtonFormField<String>(
      decoration: _getConsistentDecoration(context).copyWith(
        errorText: 'Failed to load categories',
      ),
      style: TextStyle(color: Colors.white70, fontSize: 16),
      dropdownColor: Colors.grey[850],
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: 24),
      isExpanded: true,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error: $message',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),
            ],
          ),
        )
      ],
      onChanged: null,
    );
  }

  Widget _buildEmptyDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: _getConsistentDecoration(context),
      style: TextStyle(color: Colors.white70, fontSize: 16),
      dropdownColor: Colors.grey[850],
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: 24),
      isExpanded: true,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('No categories available', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        )
      ],
      onChanged: null,
    );
  }
}
