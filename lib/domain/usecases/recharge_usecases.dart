import '../../core/utils/phone_validator.dart';
import '../../core/errors/exceptions.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/customer_repository.dart';
import '../../services/operators/operator_provider.dart';

class ExecuteRechargeUseCase {
  final TransactionRepository transactionRepository;
  final CustomerRepository customerRepository;

  ExecuteRechargeUseCase({
    required this.transactionRepository,
    required this.customerRepository,
  });

  Future<TransactionEntity> execute({
    required OperatorProvider provider,
    required String phoneNumber,
    required double amount,
    String? customerName,
    String? notes,
    int? userId,
    String source = 'MANUAL',
  }) async {
    final sanitizedPhone = PhoneValidator.sanitize(phoneNumber);
    if (!PhoneValidator.isValidAlgerianMobile(sanitizedPhone)) {
      throw ValidationException('Invalid Algerian mobile number: $phoneNumber');
    }
    if (amount <= 0) {
      throw ValidationException('Recharge amount must be greater than 0');
    }

    // Check provider connection
    final isConnected = await provider.connect();
    if (!isConnected) {
      throw OperatorException(
        'Operator connection failed for ${provider.operatorName}',
        operatorId: provider.operatorId,
      );
    }

    final txNumber = 'TX${DateTime.now().millisecondsSinceEpoch}';
    final receiptNumber = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Execute recharge through provider
    final result = await provider.recharge(
      phoneNumber: sanitizedPhone,
      amount: amount,
      transactionId: txNumber,
    );

    final transaction = TransactionEntity(
      transactionNumber: txNumber,
      phoneNumber: sanitizedPhone,
      operator: provider.operatorId,
      amount: amount,
      rechargeCode: result.rechargeCode,
      status: result.isSuccess ? 'SUCCESS' : 'FAILED',
      source: source,
      createdAt: DateTime.now(),
      userId: userId,
      receiptNumber: receiptNumber,
    );

    // Save transaction
    final savedTx = await transactionRepository.saveTransaction(transaction);

    // If successful, record customer data & recharge count
    if (result.isSuccess) {
      await customerRepository.recordTransactionForCustomer(sanitizedPhone, provider.operatorId);
      if (customerName != null && customerName.trim().isNotEmpty) {
        final existing = await customerRepository.getCustomerByPhone(sanitizedPhone);
        if (existing != null) {
          await customerRepository.saveOrUpdateCustomer(
            existing.copyWith(name: customerName.trim(), notes: notes?.trim()),
          );
        }
      }
    }

    return savedTx;
  }
}
