// data/models/category_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/category.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel {
  final String id;
  final String name;
  @JsonKey(name: 'parent_id')
  final String? parentId;
  final String? description;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  // Convert to domain entity
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      parentId: parentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Create from domain entity
  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      parentId: entity.parentId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Convert from Supabase response
  factory CategoryModel.fromSupabase(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'],
      name: data['name'],
      parentId: data['parent_id'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
