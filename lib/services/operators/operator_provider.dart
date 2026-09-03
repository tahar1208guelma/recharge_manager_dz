import '../../domain/entities/operator_info.dart';
import '../../domain/entities/balance_info.dart';
import '../../domain/entities/recharge_result.dart';
import '../../domain/entities/recharge_option.dart';

abstract class OperatorProvider {
  String get operatorId;
  String get operatorName;
  bool get isConnected;

  Future<bool> connect();
  Future<void> disconnect();
  Future<OperatorInfo> getOperatorInfo();
  Future<BalanceInfo> getBalance();
  Future<RechargeResult> recharge({
    required String phoneNumber,
    required double amount,
    String? transactionId,
    Map<String, dynamic>? customData,
  });
  Future<List<RechargeOption>> getRechargeOptions();
}
