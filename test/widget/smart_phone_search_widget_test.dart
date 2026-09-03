import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recharge_manager_dz/core/localization/app_localizations.dart';
import 'package:recharge_manager_dz/domain/entities/customer.dart';
import 'package:recharge_manager_dz/domain/repositories/customer_repository.dart';
import 'package:recharge_manager_dz/presentation/providers/customer_provider.dart';
import 'package:recharge_manager_dz/presentation/providers/recharge_provider.dart';
import 'package:recharge_manager_dz/presentation/widgets/quick_amount_selector.dart';
import 'package:recharge_manager_dz/presentation/widgets/smart_phone_search_field.dart';
import 'package:recharge_manager_dz/services/operators/operator_factory.dart';
import 'package:recharge_manager_dz/domain/usecases/recharge_usecases.dart';
import 'package:recharge_manager_dz/domain/entities/transaction.dart';
import 'package:recharge_manager_dz/domain/repositories/transaction_repository.dart';

class MockCustomerRepository implements CustomerRepository {
  final List<Customer> customers = [
    Customer(
      id: 1,
      phoneNumber: '0661123456',
      operator: 'mobilis',
      name: 'أحمد بن علي',
      totalTransactions: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Customer>> searchCustomers(String query, {int limit = 10}) async {
    return customers.where((c) => c.phoneNumber.startsWith(query) || (c.name?.contains(query) ?? false)).toList();
  }

  @override
  Future<bool> deleteCustomer(int id) async => true;
  @override
  Future<List<Customer>> getAllCustomers({int offset = 0, int limit = 50}) async => customers;
  @override
  Future<Customer?> getCustomerById(int id) async => customers.first;
  @override
  Future<Customer?> getCustomerByPhone(String phoneNumber) async => customers.first;
  @override
  Future<int> getTotalCustomerCount() async => customers.length;
  @override
  Future<void> recordTransactionForCustomer(String phoneNumber, String operator) async {}
  @override
  Future<Customer> saveOrUpdateCustomer(Customer customer) async => customer;
}

class FakeTxRepo implements TransactionRepository {
  @override
  Future<String> exportTransactionsCsv({DateTime? fromDate, DateTime? toDate}) async => '';
  @override
  Future<List<TransactionEntity>> filterTransactions({String? query, String? operator, String? status, DateTime? fromDate, DateTime? toDate, int offset = 0, int limit = 50}) async => [];
  @override
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 10}) async => [];
  @override
  Future<Map<String, dynamic>> getStatistics({DateTime? fromDate, DateTime? toDate}) async => {};
  @override
  Future<TransactionEntity?> getTransactionById(int id) async => null;
  @override
  Future<TransactionEntity?> getTransactionByNumber(String transactionNumber) async => null;
  @override
  Future<List<TransactionEntity>> getTransactionsByPhone(String phoneNumber, {int limit = 5}) async => [];
  @override
  Future<TransactionEntity> saveTransaction(TransactionEntity transaction) async => transaction;
}

void main() {
  testWidgets('QuickAmountSelector renders preset amounts and handles tap', (WidgetTester tester) async {
    double selected = 100.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickAmountSelector(
            selectedAmount: selected,
            onAmountSelected: (val) => selected = val,
          ),
        ),
      ),
    );

    expect(find.text('100 د.ج'), findsOneWidget);
    expect(find.text('500 د.ج'), findsOneWidget);
    expect(find.text('1,000 د.ج'), findsOneWidget);

    await tester.tap(find.text('500 د.ج'));
    await tester.pumpAndSettle();

    expect(selected, 500.0);
  });

  testWidgets('SmartPhoneSearchField accepts text and updates controller', (WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final custRepo = MockCustomerRepository();
    final txRepo = FakeTxRepo();
    final custProvider = CustomerProvider(repository: custRepo);
    final rechargeProvider = RechargeProvider(
      rechargeUseCase: ExecuteRechargeUseCase(transactionRepository: txRepo, customerRepository: custRepo),
      operatorFactory: OperatorFactory(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: custProvider),
          ChangeNotifierProvider.value(value: rechargeProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          home: Scaffold(
            body: SmartPhoneSearchField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(SmartPhoneSearchField), findsOneWidget);

    controller.text = '0661123456';
    await tester.pumpAndSettle();

    expect(controller.text, '0661123456');
  });
}
