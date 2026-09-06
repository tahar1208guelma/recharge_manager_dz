enum UnsolicitedType {
  ussdPrompt, // +CUSD: 1, ...
  ussdTerminated, // +CUSD: 0, ... or +CUSD: 2
  smsNotification, // +CMTI: ...
  smsDirect, // +CMT: ...
  networkRegistration, // +CREG: ...
  ring, // RING
  noCarrier, // NO CARRIER
  other,
}

class UnsolicitedResponse {
  final UnsolicitedType type;
  final String rawLine;
  final String? payload;
  final DateTime timestamp;

  UnsolicitedResponse({
    required this.type,
    required this.rawLine,
    this.payload,
  }) : timestamp = DateTime.now();

  factory UnsolicitedResponse.parse(String line) {
    final clean = line.trim();

    if (clean.startsWith('+CUSD:')) {
      final isPrompt = clean.contains('+CUSD: 1') || clean.contains('+CUSD:1');
      return UnsolicitedResponse(
        type: isPrompt ? UnsolicitedType.ussdPrompt : UnsolicitedType.ussdTerminated,
        rawLine: clean,
        payload: clean,
      );
    } else if (clean.startsWith('+CMTI:')) {
      return UnsolicitedResponse(
        type: UnsolicitedType.smsNotification,
        rawLine: clean,
        payload: clean.substring(6).trim(),
      );
    } else if (clean.startsWith('+CMT:')) {
      return UnsolicitedResponse(
        type: UnsolicitedType.smsDirect,
        rawLine: clean,
        payload: clean,
      );
    } else if (clean.startsWith('+CREG:')) {
      return UnsolicitedResponse(
        type: UnsolicitedType.networkRegistration,
        rawLine: clean,
        payload: clean.substring(6).trim(),
      );
    } else if (clean == 'RING') {
      return UnsolicitedResponse(
        type: UnsolicitedType.ring,
        rawLine: clean,
      );
    }

    return UnsolicitedResponse(
      type: UnsolicitedType.other,
      rawLine: clean,
      payload: clean,
    );
  }
}
