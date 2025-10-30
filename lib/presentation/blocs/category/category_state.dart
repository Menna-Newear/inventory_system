// presentation/blocs/category/category_state.dart
part of 'category_bloc.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;

  const CategoryLoaded(this.categories);

  @override
  List<Object> get props => [categories];

  CategoryLoaded copyWith({List<Category>? categories}) {
    return CategoryLoaded(categories ?? this.categories);
  }
}

class CategoryError extends CategoryState {
  final String message;

  const CategoryError(this.message);

  @override
  List<Object> get props => [message];
}

class CategoryCreated extends CategoryState {
  final Category category;

  const CategoryCreated(this.category);

  @override
  List<Object> get props => [category];
}

class CategoryDeleted extends CategoryState {}
