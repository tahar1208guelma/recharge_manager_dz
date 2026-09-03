import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/local/customer_local_datasource.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource _localDataSource;

  CustomerRepositoryImpl({CustomerLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? CustomerLocalDataSourceImpl();

  @override
  Future<List<Customer>> searchCustomers(String query, {int limit = 10}) async {
    return await _localDataSource.searchCustomers(query, limit: limit);
  }

  @override
  Future<Customer?> getCustomerByPhone(String phoneNumber) async {
    return await _localDataSource.getCustomerByPhone(phoneNumber);
  }

  @override
  Future<Customer?> getCustomerById(int id) async {
    return await _localDataSource.getCustomerById(id);
  }

  @override
  Future<List<Customer>> getAllCustomers({int offset = 0, int limit = 50}) async {
    return await _localDataSource.getAllCustomers(offset: offset, limit: limit);
  }

  @override
  Future<Customer> saveOrUpdateCustomer(Customer customer) async {
    final model = customer is CustomerModel ? customer : CustomerModel.fromEntity(customer);
    return await _localDataSource.saveOrUpdateCustomer(model);
  }

  @override
  Future<void> recordTransactionForCustomer(String phoneNumber, String operator) async {
    await _localDataSource.recordTransactionForCustomer(phoneNumber, operator);
  }

  @override
  Future<bool> deleteCustomer(int id) async {
    return await _localDataSource.deleteCustomer(id);
  }

  @override
  Future<int> getTotalCustomerCount() async {
    return await _localDataSource.getTotalCustomerCount();
  }
}
