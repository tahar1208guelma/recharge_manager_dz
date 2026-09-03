import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

abstract class SettingsLocalDataSource {
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<Map<String, String>> getAllSettings();
  Future<void> deleteSetting(String key);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final DatabaseHelper _dbHelper;
  final Database? _db;

  SettingsLocalDataSourceImpl({DatabaseHelper? dbHelper, Database? database})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _db = database;

  Future<Database> get _database async {
    if (_db != null) return _db;
    return await _dbHelper.database;
  }

  @override
  Future<String?> getSetting(String key) async {
    final db = await _database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    final db = await _database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, String>> getAllSettings() async {
    final db = await _database;
    final results = await db.query('settings');
    final map = <String, String>{};
    for (final row in results) {
      map[row['key'] as String] = row['value'] as String;
    }
    return map;
  }

  @override
  Future<void> deleteSetting(String key) async {
    final db = await _database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
