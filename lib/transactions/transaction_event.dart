class TransactionEvent {
  final int? id;
  final String transactionId;
  final String eventType; // e.g. "CREATED", "USSD_SENT", "MENU_CLICKED", "TIMEOUT", "CONFIRMED"
  final String description;
  final String? rawData;
  final DateTime timestamp;

  TransactionEvent({
    this.id,
    required this.transactionId,
    required this.eventType,
    required this.description,
    this.rawData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'event_type': eventType,
      'description': description,
      'raw_data': rawData,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionEvent.fromMap(Map<String, dynamic> map) {
    return TransactionEvent(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as String,
      eventType: map['event_type'] as String,
      description: map['description'] as String,
      rawData: map['raw_data'] as String?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
