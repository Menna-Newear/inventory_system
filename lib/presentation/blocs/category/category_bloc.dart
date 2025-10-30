// presentation/blocs/category/category_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/category.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_categories.dart' as get_categories_usecase;
import '../../../domain/usecases/create_category.dart' as create_category_usecase;
import '../../../domain/usecases/delete_category.dart' as delete_category_usecase;

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final get_categories_usecase.GetCategories getCategories;
  final create_category_usecase.CreateCategory createCategory;
  final delete_category_usecase.DeleteCategory deleteCategory;

  CategoryBloc({
    required this.getCategories,
    required this.createCategory,
    required this.deleteCategory,
  }) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
    on<RefreshCategories>(_onRefreshCategories);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event,
      Emitter<CategoryState> emit,
      ) async {
    print('🟡 Loading categories from database...');
    emit(CategoryLoading());

    final result = await getCategories(NoParams());

    result.fold(
          (failure) {
        print('🔴 Failed to load categories: ${failure.message}');
        emit(CategoryError(failure.message));
      },
          (categories) {
        print('🟢 Loaded ${categories.length} categories from database');
        emit(CategoryLoaded(categories));
      },
    );
  }

  Future<void> _onCreateCategory(
      CreateCategoryEvent event,
      Emitter<CategoryState> emit,
      ) async {
    print('🟡 Creating new category: ${event.category.name}');

    final result = await createCategory(
      create_category_usecase.CreateCategoryParams(event.category),
    );

    result.fold(
          (failure) {
        print('🔴 Failed to create category: ${failure.message}');
        emit(CategoryError(failure.message));
      },
          (category) {
        print('🟢 Category created successfully: ${category.name}');
        emit(CategoryCreated(category));
        add(LoadCategories());
      },
    );
  }

  Future<void> _onDeleteCategory(
      DeleteCategoryEvent event,
      Emitter<CategoryState> emit,
      ) async {
    print('🟡 Deleting category: ${event.categoryId}');

    final result = await deleteCategory(
      delete_category_usecase.DeleteCategoryParams(event.categoryId),
    );

    result.fold(
          (failure) {
        print('🔴 Failed to delete category: ${failure.message}');
        emit(CategoryError(failure.message));
      },
          (_) {
        print('🟢 Category deleted successfully');
        emit(CategoryDeleted());
        add(LoadCategories());
      },
    );
  }

  Future<void> _onRefreshCategories(
      RefreshCategories event,
      Emitter<CategoryState> emit,
      ) async {
    final result = await getCategories(NoParams());

    result.fold(
          (failure) => emit(CategoryError(failure.message)),
          (categories) {
        print('🔄 Categories refreshed: ${categories.length} items');
        emit(CategoryLoaded(categories));
      },
    );
  }
}
