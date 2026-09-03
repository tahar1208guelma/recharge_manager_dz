import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<TransactionEntity> saveTransaction(TransactionEntity transaction);
  Future<TransactionEntity?> getTransactionById(int id);
  Future<TransactionEntity?> getTransactionByNumber(String transactionNumber);
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 10});
  Future<List<TransactionEntity>> filterTransactions({
    String? query,
    String? operator,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int offset = 0,
    int limit = 50,
  });
  Future<List<TransactionEntity>> getTransactionsByPhone(String phoneNumber, {int limit = 5});
  Future<Map<String, dynamic>> getStatistics({DateTime? fromDate, DateTime? toDate});
  Future<String> exportTransactionsCsv({DateTime? fromDate, DateTime? toDate});
}
