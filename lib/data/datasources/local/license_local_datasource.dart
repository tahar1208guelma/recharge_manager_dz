import 'package:sqflite/sqflite.dart';
import '../../models/license_model.dart';
import 'database_helper.dart';

abstract class LicenseLocalDataSource {
  Future<LicenseModel?> getCachedLicense();
  Future<void> saveLicense(LicenseModel license);
  Future<void> clearLicense();
  Future<DateTime?> getLastTamperCheckTimestamp();
  Future<void> updateLastTamperCheckTimestamp(DateTime timestamp);
}

class LicenseLocalDataSourceImpl implements LicenseLocalDataSource {
  static const String _tamperKey = 'TAMPER_LAST_CLOCK_CHECK';
  final DatabaseHelper _dbHelper;
  final Database? _db;

  LicenseLocalDataSourceImpl({DatabaseHelper? dbHelper, Database? database})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _db = database;

  Future<Database> get _database async {
    if (_db != null) return _db;
    return await _dbHelper.database;
  }

  @override
  Future<LicenseModel?> getCachedLicense() async {
    final db = await _database;
    final results = await db.query('licenses', orderBy: 'id DESC', limit: 1);
    if (results.isEmpty) return null;
    return LicenseModel.fromMap(results.first);
  }

  @override
  Future<void> saveLicense(LicenseModel license) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('licenses');
      await txn.insert('licenses', license.toMap());
    });
  }

  @override
  Future<void> clearLicense() async {
    final db = await _database;
    await db.delete('licenses');
  }

  @override
  Future<DateTime?> getLastTamperCheckTimestamp() async {
    final db = await _database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [_tamperKey], limit: 1);
    if (results.isEmpty) return null;
    return DateTime.tryParse(results.first['value'] as String);
  }

  @override
  Future<void> updateLastTamperCheckTimestamp(DateTime timestamp) async {
    final db = await _database;
    await db.insert(
      'settings',
      {'key': _tamperKey, 'value': timestamp.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
