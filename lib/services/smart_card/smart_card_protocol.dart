class SmartCardProtocol {
  // ISO 7816-4 Standard Class & Instructions
  static const int claIso = 0x00;
  static const int claGsm = 0xA0;
  static const int insSelect = 0xA4;
  static const int insReadBinary = 0xB0;
  static const int insGetResponse = 0xC0;
  static const int insVerify = 0x20;

  // Standard Dedicated & Master Files
  static const List<int> mfMaster = [0x3F, 0x00];  // Master File (Root)
  static const List<int> dfGsm = [0x7F, 0x20];     // Dedicated File GSM (DF_GSM)
  static const List<int> dfTelecom = [0x7F, 0x10]; // Dedicated File Telecom (DF_TELECOM)

  // Standard Public Elementary File (EF) IDs
  static const List<int> efIccid = [0x2F, 0xE2]; // Public Serial / ICCID
  static const List<int> efDir = [0x2F, 0x00];   // Application Directory
  static const List<int> efImsi = [0x6F, 0x07];  // Public IMSI (under 7F20 / GSM DF)
  static const List<int> efMsisdn = [0x6F, 0x40];// Public Own Number (under 7F10 / Telecom DF)

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

  /// Builds a standard ISO 7816-4 GET RESPONSE APDU command (T=0)
  static List<int> buildGetResponseApdu(int length, {bool isGsm = false}) {
    return [
      isGsm ? claGsm : claIso,
      insGetResponse,
      0x00,
      0x00,
      length & 0xFF,
    ];
  }

  /// Builds a standard ISO 7816-4 / GSM 11.11 VERIFY CHV1 / PIN1 APDU command
  /// PIN is padded with 0xFF to 8 bytes.
  static List<int> buildVerifyPinApdu(String pin, {bool isGsm = false}) {
    final pinBytes = pin.codeUnits.take(8).toList();
    while (pinBytes.length < 8) {
      pinBytes.add(0xFF);
    }
    return [
      isGsm ? claGsm : claIso,
      insVerify,
      0x00,
      0x01, // P2: CHV1 (PIN 1)
      0x08, // Lc: 8 bytes
      ...pinBytes,
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

    final isSuccess = (sw1 == 0x90 && sw2 == 0x00) || (sw1 == 0x91);

    return SmartCardResponse(
      data: data,
      sw1: sw1,
      sw2: sw2,
      isSuccess: isSuccess,
    );
  }

  /// Decodes generic BCD nibbles
  static String decodeBcd(List<int> rawBytes) => decodeBcdIccid(rawBytes);

  /// Decodes BCD-encoded (Binary Coded Decimal) ICCID from raw bytes (10 bytes with swapped nibbles)
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

  /// Decodes BCD-encoded IMSI from raw bytes (GSM 11.11 / 3GPP TS 51.011 / TS 31.102)
  /// Byte 0: length of subsequent bytes
  /// Byte 1: parity in low nibble, first digit in high nibble
  /// Bytes 2..N: low nibble then high nibble
  static String decodeBcdImsi(List<int> rawBytes) {
    if (rawBytes.length < 2) return '';
    final buffer = StringBuffer();
    final length = rawBytes[0];
    final totalLen = (length > 0 && length < rawBytes.length) ? (length + 1) : rawBytes.length;

    // First digit is in high nibble of byte 1
    final firstDigit = (rawBytes[1] >> 4) & 0x0F;
    if (firstDigit <= 9) buffer.write(firstDigit);

    // Remaining digits: low nibble, then high nibble
    for (int i = 2; i < totalLen; i++) {
      final byte = rawBytes[i];
      final lowNibble = byte & 0x0F;
      final highNibble = (byte >> 4) & 0x0F;
      if (lowNibble <= 9) buffer.write(lowNibble);
      if (highNibble <= 9) buffer.write(highNibble);
    }
    return buffer.toString();
  }

  /// Decodes MSISDN from raw record bytes (EF_MSISDN under 7F10)
  /// Returns null if not present or unconfigured (0xFF)
  static String? decodeMsisdn(List<int> rawBytes) {
    if (rawBytes.isEmpty || rawBytes.every((b) => b == 0xFF)) return null;

    int lengthIndex = -1;
    // Standard 3GPP TS 51.011 EF_MSISDN linear fixed record:
    // Alpha (X-14 bytes), Length (1 byte at X-14), TON/NPI (1 byte at X-13), BCD (10 bytes), Cap (1 byte), Ext (1 byte)
    if (rawBytes.length >= 14) {
      final candidate = rawBytes.length - 14;
      final len = rawBytes[candidate];
      if (len > 0 && len <= 11 && len <= (rawBytes.length - candidate - 1)) {
        lengthIndex = candidate;
      }
    }

    // Check if rawBytes starts directly with length byte (e.g. stripped record)
    if (lengthIndex == -1) {
      final len = rawBytes[0];
      if (len > 0 && len <= 11 && len <= rawBytes.length - 1) {
        lengthIndex = 0;
      }
    }

    // Search for first byte matching valid BCD length (1..11) followed by valid TON/NPI byte
    if (lengthIndex == -1) {
      for (int i = 0; i < rawBytes.length - 2; i++) {
        final len = rawBytes[i];
        final ton = rawBytes[i + 1];
        if (len > 0 && len <= 11 && (i + len < rawBytes.length) && (ton & 0x80) != 0) {
          lengthIndex = i;
          break;
        }
      }
    }

    if (lengthIndex == -1) return null;

    final bcdLength = rawBytes[lengthIndex];
    if (bcdLength == 0 || bcdLength == 0xFF || bcdLength > (rawBytes.length - lengthIndex - 1)) {
      return null;
    }

    final tonNpi = rawBytes[lengthIndex + 1];
    final isInternational = (tonNpi & 0x70) == 0x10;
    final buffer = StringBuffer(isInternational ? '+' : '');

    for (int i = lengthIndex + 2; i <= lengthIndex + bcdLength; i++) {
      if (i >= rawBytes.length) break;
      final byte = rawBytes[i];
      final low = byte & 0x0F;
      final high = (byte >> 4) & 0x0F;
      if (low <= 9) buffer.write(low);
      if (high <= 9) buffer.write(high);
    }

    final number = buffer.toString();
    return number.isNotEmpty && number != '+' ? number : null;
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

  /// Normal OK status (90 00 or 91 xx)
  bool get isOk => (sw1 == 0x90 && sw2 == 0x00) || (sw1 == 0x91);

  /// T=0: SW1 == 0x61 means sw2 bytes are available to be fetched via GET RESPONSE
  bool get hasMoreData => sw1 == 0x61;
  int get moreDataLength => sw2;

  /// T=0: SW1 == 0x6C means wrong Le length, resend with Le = sw2
  bool get isWrongLength => sw1 == 0x6C;
  int get correctLength => sw2;

  /// Class not supported (6E 00) - signal to fallback from CLA A0 to CLA 00
  bool get isClassNotSupported => sw1 == 0x6E && sw2 == 0x00;

  /// Instruction not supported (6D 00)
  bool get isInstructionNotSupported => sw1 == 0x6D && sw2 == 0x00;

  /// PIN required / Security status not satisfied (69 82 or 98 04)
  bool get isPinRequired => (sw1 == 0x69 && sw2 == 0x82) || (sw1 == 0x98 && sw2 == 0x04);

  /// PIN verify failed (63 Cx) where x is the remaining attempts count
  bool get isPinFailed => sw1 == 0x63 && (sw2 & 0xF0) == 0xC0;

  /// Remaining PIN attempts if PIN failed
  int? get remainingPinAttempts => isPinFailed ? (sw2 & 0x0F) : null;

  String get statusWordHex =>
      '${sw1.toRadixString(16).padLeft(2, '0').toUpperCase()}${sw2.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}
