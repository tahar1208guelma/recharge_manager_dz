import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:recharge_manager_dz/data/datasources/local/customer_local_datasource.dart';
import 'package:recharge_manager_dz/data/models/customer_model.dart';
import 'package:recharge_manager_dz/data/repositories/customer_repository_impl.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Customer Repository SQLite In-Memory Tests', () {
    late Database db;
    late CustomerRepositoryImpl repository;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
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
        },
      );

      final localDs = CustomerLocalDataSourceImpl(database: db);
      repository = CustomerRepositoryImpl(localDataSource: localDs);
    });

    tearDown(() async {
      await db.close();
    });

    test('Should insert and retrieve a customer by phone number', () async {
      final now = DateTime.now();
      final customer = CustomerModel(
        phoneNumber: '0661123456',
        operator: 'mobilis',
        name: 'أحمد بن علي',
        notes: 'ملاحظة تجريبية',
        createdAt: now,
        updatedAt: now,
      );

      final saved = await repository.saveOrUpdateCustomer(customer);
      expect(saved.id, isNotNull);
      expect(saved.phoneNumber, '0661123456');

      final fetched = await repository.getCustomerByPhone('0661123456');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'أحمد بن علي');
      expect(fetched.operator, 'mobilis');
    });

    test('Smart Search: Should find customers matching prefix 06 or 05', () async {
      final now = DateTime.now();
      await repository.saveOrUpdateCustomer(CustomerModel(
        phoneNumber: '0661123456',
        operator: 'mobilis',
        name: 'أحمد بن علي',
        createdAt: now,
        updatedAt: now,
      ));
      await repository.saveOrUpdateCustomer(CustomerModel(
        phoneNumber: '0669988776',
        operator: 'mobilis',
        name: 'ياسين الجزائري',
        createdAt: now,
        updatedAt: now,
      ));
      await repository.saveOrUpdateCustomer(CustomerModel(
        phoneNumber: '0555432100',
        operator: 'ooredoo',
        name: 'سمير بلقاسم',
        createdAt: now,
        updatedAt: now,
      ));

      final results06 = await repository.searchCustomers('06');
      expect(results06.length, 2);

      final results05 = await repository.searchCustomers('05');
      expect(results05.length, 1);
      expect(results05.first.phoneNumber, '0555432100');
    });

    test('Should record transaction and increment totalTransactions count', () async {
      await repository.recordTransactionForCustomer('0770987654', 'djezzy');
      final c1 = await repository.getCustomerByPhone('0770987654');
      expect(c1, isNotNull);
      expect(c1!.totalTransactions, 1);

      await repository.recordTransactionForCustomer('0770987654', 'djezzy');
      final c2 = await repository.getCustomerByPhone('0770987654');
      expect(c2!.totalTransactions, 2);
    });
  });
}
