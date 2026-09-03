class RechargeOption {
  final String id;
  final String title;
  final double amount;
  final String? description;
  final int? validityDays;
  final String? bonusInfo;

  const RechargeOption({
    required this.id,
    required this.title,
    required this.amount,
    this.description,
    this.validityDays,
    this.bonusInfo,
  });
}
