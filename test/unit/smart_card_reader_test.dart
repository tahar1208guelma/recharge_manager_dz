import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/smart_card/platforms/mock_smart_card_service.dart';
import 'package:recharge_manager_dz/services/smart_card/platforms/windows_pcsc_service.dart';
import 'package:recharge_manager_dz/services/smart_card/reader_device_info.dart';
import 'package:recharge_manager_dz/services/smart_card/reader_discovery.dart';
import 'package:recharge_manager_dz/services/smart_card/smart_card_protocol.dart';
import 'package:recharge_manager_dz/services/smart_card/smart_card_state.dart';

void main() {
  group('ReaderDiscovery & Device Information Tests', () {
    test('Should identify known ACS smart card reader from name', () {
      final dev = ReaderDiscovery.inspectReader('ACS ACR39U CCID Smart Card Reader (072F:2200)');
      expect(dev.vendorId, '072F');
      expect(dev.productId, '2200');
      expect(dev.manufacturer, contains('Advanced Card Systems'));
      expect(dev.formattedVendorId, '0x072F');
      expect(dev.formattedProductId, '0x2200');
      expect(dev.isCompatible, true);
      expect(dev.connectionStatus, 'CONNECTED');
    });

    test('Should identify known Omnikey smart card reader from name', () {
      final dev = ReaderDiscovery.inspectReader('HID Global OMNIKEY 3x21 Smart Card Reader (076B:3021)');
      expect(dev.vendorId, '076B');
      expect(dev.productId, '3021');
      expect(dev.manufacturer, contains('HID Global'));
      expect(dev.isCompatible, true);
    });

    test('Should detect and flag incompatible USB device (e.g. Flash Drive)', () {
      final badDev = ReaderDiscovery.inspectReader('Generic USB Mass Storage Flash Drive');
      expect(badDev.isCompatible, false);
      expect(badDev.connectionStatus, 'INCOMPATIBLE');
      expect(badDev.errorMessage, contains('Mass Storage'));
    });
  });

  group('MockSmartCardService Lifecycle & State Machine Tests', () {
    late MockSmartCardService smartCardService;

    setUp(() {
      smartCardService = MockSmartCardService();
    });

    tearDown(() {
      smartCardService.dispose();
    });

    test('Initial state should be Card Waiting with connected reader', () async {
      await smartCardService.initialize();
      expect(smartCardService.currentState.status, SmartCardConnectionStatus.cardWaiting);
      expect(smartCardService.currentState.isReaderConnected, true);
      expect(smartCardService.currentState.isWaitingForCard, true);
      expect(smartCardService.currentState.hasCard, false);
    });

    test('List readers returns available hardware readers with VID/PID', () async {
      final readers = await smartCardService.listReaders();
      expect(readers.isNotEmpty, true);
      expect(readers.first.readerName, contains('OMNIKEY'));
      expect(readers.first.formattedVendorId, '0x076B');
    });

    test('Simulate inserting Mobilis SIM card transitions to Card Detected (🔵)', () async {
      await smartCardService.insertSimCard(OperatorType.mobilis);
      expect(smartCardService.currentState.status, SmartCardConnectionStatus.cardDetected);
      expect(smartCardService.currentState.hasCard, true);
      expect(smartCardService.currentState.detectedOperator, OperatorType.mobilis);
      expect(smartCardService.currentState.cardInfo?.imsi, '603010198765432');
      expect(smartCardService.currentState.cardInfo?.iccid, '89213010012345678901');
      expect(smartCardService.currentState.cardInfo?.msisdn, '0661123456');
    });

    test('Simulate inserting Djezzy SIM card transitions to Card Detected (🔵)', () async {
      await smartCardService.insertSimCard(OperatorType.djezzy);
      expect(smartCardService.currentState.status, SmartCardConnectionStatus.cardDetected);
      expect(smartCardService.currentState.detectedOperator, OperatorType.djezzy);
      expect(smartCardService.currentState.cardInfo?.imsi, '603020987654321');
      expect(smartCardService.currentState.cardInfo?.msisdn, '0770987654');
    });

    test('Simulate inserting Ooredoo SIM card transitions to Card Detected (🔵)', () async {
      await smartCardService.insertSimCard(OperatorType.ooredoo);
      expect(smartCardService.currentState.status, SmartCardConnectionStatus.cardDetected);
      expect(smartCardService.currentState.detectedOperator, OperatorType.ooredoo);
      expect(smartCardService.currentState.cardInfo?.imsi, '603030555432100');
      expect(smartCardService.currentState.cardInfo?.msisdn, '0555432100');
    });

    test('Simulate ejecting SIM transitions back to Card Waiting (🟡)', () async {
      await smartCardService.insertSimCard(OperatorType.mobilis);
      expect(smartCardService.currentState.hasCard, true);

      await smartCardService.removeSimCard();
      expect(smartCardService.currentState.status, SmartCardConnectionStatus.cardWaiting);
      expect(smartCardService.currentState.hasCard, false);
      expect(smartCardService.currentState.cardInfo, isNull);
    });

    test('Simulate hardware error transitions to Reader Error (🔴)', () {
      smartCardService.simulateError('USB CCID transmission error 0x80100016');
      expect(smartCardService.currentState.status, SmartCardConnectionStatus.readerError);
      expect(smartCardService.currentState.hasError, true);
      expect(smartCardService.currentState.errorMessage, contains('0x80100016'));
    });

    test('Simulate incompatible reader transitions to Reader Error with message', () {
      smartCardService.simulateIncompatibleReader();
      expect(smartCardService.currentState.status, SmartCardConnectionStatus.readerError);
      expect(smartCardService.currentState.errorMessage, isNotNull);
    });

    test('Simulate typed error states (noReader, noCard, cardMuted, pinLocked, protocolError)', () {
      smartCardService.simulateNoReader();
      expect(smartCardService.currentState.isNoReader, true);
      expect(smartCardService.currentState.errorCode, SmartCardErrorCode.noReader);

      smartCardService.simulateNoCard();
      expect(smartCardService.currentState.isNoCard, true);
      expect(smartCardService.currentState.errorCode, SmartCardErrorCode.noCard);

      smartCardService.simulateCardMuted();
      expect(smartCardService.currentState.isCardMuted, true);
      expect(smartCardService.currentState.errorCode, SmartCardErrorCode.cardMuted);

      smartCardService.simulatePinLocked();
      expect(smartCardService.currentState.isPinLocked, true);
      expect(smartCardService.currentState.errorCode, SmartCardErrorCode.pinLocked);

      smartCardService.simulateProtocolError();
      expect(smartCardService.currentState.isProtocolError, true);
      expect(smartCardService.currentState.errorCode, SmartCardErrorCode.protocolError);
    });

    test('Active CardConnection transmits ISO 7816-4 APDUs', () async {
      await smartCardService.insertSimCard(OperatorType.mobilis);
      final conn = smartCardService.activeConnection;
      expect(conn, isNotNull);
      expect(conn!.isConnected, true);

      final resp = await conn.selectFile(SmartCardProtocol.efIccid);
      expect(resp.isSuccess, true);
      expect(resp.statusWordHex, '9000');
    });
  });

  group('WindowsPcscService Tests', () {
    test('WindowsPcscService initializes and handles reader enumeration without fake data', () async {
      final pcsc = WindowsPcscService();
      await pcsc.initialize();
      final readers = await pcsc.listReaders();
      expect(readers, isA<List<ReaderDeviceInfo>>());
      if (readers.isEmpty) {
        expect(pcsc.currentState.errorCode, SmartCardErrorCode.noReader);
        expect(await pcsc.isCardPresent(), false);
        expect(await pcsc.getCardInfo(), isNull);
      } else {
        expect(readers.first.protocol, 'PC/SC (CCID)');
      }
      pcsc.dispose();
    });

    test('WindowsPcscService exposes typed error states when hardware is missing', () async {
      final pcsc = WindowsPcscService();
      await pcsc.initialize();
      if ((await pcsc.listReaders()).isEmpty) {
        expect(pcsc.currentState.isNoReader, true);
        expect(pcsc.currentState.formattedErrorMessage, contains('noReader'));
      }
      pcsc.dispose();
    });
  });
}
