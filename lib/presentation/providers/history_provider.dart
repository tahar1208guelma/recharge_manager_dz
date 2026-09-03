import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final TransactionRepository repository;

  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> _recentTransactions = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;

  // Filter state
  String? _query;
  String? _selectedOperator;
  String? _selectedStatus;
  DateTime? _fromDate;
  DateTime? _toDate;

  HistoryProvider({required this.repository});

  List<TransactionEntity> get transactions => _transactions;
  List<TransactionEntity> get recentTransactions => _recentTransactions;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;

  String? get query => _query;
  String? get selectedOperator => _selectedOperator;
  String? get selectedStatus => _selectedStatus;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  Future<void> loadRecentTransactions({int limit = 10}) async {
    try {
      _recentTransactions = await repository.getRecentTransactions(limit: limit);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> filterTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await repository.filterTransactions(
        query: _query,
        operator: _selectedOperator,
        status: _selectedStatus,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      _statistics = await repository.getStatistics(
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } catch (_) {
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String? q) {
    _query = q;
    filterTransactions();
  }

  void setOperatorFilter(String? op) {
    _selectedOperator = op;
    filterTransactions();
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    filterTransactions();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    filterTransactions();
  }

  void resetFilters() {
    _query = null;
    _selectedOperator = null;
    _selectedStatus = null;
    _fromDate = null;
    _toDate = null;
    filterTransactions();
  }

  Future<String> exportCsv() async {
    return await repository.exportTransactionsCsv(
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }
}
