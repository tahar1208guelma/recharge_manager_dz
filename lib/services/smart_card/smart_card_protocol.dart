class SmartCardProtocol {
  // ISO 7816-4 Standard Class & Instructions
  static const int claIso = 0x00;
  static const int claGsm = 0xA0;
  static const int insSelect = 0xA4;
  static const int insReadBinary = 0xB0;
  static const int insGetResponse = 0xC0;

  // Standard Dedicated & Master Files
  static const List<int> mfMaster = [0x3F, 0x00];  // Master File (Root)
  static const List<int> dfGsm = [0x7F, 0x20];     // Dedicated File GSM (DF_GSM)
  static const List<int> dfTelecom = [0x7F, 0x10]; // Dedicated File Telecom (DF_TELECOM)

  // Standard Public Elementary File (EF) IDs
  static const List<int> efIccid = [0x2F, 0xE2]; // Public Serial / ICCID
  static const List<int> efDir = [0x2F, 0x00];   // Application Directory
  static const List<int> efImsi = [0x6F, 0x07];  // Public IMSI (under 7F20 / GSM DF)
  static const List<int> efMsisdn = [0x6F, 0x40];// Public Own Number (if configured)

  /// Builds a standard ISO 7816-4 SELECT FILE APDU command
  static List<int> buildSelectFileApdu(List<int> fileId, {bool isGsm = false}) {
    return [
      isGsm ? claGsm : claIso,
      insSelect,
      0x00, // P1: Select by ID
      0x00, // P2: First or only occurrence
      fileId.length, // Lc
      ...fileId,
    ];
  }

  /// Builds a standard ISO 7816-4 READ BINARY APDU command
  static List<int> buildReadBinaryApdu(int offset, int length, {bool isGsm = false}) {
    return [
      isGsm ? claGsm : claIso,
      insReadBinary,
      (offset >> 8) & 0xFF, // P1: High offset
      offset & 0xFF,        // P2: Low offset
      length,               // Le: Expected length
    ];
  }

  /// Parses an APDU response into Status Word (SW1, SW2) and data payload
  static SmartCardResponse parseApduResponse(List<int> responseBytes) {
    if (responseBytes.length < 2) {
      return SmartCardResponse(data: [], sw1: 0, sw2: 0, isSuccess: false);
    }

    final sw1 = responseBytes[responseBytes.length - 2];
    final sw2 = responseBytes[responseBytes.length - 1];
    final data = responseBytes.sublist(0, responseBytes.length - 2);

    final isSuccess = (sw1 == 0x90 && sw2 == 0x00) || (sw1 == 0x91) || (sw1 == 0x61);

    return SmartCardResponse(
      data: data,
      sw1: sw1,
      sw2: sw2,
      isSuccess: isSuccess,
    );
  }

  /// Decodes generic BCD nibbles
  static String decodeBcd(List<int> rawBytes) => decodeBcdIccid(rawBytes);

  /// Decodes BCD-encoded (Binary Coded Decimal) ICCID from raw bytes
  static String decodeBcdIccid(List<int> rawBytes) {
    final buffer = StringBuffer();
    for (final byte in rawBytes) {
      final lowNibble = byte & 0x0F;
      final highNibble = (byte >> 4) & 0x0F;
      if (lowNibble <= 9) buffer.write(lowNibble);
      if (highNibble <= 9) buffer.write(highNibble);
    }
    return buffer.toString();
  }

  /// Decodes BCD-encoded IMSI from raw bytes (GSM 11.11 / 3GPP TS 51.011)
  static String decodeBcdImsi(List<int> rawBytes) {
    if (rawBytes.isEmpty) return '';
    final buffer = StringBuffer();
    int startIndex = 0;

    // Check if byte 0 is length prefix
    if (rawBytes.length > 1 && rawBytes[0] <= rawBytes.length - 1) {
      final firstByte = rawBytes[1];
      final firstDigit = (firstByte >> 4) & 0x0F;
      if (firstDigit <= 9) buffer.write(firstDigit);
      startIndex = 2;
    }

    for (int i = startIndex; i < rawBytes.length; i++) {
      final byte = rawBytes[i];
      final lowNibble = byte & 0x0F;
      final highNibble = (byte >> 4) & 0x0F;
      if (lowNibble <= 9) buffer.write(lowNibble);
      if (highNibble <= 9) buffer.write(highNibble);
    }
    return buffer.toString();
  }
}

class SmartCardResponse {
  final List<int> data;
  final int sw1;
  final int sw2;
  final bool isSuccess;

  SmartCardResponse({
    required this.data,
    required this.sw1,
    required this.sw2,
    required this.isSuccess,
  });

  String get statusWordHex =>
      '${sw1.toRadixString(16).padLeft(2, '0').toUpperCase()}${sw2.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}
