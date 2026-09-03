import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:recharge_manager_dz/data/datasources/local/transaction_local_datasource.dart';
import 'package:recharge_manager_dz/data/models/transaction_model.dart';
import 'package:recharge_manager_dz/data/repositories/transaction_repository_impl.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Transaction Repository SQLite In-Memory Tests', () {
    late Database db;
    late TransactionRepositoryImpl repository;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
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
        },
      );

      final localDs = TransactionLocalDataSourceImpl(database: db);
      repository = TransactionRepositoryImpl(localDataSource: localDs);
    });

    tearDown(() async {
      await db.close();
    });

    test('Should save transaction and calculate statistics correctly', () async {
      final now = DateTime.now();
      await repository.saveTransaction(TransactionModel(
        transactionNumber: 'TX001',
        phoneNumber: '0661123456',
        operator: 'mobilis',
        amount: 500.0,
        rechargeCode: '123456789012',
        status: 'SUCCESS',
        source: 'MANUAL',
        createdAt: now,
        receiptNumber: 'REC-001',
      ));

      await repository.saveTransaction(TransactionModel(
        transactionNumber: 'TX002',
        phoneNumber: '0770987654',
        operator: 'djezzy',
        amount: 1000.0,
        rechargeCode: '987654321098',
        status: 'SUCCESS',
        source: 'SMART_CARD',
        createdAt: now,
        receiptNumber: 'REC-002',
      ));

      await repository.saveTransaction(TransactionModel(
        transactionNumber: 'TX003',
        phoneNumber: '0555432100',
        operator: 'ooredoo',
        amount: 200.0,
        status: 'FAILED',
        source: 'MANUAL',
        createdAt: now,
        receiptNumber: 'REC-003',
      ));

      final stats = await repository.getStatistics();
      expect(stats['total_transactions'], 3);
      expect(stats['total_volume_dzd'], 1700.0);
      expect(stats['success_count'], 2);
      expect(stats['failed_count'], 1);

      final csv = await repository.exportTransactionsCsv();
      expect(csv, contains('TX001'));
      expect(csv, contains('TX002'));
      expect(csv, contains('REC-001'));
    });
  });
}
