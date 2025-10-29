// ✅ data/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String name,
    required UserRole role,
    required List<Permission> permissions,
    bool isActive = true,
    required DateTime createdAt,
    DateTime? lastLogin,
    String? avatarUrl,
  }) : super(
    id: id,
    email: email,
    name: name,
    role: role,
    permissions: permissions,
    isActive: isActive,
    createdAt: createdAt,
    lastLogin: lastLogin,
    avatarUrl: avatarUrl,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Convert from entity to model
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      permissions: user.permissions,
      isActive: user.isActive,
      createdAt: user.createdAt,
      lastLogin: user.lastLogin,
      avatarUrl: user.avatarUrl,
    );
  }

  // Convert to entity
  User toEntity() => this;
}
