class BalanceInfo {
  final String operatorId;
  final double currentBalance;
  final String currency;
  final DateTime lastUpdated;
  final double? creditLimit;
  final String? accountId;

  const BalanceInfo({
    required this.operatorId,
    required this.currentBalance,
    this.currency = 'DZD',
    required this.lastUpdated,
    this.creditLimit,
    this.accountId,
  });
}
