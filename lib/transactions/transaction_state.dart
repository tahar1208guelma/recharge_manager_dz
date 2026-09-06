enum PosTransactionStatus {
  pending, // Transaction started, waiting for network response
  success, // Confirmed by network with reference ID
  failed, // Rejected or error returned by network
  timeout, // Response timed out
  unknown, // Ambiguous state (timeout or connection lost before final confirmation)
  cancelled, // Cancelled by seller
}

extension PosTransactionStatusExtension on PosTransactionStatus {
  String get displayNameAr {
    switch (this) {
      case PosTransactionStatus.success:
        return 'ناجحة (مؤكدة)';
      case PosTransactionStatus.failed:
        return 'فاشلة (مرفوضة)';
      case PosTransactionStatus.pending:
        return 'قيد المعالجة...';
      case PosTransactionStatus.timeout:
        return 'انتهت المهلة';
      case PosTransactionStatus.unknown:
        return 'غير مؤكدة (تحتاج مراجعة الرصيد)';
      case PosTransactionStatus.cancelled:
        return 'ملغاة من البائع';
    }
  }

  bool get isFinal => this == PosTransactionStatus.success || this == PosTransactionStatus.failed || this == PosTransactionStatus.cancelled;
}
