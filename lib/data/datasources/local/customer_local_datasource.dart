import 'package:sqflite/sqflite.dart';
import '../../models/customer_model.dart';
import 'database_helper.dart';

abstract class CustomerLocalDataSource {
  Future<List<CustomerModel>> searchCustomers(String query, {int limit = 10});
  Future<CustomerModel?> getCustomerByPhone(String phoneNumber);
  Future<CustomerModel?> getCustomerById(int id);
  Future<List<CustomerModel>> getAllCustomers({int offset = 0, int limit = 50});
  Future<CustomerModel> saveOrUpdateCustomer(CustomerModel customer);
  Future<void> recordTransactionForCustomer(String phoneNumber, String operator);
  Future<bool> deleteCustomer(int id);
  Future<int> getTotalCustomerCount();
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final DatabaseHelper _dbHelper;
  final Database? _db;

  CustomerLocalDataSourceImpl({DatabaseHelper? dbHelper, Database? database})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _db = database;

  Future<Database> get _database async {
    if (_db != null) return _db;
    return await _dbHelper.database;
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query, {int limit = 10}) async {
    final db = await _database;
    final sanitizedQuery = query.trim().replaceAll(' ', '');
    if (sanitizedQuery.isEmpty) {
      return getAllCustomers(limit: limit);
    }

    final results = await db.query(
      'customers',
      where: 'phone_number LIKE ? OR name LIKE ?',
      whereArgs: ['$sanitizedQuery%', '%$query%'],
      orderBy: 'last_recharge DESC, total_transactions DESC',
      limit: limit,
    );

    return results.map((m) => CustomerModel.fromMap(m)).toList();
  }

  @override
  Future<CustomerModel?> getCustomerByPhone(String phoneNumber) async {
    final db = await _database;
    final clean = phoneNumber.trim().replaceAll(' ', '');
    final results = await db.query(
      'customers',
      where: 'phone_number = ?',
      whereArgs: [clean],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CustomerModel.fromMap(results.first);
  }

  @override
  Future<CustomerModel?> getCustomerById(int id) async {
    final db = await _database;
    final results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CustomerModel.fromMap(results.first);
  }

  @override
  Future<List<CustomerModel>> getAllCustomers({int offset = 0, int limit = 50}) async {
    final db = await _database;
    final results = await db.query(
      'customers',
      orderBy: 'updated_at DESC',
      offset: offset,
      limit: limit,
    );

    return results.map((m) => CustomerModel.fromMap(m)).toList();
  }

  @override
  Future<CustomerModel> saveOrUpdateCustomer(CustomerModel customer) async {
    final db = await _database;
    final cleanPhone = customer.phoneNumber.trim().replaceAll(' ', '');
    final now = DateTime.now();

    final existing = await getCustomerByPhone(cleanPhone);
    if (existing != null) {
      final updated = CustomerModel(
        id: existing.id,
        phoneNumber: cleanPhone,
        operator: customer.operator.isNotEmpty ? customer.operator : existing.operator,
        name: customer.name ?? existing.name,
        notes: customer.notes ?? existing.notes,
        lastRecharge: customer.lastRecharge ?? existing.lastRecharge,
        totalTransactions: customer.totalTransactions > 0
            ? customer.totalTransactions
            : existing.totalTransactions,
        createdAt: existing.createdAt,
        updatedAt: now,
      );

      await db.update(
        'customers',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return updated;
    } else {
      final newCustomer = CustomerModel(
        phoneNumber: cleanPhone,
        operator: customer.operator,
        name: customer.name,
        notes: customer.notes,
        lastRecharge: customer.lastRecharge,
        totalTransactions: customer.totalTransactions,
        createdAt: now,
        updatedAt: now,
      );

      final id = await db.insert('customers', newCustomer.toMap());
      return CustomerModel(
        id: id,
        phoneNumber: newCustomer.phoneNumber,
        operator: newCustomer.operator,
        name: newCustomer.name,
        notes: newCustomer.notes,
        lastRecharge: newCustomer.lastRecharge,
        totalTransactions: newCustomer.totalTransactions,
        createdAt: newCustomer.createdAt,
        updatedAt: newCustomer.updatedAt,
      );
    }
  }

  @override
  Future<void> recordTransactionForCustomer(String phoneNumber, String operator) async {
    final db = await _database;
    final cleanPhone = phoneNumber.trim().replaceAll(' ', '');
    final now = DateTime.now();

    final existing = await getCustomerByPhone(cleanPhone);
    if (existing != null) {
      await db.rawUpdate('''
        UPDATE customers 
        SET total_transactions = total_transactions + 1,
            last_recharge = ?,
            updated_at = ?
        WHERE id = ?
      ''', [now.toIso8601String(), now.toIso8601String(), existing.id]);
    } else {
      await db.insert('customers', {
        'phone_number': cleanPhone,
        'operator': operator,
        'name': null,
        'notes': null,
        'last_recharge': now.toIso8601String(),
        'total_transactions': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }

  @override
  Future<bool> deleteCustomer(int id) async {
    final db = await _database;
    final count = await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }

  @override
  Future<int> getTotalCustomerCount() async {
    final db = await _database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return (result.first['count'] as int?) ?? 0;
  }
}
