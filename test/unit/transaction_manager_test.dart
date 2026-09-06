import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/transactions/transaction_manager.dart';
import 'package:recharge_manager_dz/transactions/transaction_state.dart';

void main() {
  group('TransactionManager Unit Tests', () {
    late TransactionManager manager;

    setUp(() {
      manager = TransactionManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('Should successfully create transaction and emit event', () {
      final tx = manager.createTransaction(
        operator: OperatorType.mobilis,
        phoneNumber: '0661123456',
        amount: 500,
      );

      expect(tx.phoneNumber, '0661123456');
      expect(tx.amount, 500);
      expect(tx.operator, OperatorType.mobilis);
      expect(tx.status, PosTransactionStatus.pending);
      expect(manager.transactions.length, 1);
      expect(manager.events.length, 1);
      expect(manager.events.first.eventType, 'CREATED');
    });

    test('Should block rapid duplicate transaction for same phone and amount within 45s', () {
      manager.createTransaction(
        operator: OperatorType.mobilis,
        phoneNumber: '0661123456',
        amount: 500,
      );

      expect(
        () => manager.createTransaction(
          operator: OperatorType.mobilis,
          phoneNumber: '0661123456',
          amount: 500,
        ),
        throwsStateError,
      );
    });

    test('Should allow transaction with different phone or different amount', () {
      final tx1 = manager.createTransaction(
        operator: OperatorType.mobilis,
        phoneNumber: '0661123456',
        amount: 500,
      );

      // Different phone
      final tx2 = manager.createTransaction(
        operator: OperatorType.djezzy,
        phoneNumber: '0770123456',
        amount: 500,
      );

      // Same phone, different amount
      final tx3 = manager.createTransaction(
        operator: OperatorType.mobilis,
        phoneNumber: '0661123456',
        amount: 1000,
      );

      expect(manager.transactions.length, 3);
      expect(tx1.transactionId, isNotEmpty);
      expect(tx2.transactionId, isNotEmpty);
      expect(tx3.transactionId, isNotEmpty);
    });

    test('Should transition to SUCCESS with network reference', () {
      final tx = manager.createTransaction(
        operator: OperatorType.ooredoo,
        phoneNumber: '0550123456',
        amount: 200,
      );

      manager.markSuccess(
        tx.transactionId,
        reference: 'NET-REF-998822',
        responseMessage: 'Recharge effectuee avec succes.',
      );

      final updated = manager.transactions.firstWhere((t) => t.transactionId == tx.transactionId);
      expect(updated.status, PosTransactionStatus.success);
      expect(updated.networkReference, 'NET-REF-998822');
      expect(updated.responseMessage, 'Recharge effectuee avec succes.');
      expect(updated.endTime, isNotNull);
    });

    test('Should mark transaction as UNKNOWN on timeout to protect vendor', () {
      final tx = manager.createTransaction(
        operator: OperatorType.mobilis,
        phoneNumber: '0661999888',
        amount: 1000,
      );

      manager.markUnknownTimeout(tx.transactionId, details: 'Network timeout after 15s');

      final updated = manager.transactions.firstWhere((t) => t.transactionId == tx.transactionId);
      expect(updated.status, PosTransactionStatus.unknown);
      expect(updated.errorMessage?.contains('فحص رصيد الشريحة'), true);
    });

    test('Should mark transaction as FAILED when explicitly rejected by network', () {
      final tx = manager.createTransaction(
        operator: OperatorType.djezzy,
        phoneNumber: '0770999888',
        amount: 2000,
      );

      manager.markFailed(tx.transactionId, error: 'Solde distributeur insuffisant');

      final updated = manager.transactions.firstWhere((t) => t.transactionId == tx.transactionId);
      expect(updated.status, PosTransactionStatus.failed);
      expect(updated.errorMessage, 'Solde distributeur insuffisant');
    });
  });
}
