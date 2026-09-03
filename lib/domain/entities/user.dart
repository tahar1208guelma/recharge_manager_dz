class UserEntity {
  final int? id;
  final String username;
  final String fullName;
  final String role; // ADMIN, CASHIER, SUPERVISOR
  final bool isActive;
  final DateTime createdAt;

  UserEntity({
    this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isCashier => role.toUpperCase() == 'CASHIER';
}
