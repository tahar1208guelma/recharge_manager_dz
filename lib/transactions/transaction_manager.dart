import 'dart:async';
import '../core/constants/operator_constants.dart';
import '../core/utils/app_logger.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class PosTransaction {
  final String transactionId;
  final String? receiptNumber;
  final OperatorType operator;
  final String phoneNumber;
  final double amount;
  final String? serviceName;
  final PosTransactionStatus status;
  final String? networkReference;
  final String? responseMessage;
  final String? errorMessage;
  final DateTime startTime;
  final DateTime? endTime;

  PosTransaction({
    required this.transactionId,
    this.receiptNumber,
    required this.operator,
    required this.phoneNumber,
    required this.amount,
    this.serviceName = 'تعبئة رصيد (Recharge)',
    this.status = PosTransactionStatus.pending,
    this.networkReference,
    this.responseMessage,
    this.errorMessage,
    required this.startTime,
    this.endTime,
  });

  PosTransaction copyWith({
    PosTransactionStatus? status,
    String? networkReference,
    String? responseMessage,
    String? errorMessage,
    DateTime? endTime,
  }) {
    return PosTransaction(
      transactionId: transactionId,
      receiptNumber: receiptNumber,
      operator: operator,
      phoneNumber: phoneNumber,
      amount: amount,
      serviceName: serviceName,
      status: status ?? this.status,
      networkReference: networkReference ?? this.networkReference,
      responseMessage: responseMessage ?? this.responseMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_number': transactionId,
      'receipt_number': receiptNumber ?? 'REC-${startTime.millisecondsSinceEpoch.toString().substring(6)}',
      'operator': operator.name,
      'phone_number': phoneNumber,
      'amount': amount,
      'service_name': serviceName,
      'status': status.name,
      'network_reference': networkReference,
      'response_message': responseMessage,
      'error_message': errorMessage,
      'created_at': startTime.toIso8601String(),
      'completed_at': endTime?.toIso8601String(),
    };
  }
}

class TransactionManager {
  final List<PosTransaction> _transactions = [];
  final List<TransactionEvent> _events = [];
  final _transactionStreamController = StreamController<PosTransaction>.broadcast();

  List<PosTransaction> get transactions => List.unmodifiable(_transactions);
  List<TransactionEvent> get events => List.unmodifiable(_events);
  Stream<PosTransaction> get transactionStream => _transactionStreamController.stream;

  /// Creates and starts a new transaction, validating against rapid duplicate requests
  PosTransaction createTransaction({
    required OperatorType operator,
    required String phoneNumber,
    required double amount,
    String serviceName = 'تعبئة رصيد (Recharge)',
  }) {
    // 1. Check duplicate protection (same phone + same amount within 45s)
    final recentDuplicate = _transactions.where((t) {
      final isSamePhone = t.phoneNumber == phoneNumber;
      final isSameAmount = (t.amount - amount).abs() < 0.01;
      final isRecent = DateTime.now().difference(t.startTime).inSeconds < 45;
      final isPendingOrUnknown = t.status == PosTransactionStatus.pending || t.status == PosTransactionStatus.unknown;
      return isSamePhone && isSameAmount && isRecent && isPendingOrUnknown;
    }).toList();

    if (recentDuplicate.isNotEmpty) {
      AppLogger.warn('TransactionManager: Blocked duplicate attempt for $phoneNumber ($amount DA)');
      throw StateError('توجد عملية قيد التنفيذ أو غير مؤكدة لنفس الرقم والمبلغ خلال آخر 45 ثانية. يرجى التحقق من رصيد الشريحة أولاً لمنع الخصم المزدوج.');
    }

    final txId = 'TX-${DateTime.now().millisecondsSinceEpoch}';
    final recNum = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    final tx = PosTransaction(
      transactionId: txId,
      receiptNumber: recNum,
      operator: operator,
      phoneNumber: phoneNumber,
      amount: amount,
      serviceName: serviceName,
      status: PosTransactionStatus.pending,
      startTime: DateTime.now(),
    );

    _transactions.insert(0, tx);
    _recordEvent(txId, 'CREATED', 'تم بدء المعاملة بمبلغ $amount دج للرقم $phoneNumber');
    _transactionStreamController.add(tx);

    return tx;
  }

  /// Marks transaction as SUCCESS with network confirmation reference
  void markSuccess(String transactionId, {String? reference, String? responseMessage}) {
    final idx = _transactions.indexWhere((t) => t.transactionId == transactionId);
    if (idx != -1) {
      final updated = _transactions[idx].copyWith(
        status: PosTransactionStatus.success,
        networkReference: reference,
        responseMessage: responseMessage,
        endTime: DateTime.now(),
      );
      _transactions[idx] = updated;
      _recordEvent(transactionId, 'SUCCESS', 'تم تأكيد المعاملة بنجاح من الشبكة. المرجع: $reference', rawData: responseMessage);
      _transactionStreamController.add(updated);
    }
  }

  /// Marks transaction as FAILED when explicitly rejected by network
  void markFailed(String transactionId, {String? error}) {
    final idx = _transactions.indexWhere((t) => t.transactionId == transactionId);
    if (idx != -1) {
      final updated = _transactions[idx].copyWith(
        status: PosTransactionStatus.failed,
        errorMessage: error,
        endTime: DateTime.now(),
      );
      _transactions[idx] = updated;
      _recordEvent(transactionId, 'FAILED', 'فشلت المعاملة: $error', rawData: error);
      _transactionStreamController.add(updated);
    }
  }

  /// Marks transaction as UNKNOWN on timeout to prevent blind double-charging
  void markUnknownTimeout(String transactionId, {String? details}) {
    final idx = _transactions.indexWhere((t) => t.transactionId == transactionId);
    if (idx != -1) {
      final updated = _transactions[idx].copyWith(
        status: PosTransactionStatus.unknown,
        errorMessage: 'انتهت المهلة دون تأكيد نهائي من الشبكة. يجب فحص رصيد الشريحة قبل إعادة المحاولة.',
        endTime: DateTime.now(),
      );
      _transactions[idx] = updated;
      _recordEvent(transactionId, 'UNKNOWN_TIMEOUT', 'انقطاع أو مهلة غير مؤكدة', rawData: details);
      _transactionStreamController.add(updated);
    }
  }

  /// Marks transaction as CANCELLED by seller
  void markCancelled(String transactionId) {
    final idx = _transactions.indexWhere((t) => t.transactionId == transactionId);
    if (idx != -1) {
      final updated = _transactions[idx].copyWith(
        status: PosTransactionStatus.cancelled,
        endTime: DateTime.now(),
      );
      _transactions[idx] = updated;
      _recordEvent(transactionId, 'CANCELLED', 'تم إلغاء المعاملة من قبل البائع');
      _transactionStreamController.add(updated);
    }
  }

  void _recordEvent(String transactionId, String eventType, String description, {String? rawData}) {
    final event = TransactionEvent(
      transactionId: transactionId,
      eventType: eventType,
      description: description,
      rawData: rawData,
    );
    _events.insert(0, event);
  }

  void dispose() {
    _transactionStreamController.close();
  }
}
