// presentation/widgets/category/simple_category_manager.dart (COMPLETE!)
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_system/injection_container.dart';

import '../../../domain/entities/category.dart';
import '../../blocs/category/category_bloc.dart';

class SimpleCategoryManager extends StatelessWidget {
  const SimpleCategoryManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoryBloc>()..add(LoadCategories()),
      child: Dialog(
        child: Container(
          width: 400,
          height: 500,
          child: Scaffold(
            appBar: AppBar(
              title: Text('category_manager.title'.tr()),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: BlocConsumer<CategoryBloc, CategoryState>(
              listener: (context, state) {
                if (state is CategoryDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('category_manager.deleted_success'.tr()),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (state is CategoryError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('category_manager.delete_failed'.tr()),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (state is CategoryLoaded) {
                  if (state.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No categories available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.category,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, category),
                          tooltip: 'Delete category',
                        ),
                      );
                    },
                  );
                }

                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('category_manager.delete_title'.tr()),
          ],
        ),
        content: Text(
          'category_manager.delete_confirm'.tr(namedArgs: {'name': category.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('category_manager.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryBloc>().add(DeleteCategoryEvent(category.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'category_manager.delete'.tr(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
