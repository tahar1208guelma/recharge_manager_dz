import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/smart_card/smart_card_protocol.dart';
import 'package:recharge_manager_dz/services/smart_card/smart_card_state.dart';
import 'package:recharge_manager_dz/services/usb/mock_usb_reader_service.dart';

void main() {
  group('Smart Card Protocol APDU Encoding & BCD Decoding Tests', () {
    test('Should build valid ISO 7816-4 Select File APDU', () {
      final apdu = SmartCardProtocol.buildSelectFileApdu([0x2F, 0xE2]);
      expect(apdu, [0x00, 0xA4, 0x00, 0x00, 0x02, 0x2F, 0xE2]);
    });

    test('Should parse APDU response status words', () {
      final successResp = SmartCardProtocol.parseApduResponse([0x01, 0x02, 0x90, 0x00]);
      expect(successResp.isSuccess, true);
      expect(successResp.sw1, 0x90);
      expect(successResp.sw2, 0x00);
      expect(successResp.statusWordHex, '9000');
    });

    test('Should decode BCD encoded IMSI correctly', () {
      // Byte 0: 0x08 (length), Byte 1: 0x69 (6), Byte 2: 0x30 (0,3), Byte 3: 0x10 (0,1) -> 60301...
      final raw = [0x08, 0x69, 0x30, 0x10, 0x90, 0x78, 0x56, 0x34, 0x12];
      final decoded = SmartCardProtocol.decodeBcdImsi(raw);
      expect(decoded.startsWith('60301'), true);
    });
  });

  group('Mock USB Reader Service State Machine Tests', () {
    late MockUsbReaderService usbService;

    setUp(() {
      usbService = MockUsbReaderService();
    });

    tearDown(() {
      usbService.dispose();
    });

    test('Initial state is connected', () {
      expect(usbService.currentState.isReaderConnected, true);
      expect(usbService.currentState.hasCard, false);
    });

    test('Simulate inserting Mobilis SIM card updates state and operator', () async {
      await usbService.insertSimCard(OperatorType.mobilis);
      expect(usbService.currentState.status, SmartCardConnectionStatus.cardDetected);
      expect(usbService.currentState.hasCard, true);
      expect(usbService.currentState.cardInfo?.operator, OperatorType.mobilis);
      expect(usbService.currentState.cardInfo?.msisdn, '0661123456');
    });

    test('Simulate ejecting SIM card resets card state', () async {
      await usbService.insertSimCard(OperatorType.djezzy);
      expect(usbService.currentState.hasCard, true);

      await usbService.removeSimCard();
      expect(usbService.currentState.hasCard, false);
      expect(usbService.currentState.status, SmartCardConnectionStatus.cardWaiting);
    });
  });
}
