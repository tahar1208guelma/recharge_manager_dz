class TransactionEntity {
  final int? id;
  final String transactionNumber;
  final String phoneNumber;
  final String operator;
  final double amount;
  final String? rechargeCode;
  final String status; // SUCCESS, FAILED, PENDING
  final String source; // MANUAL, SMART_CARD, API
  final DateTime createdAt;
  final int? userId;
  final String receiptNumber;

  TransactionEntity({
    this.id,
    required this.transactionNumber,
    required this.phoneNumber,
    required this.operator,
    required this.amount,
    this.rechargeCode,
    required this.status,
    required this.source,
    required this.createdAt,
    this.userId,
    required this.receiptNumber,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  TransactionEntity copyWith({
    int? id,
    String? transactionNumber,
    String? phoneNumber,
    String? operator,
    double? amount,
    String? rechargeCode,
    String? status,
    String? source,
    DateTime? createdAt,
    int? userId,
    String? receiptNumber,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      operator: operator ?? this.operator,
      amount: amount ?? this.amount,
      rechargeCode: rechargeCode ?? this.rechargeCode,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }
}
