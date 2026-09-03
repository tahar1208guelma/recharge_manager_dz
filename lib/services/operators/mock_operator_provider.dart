import 'dart:async';
import 'dart:math';
import '../../core/constants/operator_constants.dart';
import '../../domain/entities/balance_info.dart';
import '../../domain/entities/operator_info.dart';
import '../../domain/entities/recharge_option.dart';
import '../../domain/entities/recharge_result.dart';
import 'operator_provider.dart';

class MockOperatorProvider implements OperatorProvider {
  final OperatorType operatorType;
  double _balance;
  bool _connected = true;
  bool shouldSimulateFailure = false;
  String? forcedErrorMessage;

  MockOperatorProvider({
    required this.operatorType,
    double initialBalance = 50000.0,
  }) : _balance = initialBalance;

  @override
  String get operatorId => OperatorConstants.getOperatorId(operatorType);

  @override
  String get operatorName => OperatorConstants.getOperatorName(operatorType, lang: 'en');

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<OperatorInfo> getOperatorInfo() async {
    List<String> prefixes;
    String mnc;

    switch (operatorType) {
      case OperatorType.mobilis:
        prefixes = OperatorConstants.mobilisPrefixes;
        mnc = OperatorConstants.mobilisMnc;
        break;
      case OperatorType.djezzy:
        prefixes = OperatorConstants.djezzyPrefixes;
        mnc = OperatorConstants.djezzyMnc;
        break;
      case OperatorType.ooredoo:
        prefixes = OperatorConstants.ooredooPrefixes;
        mnc = OperatorConstants.ooredooMnc;
        break;
      default:
        prefixes = [];
        mnc = '00';
    }

    return OperatorInfo(
      id: operatorId,
      name: operatorName,
      fullName: OperatorConstants.getOperatorName(operatorType, lang: 'ar'),
      mnc: mnc,
      prefixes: prefixes,
      isConnected: _connected,
    );
  }

  @override
  Future<BalanceInfo> getBalance() async {
    return BalanceInfo(
      operatorId: operatorId,
      currentBalance: _balance,
      currency: 'DZD',
      lastUpdated: DateTime.now(),
      accountId: 'MOCK-POS-${operatorId.toUpperCase()}-001',
    );
  }

  @override
  Future<RechargeResult> recharge({
    required String phoneNumber,
    required double amount,
    String? transactionId,
    Map<String, dynamic>? customData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (shouldSimulateFailure) {
      return RechargeResult.failure(
        message: forcedErrorMessage ?? 'Operator API rejected transaction',
        transactionId: transactionId,
      );
    }

    if (_balance < amount) {
      return RechargeResult.failure(
        message: 'Insufficient dealer commercial balance ($_balance DZD available)',
        transactionId: transactionId,
      );
    }

    _balance -= amount;
    final r1 = 100000 + Random().nextInt(899999);
    final r2 = 100000 + Random().nextInt(899999);
    final randomPin = '$r1$r2';
    final effectiveTxId = transactionId ?? 'TX${DateTime.now().millisecondsSinceEpoch}';
    final receiptNum = 'REC-${effectiveTxId.substring(effectiveTxId.length - 6)}';

    return RechargeResult.success(
      transactionId: effectiveTxId,
      rechargeCode: randomPin,
      receiptNumber: receiptNum,
      message: 'Recharge completed successfully ($amount DZD)',
      newBalance: _balance,
      rawResponse: {
        'operator': operatorId,
        'phone': phoneNumber,
        'amount': amount,
        'status': 'SUCCESS',
        'auth_code': 'AUTH-${Random().nextInt(999999)}',
      },
    );
  }

  @override
  Future<List<RechargeOption>> getRechargeOptions() async {
    return const [
      RechargeOption(id: 'flexy_100', title: '100 DZD', amount: 100),
      RechargeOption(id: 'flexy_200', title: '200 DZD', amount: 200),
      RechargeOption(id: 'flexy_500', title: '500 DZD', amount: 500, bonusInfo: '+ 50 DZD Bonus'),
      RechargeOption(id: 'flexy_1000', title: '1000 DZD', amount: 1000, bonusInfo: '+ 200 DZD Bonus'),
      RechargeOption(id: 'flexy_2000', title: '2000 DZD', amount: 2000, bonusInfo: '+ 500 DZD Bonus'),
    ];
  }

  void setBalanceForTesting(double balance) {
    _balance = balance;
  }
}
