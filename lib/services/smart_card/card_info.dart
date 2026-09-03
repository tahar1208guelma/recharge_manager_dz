import '../../core/constants/operator_constants.dart';

class CardInfo {
  final String? atr; // Answer-To-Reset hex string
  final List<int>? rawAtrBytes;
  final String? iccid; // Integrated Circuit Card ID (2FE2)
  final String? imsi; // International Mobile Subscriber Identity (6F07)
  final OperatorType operator;
  final String? msisdn; // Phone number from public EF_MSISDN (6F40)
  final String protocolUsed; // "T=0", "T=1", "RAW"
  final DateTime readAt;

  CardInfo({
    this.atr,
    this.rawAtrBytes,
    this.iccid,
    this.imsi,
    required this.operator,
    this.msisdn,
    this.protocolUsed = 'T=0',
    DateTime? readAt,
  }) : readAt = readAt ?? DateTime.now();

  factory CardInfo.fromPublicData({
    String? atr,
    List<int>? rawAtrBytes,
    String? iccid,
    String? imsi,
    String? msisdn,
    String protocolUsed = 'T=0',
  }) {
    OperatorType detected = OperatorType.unknown;
    if (imsi != null && imsi.isNotEmpty) {
      detected = OperatorConstants.detectFromImsi(imsi);
    } else if (msisdn != null && msisdn.isNotEmpty) {
      detected = OperatorConstants.detectFromPhoneNumber(msisdn);
    }

    return CardInfo(
      atr: atr,
      rawAtrBytes: rawAtrBytes,
      iccid: iccid,
      imsi: imsi,
      operator: detected,
      msisdn: msisdn,
      protocolUsed: protocolUsed,
      readAt: DateTime.now(),
    );
  }

  CardInfo copyWith({
    String? atr,
    List<int>? rawAtrBytes,
    String? iccid,
    String? imsi,
    OperatorType? operator,
    String? msisdn,
    String? protocolUsed,
    DateTime? readAt,
  }) {
    return CardInfo(
      atr: atr ?? this.atr,
      rawAtrBytes: rawAtrBytes ?? this.rawAtrBytes,
      iccid: iccid ?? this.iccid,
      imsi: imsi ?? this.imsi,
      operator: operator ?? this.operator,
      msisdn: msisdn ?? this.msisdn,
      protocolUsed: protocolUsed ?? this.protocolUsed,
      readAt: readAt ?? this.readAt,
    );
  }
}
