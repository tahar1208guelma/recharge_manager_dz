import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _localDataSource;

  TransactionRepositoryImpl({TransactionLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? TransactionLocalDataSourceImpl();

  @override
  Future<TransactionEntity> saveTransaction(TransactionEntity transaction) async {
    final model = transaction is TransactionModel
        ? transaction
        : TransactionModel.fromEntity(transaction);
    return await _localDataSource.saveTransaction(model);
  }

  @override
  Future<TransactionEntity?> getTransactionById(int id) async {
    return await _localDataSource.getTransactionById(id);
  }

  @override
  Future<TransactionEntity?> getTransactionByNumber(String transactionNumber) async {
    return await _localDataSource.getTransactionByNumber(transactionNumber);
  }

  @override
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 10}) async {
    return await _localDataSource.getRecentTransactions(limit: limit);
  }

  @override
  Future<List<TransactionEntity>> filterTransactions({
    String? query,
    String? operator,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int offset = 0,
    int limit = 50,
  }) async {
    return await _localDataSource.filterTransactions(
      query: query,
      operator: operator,
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<List<TransactionEntity>> getTransactionsByPhone(String phoneNumber, {int limit = 5}) async {
    return await _localDataSource.getTransactionsByPhone(phoneNumber, limit: limit);
  }

  @override
  Future<Map<String, dynamic>> getStatistics({DateTime? fromDate, DateTime? toDate}) async {
    return await _localDataSource.getStatistics(fromDate: fromDate, toDate: toDate);
  }

  @override
  Future<String> exportTransactionsCsv({DateTime? fromDate, DateTime? toDate}) async {
    return await _localDataSource.exportTransactionsCsv(fromDate: fromDate, toDate: toDate);
  }
}
