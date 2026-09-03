import 'package:sqflite/sqflite.dart';
import '../../../core/security/encryption_service.dart';
import '../../models/user_model.dart';
import 'database_helper.dart';

abstract class UserLocalDataSource {
  Future<UserModel?> authenticate(String username, String password);
  Future<List<UserModel>> getAllUsers();
  Future<UserModel> createUser(UserModel user, String password);
  Future<void> updateUser(UserModel user, {String? newPassword});
  Future<void> deleteUser(int id);
  Future<int> getUserCount();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DatabaseHelper _dbHelper;
  final Database? _db;

  UserLocalDataSourceImpl({DatabaseHelper? dbHelper, Database? database})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _db = database;

  Future<Database> get _database async {
    if (_db != null) return _db;
    return await _dbHelper.database;
  }

  @override
  Future<UserModel?> authenticate(String username, String password) async {
    final db = await _database;
    final passwordHash = EncryptionService.hash(password);
    final results = await db.query(
      'users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username.trim(), passwordHash],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final db = await _database;
    final results = await db.query('users', orderBy: 'id ASC');
    return results.map((m) => UserModel.fromMap(m)).toList();
  }

  @override
  Future<UserModel> createUser(UserModel user, String password) async {
    final db = await _database;
    final hash = EncryptionService.hash(password);
    final toInsert = user.toMap();
    toInsert['password_hash'] = hash;

    final id = await db.insert('users', toInsert);
    return UserModel(
      id: id,
      username: user.username,
      fullName: user.fullName,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
    );
  }

  @override
  Future<void> updateUser(UserModel user, {String? newPassword}) async {
    final db = await _database;
    final toUpdate = user.toMap();
    if (newPassword != null && newPassword.isNotEmpty) {
      toUpdate['password_hash'] = EncryptionService.hash(newPassword);
    }

    await db.update('users', toUpdate, where: 'id = ?', whereArgs: [user.id]);
  }

  @override
  Future<void> deleteUser(int id) async {
    final db = await _database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getUserCount() async {
    final db = await _database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return (result.first['count'] as int?) ?? 0;
  }
}
