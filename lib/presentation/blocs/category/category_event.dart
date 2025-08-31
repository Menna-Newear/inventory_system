// presentation/blocs/category/category_event.dart
part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object> get props => [];
}

class LoadCategories extends CategoryEvent {}

class RefreshCategories extends CategoryEvent {}

class CreateCategoryEvent extends CategoryEvent {
  final Category category;

  const CreateCategoryEvent(this.category);

  @override
  List<Object> get props => [category];
}

class DeleteCategoryEvent extends CategoryEvent {
  final String categoryId;

  const DeleteCategoryEvent(this.categoryId);

  @override
  List<Object> get props => [categoryId];
}
