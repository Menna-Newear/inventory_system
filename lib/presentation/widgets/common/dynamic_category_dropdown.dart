// presentation/widgets/common/dynamic_category_dropdown.dart (FULLY LOCALIZED!)
import 'package:easy_localization/easy_localization.dart';
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
    this.label,
  }) : super(key: key);

  // ✅ Safe value validator to prevent "_add_new" as selected value
  String? _getSafeSelectedValue(String? currentValue, List<Category> categories) {
    if (currentValue == null || currentValue == '_add_new') {
      return null;
    }

    final exists = categories.any((category) => category.id == currentValue);
    return exists ? currentValue : null;
  }

  InputDecoration _getConsistentDecoration(BuildContext context) {
    return InputDecoration(
      labelText: label ?? 'category_dropdown.label'.tr(),
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
          title: Text('category_dropdown.add_category_title'.tr()),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'category_dropdown.category_name'.tr(),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('category_dropdown.cancel'.tr()),
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
              child: Text('category_dropdown.add'.tr()),
            ),
          ],
        ),
      );
    }

    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryCreated) {
          print('🟢 UI received category created: ${state.category.name}');
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
    final safeSelectedValue = _getSafeSelectedValue(selectedCategoryId, categories);

    print('🔍 Debug Info:');
    print('   - selectedCategoryId: $selectedCategoryId');
    print('   - safeSelectedValue: $safeSelectedValue');
    print('   - categories count: ${categories.length}');
    print('   - category IDs: ${categories.map((c) => c.id).toList()}');

    final items = <DropdownMenuItem<String>>[
      // Null option for "Select Category"
      DropdownMenuItem<String>(
        value: null,
        child: Text(
          'category_dropdown.select_category'.tr(),
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
      // Category options
      ...categories
          .where((category) => category.id.isNotEmpty)
          .map((category) => DropdownMenuItem<String>(
        value: category.id,
        child: Text(
          category.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(color: Colors.white70),
        ),
      )),
      // Add new option
      DropdownMenuItem<String>(
        value: '_add_new',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'category_dropdown.add_new_category'.tr(),
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ];

    return DropdownButtonFormField<String>(
      key: ValueKey('category_dropdown_${categories.length}_${safeSelectedValue ?? 'null'}'),
      value: safeSelectedValue,
      decoration: _getConsistentDecoration(context),
      style: TextStyle(color: Colors.white70, fontSize: 16),
      dropdownColor: Colors.grey[850],
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: 24),
      isExpanded: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'category_dropdown.validation_required'.tr();
        }
        return null;
      },
      items: items,
      onChanged: (value) {
        print('🔄 Dropdown value changed: $value');
        if (value == '_add_new') {
          showAddDialog();
        } else {
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
                ),
              ),
              SizedBox(width: 10),
              Text(
                'category_dropdown.loading_categories'.tr(),
                style: TextStyle(color: Colors.grey[500]),
              ),
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
        errorText: 'category_dropdown.failed_to_load'.tr(),
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
                  message,
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
              Text(
                'category_dropdown.no_categories'.tr(),
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        )
      ],
      onChanged: null,
    );
  }
}
