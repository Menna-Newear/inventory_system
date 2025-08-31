// domain/entities/category.dart
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? parentId; // For hierarchical category
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, parentId, createdAt, updatedAt];
}
