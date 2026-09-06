enum SmsType {
  inbox,
  sent,
  draft,
  unsolicitedNotification,
}

class SmsMessage {
  final int? id;
  final int? indexOnSim;
  final String senderOrRecipient;
  final String text;
  final DateTime timestamp;
  final SmsType type;
  final bool isRead;
  final String? rawPdu;

  const SmsMessage({
    this.id,
    this.indexOnSim,
    required this.senderOrRecipient,
    required this.text,
    required this.timestamp,
    this.type = SmsType.inbox,
    this.isRead = true,
    this.rawPdu,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'index_on_sim': indexOnSim,
      'sender_or_recipient': senderOrRecipient,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'is_read': isRead ? 1 : 0,
      'raw_pdu': rawPdu,
    };
  }

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'] as int?,
      indexOnSim: map['index_on_sim'] as int?,
      senderOrRecipient: map['sender_or_recipient'] as String? ?? 'Unknown',
      text: map['text'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      type: SmsType.values.firstWhere((e) => e.name == map['type'], orElse: () => SmsType.inbox),
      isRead: (map['is_read'] as int? ?? 1) == 1,
      rawPdu: map['raw_pdu'] as String?,
    );
  }
}
