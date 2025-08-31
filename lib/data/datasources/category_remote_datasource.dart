// data/datasources/category_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../../core/constants/supabase_constants.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel> createCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClient supabase;

  CategoryRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await supabase
          .from(SupabaseConstants.categoriesTable)
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((item) => CategoryModel.fromSupabase(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      print('🟡 Creating category with data: ${category.toSupabase()}');

      final response = await supabase
          .from(SupabaseConstants.categoriesTable)
          .insert(category.toSupabase()) // Don't include ID - Supabase will generate it
          .select()
          .single();

      print('🟢 Category created: $response');
      return CategoryModel.fromSupabase(response);
    } catch (e) {
      print('🔴 Error creating category: $e');
      throw Exception('Failed to create category: $e');
    }
  }
  @override
  Future<void> deleteCategory(String id) async {
    try {
      await supabase
          .from(SupabaseConstants.categoriesTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
