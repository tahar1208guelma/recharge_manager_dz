import 'package:flutter/material.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository repository;
  List<Customer> _searchResults = [];
  List<Customer> _allCustomers = [];
  bool _isLoading = false;
  String _currentQuery = '';

  CustomerProvider({required this.repository});

  List<Customer> get searchResults => _searchResults;
  List<Customer> get allCustomers => _allCustomers;
  bool get isLoading => _isLoading;
  String get currentQuery => _currentQuery;

  /// Fast Smart Search triggered when typing (especially for 05, 06, 07)
  Future<void> search(String query) async {
    _currentQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await repository.searchCustomers(query, limit: 10);
    } catch (_) {
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllCustomers({int offset = 0, int limit = 50}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allCustomers = await repository.getAllCustomers(offset: offset, limit: limit);
    } catch (_) {
      _allCustomers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Customer> saveCustomer(Customer customer) async {
    final saved = await repository.saveOrUpdateCustomer(customer);
    await loadAllCustomers();
    return saved;
  }

  Future<bool> deleteCustomer(int id) async {
    final success = await repository.deleteCustomer(id);
    if (success) {
      _allCustomers.removeWhere((c) => c.id == id);
      _searchResults.removeWhere((c) => c.id == id);
      notifyListeners();
    }
    return success;
  }

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    notifyListeners();
  }
}
