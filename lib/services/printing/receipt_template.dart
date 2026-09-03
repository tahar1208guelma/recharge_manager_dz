import '../../domain/entities/transaction.dart';

class ReceiptData {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String transactionNumber;
  final String receiptNumber;
  final String operator;
  final String phoneNumber;
  final double amount;
  final String? rechargeCode;
  final DateTime dateTime;
  final String status;
  final String? cashierName;
  final String qrData;

  ReceiptData({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.transactionNumber,
    required this.receiptNumber,
    required this.operator,
    required this.phoneNumber,
    required this.amount,
    this.rechargeCode,
    required this.dateTime,
    required this.status,
    this.cashierName,
    required this.qrData,
  });

  factory ReceiptData.fromTransaction(
    TransactionEntity tx, {
    String storeName = 'نقطة بيع وخدمات الاتصالات',
    String storeAddress = 'الجزائر العاصمة - الجزائر',
    String storePhone = '0550000000',
    String? cashierName,
  }) {
    final qr = 'DZ-RECHARGE|${tx.transactionNumber}|${tx.phoneNumber}|${tx.amount}|${tx.createdAt.toIso8601String()}';
    return ReceiptData(
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      transactionNumber: tx.transactionNumber,
      receiptNumber: tx.receiptNumber,
      operator: tx.operator.toUpperCase(),
      phoneNumber: tx.phoneNumber,
      amount: tx.amount,
      rechargeCode: tx.rechargeCode,
      dateTime: tx.createdAt,
      status: tx.status,
      cashierName: cashierName,
      qrData: qr,
    );
  }
}
