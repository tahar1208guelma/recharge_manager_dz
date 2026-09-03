import 'package:flutter/material.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/phone_validator.dart';
import '../../domain/entities/balance_info.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/recharge_usecases.dart';
import '../../services/operators/operator_factory.dart';
import '../../services/operators/operator_provider.dart';

class RechargeProvider extends ChangeNotifier {
  final ExecuteRechargeUseCase rechargeUseCase;
  final OperatorFactory operatorFactory;

  OperatorType _selectedOperator = OperatorType.mobilis;
  String _phoneNumber = '';
  double _amount = 100.0;
  String? _customerName;
  String? _notes;

  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  TransactionEntity? _lastTransaction;

  // Balances cache
  final Map<OperatorType, BalanceInfo> _balances = {};

  RechargeProvider({
    required this.rechargeUseCase,
    required this.operatorFactory,
  });

  OperatorType get selectedOperator => _selectedOperator;
  String get phoneNumber => _phoneNumber;
  double get amount => _amount;
  String? get customerName => _customerName;
  String? get notes => _notes;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  TransactionEntity? get lastTransaction => _lastTransaction;
  Map<OperatorType, BalanceInfo> get balances => _balances;

  OperatorProvider get currentProvider => operatorFactory.getProvider(_selectedOperator);

  void setOperator(OperatorType operator) {
    if (_selectedOperator != operator) {
      _selectedOperator = operator;
      _errorMessage = null;
      notifyListeners();
      refreshBalance(operator);
    }
  }

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    _errorMessage = null;

    // Auto-detect operator if user types valid prefix (05, 06, 07)
    final detected = PhoneValidator.getOperator(phone);
    if (detected != OperatorType.unknown && detected != _selectedOperator) {
      _selectedOperator = detected;
      refreshBalance(detected);
    }
    notifyListeners();
  }

  void selectCustomer(Customer customer) {
    _phoneNumber = customer.phoneNumber;
    _customerName = customer.name;
    _notes = customer.notes;

    final detected = OperatorConstants.fromString(customer.operator);
    if (detected != OperatorType.unknown) {
      _selectedOperator = detected;
    } else {
      final phoneOp = PhoneValidator.getOperator(customer.phoneNumber);
      if (phoneOp != OperatorType.unknown) {
        _selectedOperator = phoneOp;
      }
    }
    _errorMessage = null;
    notifyListeners();
    refreshBalance(_selectedOperator);
  }

  void setAmount(double value) {
    _amount = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setCustomerName(String? name) {
    _customerName = name;
    notifyListeners();
  }

  void setNotes(String? noteText) {
    _notes = noteText;
    notifyListeners();
  }

  Future<void> refreshBalance(OperatorType operator) async {
    try {
      final provider = operatorFactory.getProvider(operator);
      final balance = await provider.getBalance();
      _balances[operator] = balance;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshAllBalances() async {
    for (final op in [OperatorType.mobilis, OperatorType.djezzy, OperatorType.ooredoo]) {
      await refreshBalance(op);
    }
  }

  Future<bool> executeRecharge({int? userId, String source = 'MANUAL'}) async {
    _isProcessing = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final tx = await rechargeUseCase.execute(
        provider: currentProvider,
        phoneNumber: _phoneNumber,
        amount: _amount,
        customerName: _customerName,
        notes: _notes,
        userId: userId,
        source: source,
      );

      _lastTransaction = tx;
      if (tx.isSuccess) {
        _successMessage = 'Recharge successful for ${tx.phoneNumber} (${tx.amount} DZD)';
        await refreshBalance(_selectedOperator);
      } else {
        _errorMessage = 'Recharge failed for ${tx.phoneNumber}';
      }

      return tx.isSuccess;
    } on ValidationException catch (e) {
      _errorMessage = e.message;
      return false;
    } on OperatorException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearForm() {
    _phoneNumber = '';
    _customerName = null;
    _notes = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
