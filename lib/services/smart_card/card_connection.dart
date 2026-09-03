import 'smart_card_protocol.dart';

abstract class CardConnection {
  String get readerName;
  String get protocol; // "T=0" or "T=1"
  String? get atr;
  bool get isConnected;

  /// Transmit raw APDU command bytes and receive response APDU with SW1 SW2
  Future<SmartCardResponse> transmit(List<int> apdu);

  /// Standard ISO 7816-4 SELECT FILE command
  Future<SmartCardResponse> selectFile(List<int> fileId, {bool isGsm = false});

  /// Standard ISO 7816-4 READ BINARY command
  Future<SmartCardResponse> readBinary(int offset, int length, {bool isGsm = false});

  /// Standard ISO 7816-4 GET RESPONSE command (for T=0 Le handling)
  Future<SmartCardResponse> getResponse(int length, {bool isGsm = false});

  /// Disconnect from card
  Future<void> disconnect({bool resetCard = false});
}
