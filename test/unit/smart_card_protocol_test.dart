import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/smart_card/smart_card_protocol.dart';

void main() {
  group('SmartCardProtocol BCD Decoding & Helpers', () {
    test('decodeBcdIccid should decode 10-byte swapped nibble BCD correctly', () {
      // 89 21 30 12 34 56 78 90 12 34
      // In BCD bytes (swapped): [0x98, 0x12, 0x03, 0x21, 0x43, 0x65, 0x87, 0x09, 0x21, 0x43]
      final rawIccid = [0x98, 0x12, 0x03, 0x21, 0x43, 0x65, 0x87, 0x09, 0x21, 0x43];
      final iccid = SmartCardProtocol.decodeBcdIccid(rawIccid);
      expect(iccid, '89213012345678901234');
    });

    test('decodeBcdIccid should handle trailing F filler nibbles', () {
      // 19-digit ICCID ending with F: 89 21 30 12 34 56 78 90 12 3F
      final rawIccid = [0x98, 0x12, 0x03, 0x21, 0x43, 0x65, 0x87, 0x09, 0x21, 0xF3];
      final iccid = SmartCardProtocol.decodeBcdIccid(rawIccid);
      expect(iccid, '8921301234567890123');
    });

    test('decodeBcdImsi should decode Mobilis IMSI (60301) according to 3GPP TS 51.011', () {
      // Byte 0: length = 8 bytes
      // Byte 1: parity (low nibble = 9 -> odd=1), digit 1 (high nibble = 6)
      // Byte 2: digit 2 (low nibble = 0), digit 3 (high nibble = 3)
      // Byte 3: digit 4 (low nibble = 0), digit 5 (high nibble = 1) -> 60301
      // Byte 4-8: remaining digits
      final rawMobilis = [0x08, 0x69, 0x30, 0x10, 0x90, 0x78, 0x56, 0x34, 0x12];
      final imsi = SmartCardProtocol.decodeBcdImsi(rawMobilis);
      expect(imsi, '603010987654321');
      expect(OperatorConstants.detectFromImsi(imsi), OperatorType.mobilis);
    });

    test('decodeBcdImsi should decode Djezzy IMSI (60302) correctly', () {
      // Byte 3: digit 4 (low nibble = 0), digit 5 (high nibble = 2) -> 60302
      final rawDjezzy = [0x08, 0x69, 0x30, 0x20, 0x45, 0x67, 0x89, 0x01, 0x23];
      final imsi = SmartCardProtocol.decodeBcdImsi(rawDjezzy);
      expect(imsi.startsWith('60302'), true);
      expect(OperatorConstants.detectFromImsi(imsi), OperatorType.djezzy);
    });

    test('decodeBcdImsi should decode Ooredoo IMSI (60303) correctly', () {
      // Byte 3: digit 4 (low nibble = 0), digit 5 (high nibble = 3) -> 60303
      final rawOoredoo = [0x08, 0x69, 0x30, 0x30, 0x99, 0x88, 0x77, 0x66, 0x55];
      final imsi = SmartCardProtocol.decodeBcdImsi(rawOoredoo);
      expect(imsi.startsWith('60303'), true);
      expect(OperatorConstants.detectFromImsi(imsi), OperatorType.ooredoo);
    });

    test('OperatorConstants.detectFromImsi rejects invalid prefixes', () {
      // Must NOT match 6031, 6032, 6033 - only 60301, 60302, 60303
      expect(OperatorConstants.detectFromImsi('603101234567890'), OperatorType.unknown);
      expect(OperatorConstants.detectFromImsi('603201234567890'), OperatorType.unknown);
      expect(OperatorConstants.detectFromImsi('603301234567890'), OperatorType.unknown);
      expect(OperatorConstants.detectFromImsi(''), OperatorType.unknown);
      expect(OperatorConstants.detectFromImsi('1234567890'), OperatorType.unknown);
    });

    test('decodeMsisdn parses valid EF_MSISDN record', () {
      // Alpha identifier (e.g. 10 bytes FF) + Length (0x07) + TON/NPI (0x81) + BCD number (0661123456)
      final rawMsisdn = [
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // Alpha identifier
        0x07, // Length of BCD number including TON/NPI
        0x81, // TON/NPI (National / Unknown)
        0x60, 0x16, 0x21, 0x43, 0x65, 0xFF, // 0661123456
      ];
      final number = SmartCardProtocol.decodeMsisdn(rawMsisdn);
      expect(number, isNotNull);
      expect(number!.contains('0661123456') || number.contains('661123456'), true);
    });

    test('decodeMsisdn returns null for empty or unprovisioned EF_MSISDN', () {
      final allFF = List.filled(28, 0xFF);
      expect(SmartCardProtocol.decodeMsisdn(allFF), isNull);
      expect(SmartCardProtocol.decodeMsisdn([]), isNull);
    });
  });

  group('APDU Construction & Response Classification', () {
    test('buildSelectFileApdu constructs correct CLA, INS, P1, P2, Lc and data', () {
      final gsmApdu = SmartCardProtocol.buildSelectFileApdu([0x3F, 0x00], isGsm: true);
      expect(gsmApdu, [0xA0, 0xA4, 0x00, 0x00, 0x02, 0x3F, 0x00]);

      final uiccApdu = SmartCardProtocol.buildSelectFileApdu([0x2F, 0xE2], isGsm: false);
      expect(uiccApdu, [0x00, 0xA4, 0x00, 0x00, 0x02, 0x2F, 0xE2]);
    });

    test('buildReadBinaryApdu constructs correct APDU', () {
      final gsmRead = SmartCardProtocol.buildReadBinaryApdu(0, 10, isGsm: true);
      expect(gsmRead, [0xA0, 0xB0, 0x00, 0x00, 0x0A]);

      final uiccRead = SmartCardProtocol.buildReadBinaryApdu(0, 10, isGsm: false);
      expect(uiccRead, [0x00, 0xB0, 0x00, 0x00, 0x0A]);
    });

    test('buildGetResponseApdu constructs correct APDU for T=0 protocol handling', () {
      final gsmGetResp = SmartCardProtocol.buildGetResponseApdu(0x16, isGsm: true);
      expect(gsmGetResp, [0xA0, 0xC0, 0x00, 0x00, 0x16]);

      final uiccGetResp = SmartCardProtocol.buildGetResponseApdu(0x0F, isGsm: false);
      expect(uiccGetResp, [0x00, 0xC0, 0x00, 0x00, 0x0F]);
    });

    test('buildVerifyPinApdu formats 8-byte PIN with FF padding', () {
      final pinApdu = SmartCardProtocol.buildVerifyPinApdu('11111', isGsm: true);
      // '1'=0x31. 5 ones followed by 3 0xFF bytes
      expect(pinApdu, [0xA0, 0x20, 0x00, 0x01, 0x08, 0x31, 0x31, 0x31, 0x31, 0x31, 0xFF, 0xFF, 0xFF]);
    });

    test('SmartCardResponse status words inspection', () {
      final okResp = SmartCardResponse(sw1: 0x90, sw2: 0x00, data: [], isSuccess: true);
      expect(okResp.isOk, true);

      final moreDataResp = SmartCardResponse(sw1: 0x61, sw2: 0x15, data: [], isSuccess: false);
      expect(moreDataResp.hasMoreData, true);
      expect(moreDataResp.moreDataLength, 0x15);

      final wrongLenResp = SmartCardResponse(sw1: 0x6C, sw2: 0x0A, data: [], isSuccess: false);
      expect(wrongLenResp.isWrongLength, true);
      expect(wrongLenResp.correctLength, 0x0A);

      final pinReqResp1 = SmartCardResponse(sw1: 0x69, sw2: 0x82, data: [], isSuccess: false);
      expect(pinReqResp1.isPinRequired, true);

      final pinReqResp2 = SmartCardResponse(sw1: 0x98, sw2: 0x04, data: [], isSuccess: false);
      expect(pinReqResp2.isPinRequired, true);

      final pinFailResp = SmartCardResponse(sw1: 0x63, sw2: 0xC2, data: [], isSuccess: false);
      expect(pinFailResp.isPinFailed, true);
      expect(pinFailResp.remainingPinAttempts, 2);

      final classNotSupported = SmartCardResponse(sw1: 0x6E, sw2: 0x00, data: [], isSuccess: false);
      expect(classNotSupported.isClassNotSupported, true);

      final insNotSupported = SmartCardResponse(sw1: 0x6D, sw2: 0x00, data: [], isSuccess: false);
      expect(insNotSupported.isInstructionNotSupported, true);
    });
  });
}
