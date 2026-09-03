import '../../domain/entities/user.dart';

class UserModel extends UserEntity {
  final String? passwordHash;

  UserModel({
    super.id,
    required super.username,
    required super.fullName,
    required super.role,
    super.isActive = true,
    required super.createdAt,
    this.passwordHash,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      passwordHash: map['password_hash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      if (passwordHash != null) 'password_hash': passwordHash,
    };
  }

  factory UserModel.fromEntity(UserEntity entity, {String? passwordHash}) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      fullName: entity.fullName,
      role: entity.role,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      passwordHash: passwordHash,
    );
  }
}
