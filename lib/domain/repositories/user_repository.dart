import '../entities/user.dart';

abstract class UserRepository {
  Future<UserEntity?> authenticate(String username, String password);
  Future<List<UserEntity>> getAllUsers();
  Future<UserEntity> createUser(UserEntity user, String password);
  Future<void> updateUser(UserEntity user, {String? newPassword});
  Future<void> deleteUser(int id);
  Future<int> getUserCount();
}
