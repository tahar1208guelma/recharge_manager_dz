import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> searchCustomers(String query, {int limit = 10});
  Future<Customer?> getCustomerByPhone(String phoneNumber);
  Future<Customer?> getCustomerById(int id);
  Future<List<Customer>> getAllCustomers({int offset = 0, int limit = 50});
  Future<Customer> saveOrUpdateCustomer(Customer customer);
  Future<void> recordTransactionForCustomer(String phoneNumber, String operator);
  Future<bool> deleteCustomer(int id);
  Future<int> getTotalCustomerCount();
}
