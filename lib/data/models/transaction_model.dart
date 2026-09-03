import '../../domain/entities/transaction.dart';

class TransactionModel extends TransactionEntity {
  TransactionModel({
    super.id,
    required super.transactionNumber,
    required super.phoneNumber,
    required super.operator,
    required super.amount,
    super.rechargeCode,
    required super.status,
    required super.source,
    required super.createdAt,
    super.userId,
    required super.receiptNumber,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      transactionNumber: map['transaction_number'] as String,
      phoneNumber: map['phone_number'] as String,
      operator: map['operator'] as String,
      amount: (map['amount'] as num).toDouble(),
      rechargeCode: map['recharge_code'] as String?,
      status: map['status'] as String,
      source: map['source'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['user_id'] as int?,
      receiptNumber: map['receipt_number'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_number': transactionNumber,
      'phone_number': phoneNumber,
      'operator': operator,
      'amount': amount,
      'recharge_code': rechargeCode,
      'status': status,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'receipt_number': receiptNumber,
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      transactionNumber: entity.transactionNumber,
      phoneNumber: entity.phoneNumber,
      operator: entity.operator,
      amount: entity.amount,
      rechargeCode: entity.rechargeCode,
      status: entity.status,
      source: entity.source,
      createdAt: entity.createdAt,
      userId: entity.userId,
      receiptNumber: entity.receiptNumber,
    );
  }
}
