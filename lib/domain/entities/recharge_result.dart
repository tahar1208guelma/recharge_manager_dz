class RechargeResult {
  final bool isSuccess;
  final String transactionId;
  final String? rechargeCode;
  final String? receiptNumber;
  final String? message;
  final double? newBalance;
  final DateTime timestamp;
  final Map<String, dynamic>? rawResponse;

  RechargeResult({
    required this.isSuccess,
    required this.transactionId,
    this.rechargeCode,
    this.receiptNumber,
    this.message,
    this.newBalance,
    DateTime? timestamp,
    this.rawResponse,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RechargeResult.success({
    required String transactionId,
    String? rechargeCode,
    String? receiptNumber,
    String? message,
    double? newBalance,
    Map<String, dynamic>? rawResponse,
  }) {
    return RechargeResult(
      isSuccess: true,
      transactionId: transactionId,
      rechargeCode: rechargeCode,
      receiptNumber: receiptNumber,
      message: message ?? 'Recharge completed successfully',
      newBalance: newBalance,
      rawResponse: rawResponse,
    );
  }

  factory RechargeResult.failure({
    required String message,
    String? transactionId,
    Map<String, dynamic>? rawResponse,
  }) {
    return RechargeResult(
      isSuccess: false,
      transactionId: transactionId ?? 'FAILED-${DateTime.now().millisecondsSinceEpoch}',
      message: message,
      rawResponse: rawResponse,
    );
  }
}
