import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/utils/app_logger.dart';

class DatabaseHelper {
  static const String _dbName = 'recharge_manager_dz.db';
  static const int _dbVersion = 1;

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
        AppLogger.info('Initializing SQLite database on Web...');
        return await openDatabase(
          inMemoryDatabasePath,
          version: _dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final docDir = await getApplicationDocumentsDirectory();
      final appDir = Directory(join(docDir.path, 'RechargeManagerDZ'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      final path = join(appDir.path, _dbName);

      AppLogger.info('Initializing SQLite database at: $path');
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      AppLogger.warn('Database initialization error ($e), falling back to in-memory database');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      return await openDatabase(
        inMemoryDatabasePath,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating SQLite database schema version $version...');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT NOT NULL UNIQUE,
        operator TEXT NOT NULL,
        name TEXT,
        notes TEXT,
        last_recharge TEXT,
        total_transactions INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_customers_phone ON customers(phone_number);
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_number TEXT NOT NULL UNIQUE,
        phone_number TEXT NOT NULL,
        operator TEXT NOT NULL,
        amount REAL NOT NULL,
        recharge_code TEXT,
        status TEXT NOT NULL,
        source TEXT NOT NULL,
        created_at TEXT NOT NULL,
        user_id INTEGER,
        receipt_number TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_created ON transactions(created_at);
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_phone ON transactions(phone_number);
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_operator ON transactions(operator);
    ''');

    await db.execute('''
      CREATE TABLE licenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        license_id TEXT NOT NULL UNIQUE,
        customer_id TEXT NOT NULL,
        plan TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        start_date TEXT NOT NULL,
        expiry_date TEXT,
        max_devices INTEGER DEFAULT 1,
        device_id TEXT NOT NULL,
        features TEXT NOT NULL,
        last_check TEXT NOT NULL,
        offline_grace_period INTEGER DEFAULT 7,
        token TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Seed default admin user (admin / admin123)
    final adminHash = EncryptionService.hash('admin123');
    await db.insert('users', {
      'username': 'admin',
      'full_name': 'مدير النظام (Admin)',
      'role': 'ADMIN',
      'is_active': 1,
      'password_hash': adminHash,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed default cashier (cashier / cashier123)
    final cashierHash = EncryptionService.hash('cashier123');
    await db.insert('users', {
      'username': 'cashier',
      'full_name': 'عامل الصندوق (Cashier)',
      'role': 'CASHIER',
      'is_active': 1,
      'password_hash': cashierHash,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed initial mock customers for instant smart search demonstration
    final now = DateTime.now();
    await db.insert('customers', {
      'phone_number': '0661123456',
      'operator': 'mobilis',
      'name': 'أحمد بن علي',
      'notes': 'زبون دائم',
      'last_recharge': now.subtract(const Duration(days: 1)).toIso8601String(),
      'total_transactions': 5,
      'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
      'updated_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    });

    await db.insert('customers', {
      'phone_number': '0770987654',
      'operator': 'djezzy',
      'name': 'كريم منصوري',
      'notes': 'محل هواتف',
      'last_recharge': now.subtract(const Duration(hours: 3)).toIso8601String(),
      'total_transactions': 12,
      'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
      'updated_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
    });

    await db.insert('customers', {
      'phone_number': '0555432100',
      'operator': 'ooredoo',
      'name': 'سمير بلقاسم',
      'notes': 'خدمات سريعة',
      'last_recharge': now.subtract(const Duration(minutes: 45)).toIso8601String(),
      'total_transactions': 8,
      'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
      'updated_at': now.subtract(const Duration(minutes: 45)).toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading SQLite database from $oldVersion to $newVersion');
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
