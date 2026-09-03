import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';
import 'database_helper.dart';

abstract class TransactionLocalDataSource {
  Future<TransactionModel> saveTransaction(TransactionModel transaction);
  Future<TransactionModel?> getTransactionById(int id);
  Future<TransactionModel?> getTransactionByNumber(String transactionNumber);
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10});
  Future<List<TransactionModel>> filterTransactions({
    String? query,
    String? operator,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int offset = 0,
    int limit = 50,
  });
  Future<List<TransactionModel>> getTransactionsByPhone(String phoneNumber, {int limit = 5});
  Future<Map<String, dynamic>> getStatistics({DateTime? fromDate, DateTime? toDate});
  Future<String> exportTransactionsCsv({DateTime? fromDate, DateTime? toDate});
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DatabaseHelper _dbHelper;
  final Database? _db;

  TransactionLocalDataSourceImpl({DatabaseHelper? dbHelper, Database? database})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _db = database;

  Future<Database> get _database async {
    if (_db != null) return _db;
    return await _dbHelper.database;
  }

  @override
  Future<TransactionModel> saveTransaction(TransactionModel transaction) async {
    final db = await _database;
    final id = await db.insert('transactions', transaction.toMap());
    return TransactionModel(
      id: id,
      transactionNumber: transaction.transactionNumber,
      phoneNumber: transaction.phoneNumber,
      operator: transaction.operator,
      amount: transaction.amount,
      rechargeCode: transaction.rechargeCode,
      status: transaction.status,
      source: transaction.source,
      createdAt: transaction.createdAt,
      userId: transaction.userId,
      receiptNumber: transaction.receiptNumber,
    );
  }

  @override
  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await _database;
    final results = await db.query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return TransactionModel.fromMap(results.first);
  }

  @override
  Future<TransactionModel?> getTransactionByNumber(String transactionNumber) async {
    final db = await _database;
    final results = await db.query(
      'transactions',
      where: 'transaction_number = ?',
      whereArgs: [transactionNumber],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return TransactionModel.fromMap(results.first);
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    final db = await _database;
    final results = await db.query(
      'transactions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return results.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<List<TransactionModel>> filterTransactions({
    String? query,
    String? operator,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int offset = 0,
    int limit = 50,
  }) async {
    final db = await _database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      whereClauses.add('(phone_number LIKE ? OR transaction_number LIKE ? OR receipt_number LIKE ?)');
      whereArgs.addAll(['%$clean%', '%$clean%', '%$clean%']);
    }

    if (operator != null && operator.trim().isNotEmpty && operator != 'all') {
      whereClauses.add('operator = ?');
      whereArgs.add(operator.trim().toLowerCase());
    }

    if (status != null && status.trim().isNotEmpty && status != 'all') {
      whereClauses.add('status = ?');
      whereArgs.add(status.trim().toUpperCase());
    }

    if (fromDate != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(toDate.toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'transactions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      offset: offset,
      limit: limit,
    );

    return results.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByPhone(String phoneNumber, {int limit = 5}) async {
    final db = await _database;
    final clean = phoneNumber.trim().replaceAll(' ', '');
    final results = await db.query(
      'transactions',
      where: 'phone_number = ?',
      whereArgs: [clean],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return results.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<Map<String, dynamic>> getStatistics({DateTime? fromDate, DateTime? toDate}) async {
    final db = await _database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (fromDate != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(toDate.toIso8601String());
    }
    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as total_count, COALESCE(SUM(amount), 0) as total_amount FROM transactions $whereString',
      whereArgs,
    );

    final successResult = await db.rawQuery(
      "SELECT COUNT(*) as count, COALESCE(SUM(amount), 0) as amount FROM transactions $whereString ${whereString.isEmpty ? 'WHERE' : 'AND'} status = 'SUCCESS'",
      whereArgs,
    );

    final failedResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transactions $whereString ${whereString.isEmpty ? 'WHERE' : 'AND'} status = 'FAILED'",
      whereArgs,
    );

    final operatorBreakdown = await db.rawQuery(
      'SELECT operator, COUNT(*) as count, COALESCE(SUM(amount), 0) as total FROM transactions $whereString GROUP BY operator',
      whereArgs,
    );

    return {
      'total_transactions': (countResult.first['total_count'] as int?) ?? 0,
      'total_volume_dzd': (countResult.first['total_amount'] as num?)?.toDouble() ?? 0.0,
      'success_count': (successResult.first['count'] as int?) ?? 0,
      'success_volume_dzd': (successResult.first['amount'] as num?)?.toDouble() ?? 0.0,
      'failed_count': (failedResult.first['count'] as int?) ?? 0,
      'operator_breakdown': operatorBreakdown,
    };
  }

  @override
  Future<String> exportTransactionsCsv({DateTime? fromDate, DateTime? toDate}) async {
    final transactions = await filterTransactions(
      fromDate: fromDate,
      toDate: toDate,
      limit: 10000,
    );

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Transaction Number,Receipt Number,Phone Number,Operator,Amount (DZD),Recharge Code,Status,Source,Date,Time');

    for (final tx in transactions) {
      final date = tx.createdAt.toIso8601String().split('T').first;
      final time = tx.createdAt.toIso8601String().split('T').last.substring(0, 8);
      buffer.writeln(
        '${tx.transactionNumber},${tx.receiptNumber},${tx.phoneNumber},${tx.operator},${tx.amount},"${tx.rechargeCode ?? ''}",${tx.status},${tx.source},$date,$time',
      );
    }

    return buffer.toString();
  }
}
