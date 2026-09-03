import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _localDataSource;

  UserRepositoryImpl({UserLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? UserLocalDataSourceImpl();

  @override
  Future<UserEntity?> authenticate(String username, String password) async {
    return await _localDataSource.authenticate(username, password);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    return await _localDataSource.getAllUsers();
  }

  @override
  Future<UserEntity> createUser(UserEntity user, String password) async {
    final model = user is UserModel ? user : UserModel.fromEntity(user);
    return await _localDataSource.createUser(model, password);
  }

  @override
  Future<void> updateUser(UserEntity user, {String? newPassword}) async {
    final model = user is UserModel ? user : UserModel.fromEntity(user);
    await _localDataSource.updateUser(model, newPassword: newPassword);
  }

  @override
  Future<void> deleteUser(int id) async {
    await _localDataSource.deleteUser(id);
  }

  @override
  Future<int> getUserCount() async {
    return await _localDataSource.getUserCount();
  }
}
