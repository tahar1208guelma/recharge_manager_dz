import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/services/smart_card/platforms/windows_pcsc_service.dart';
import 'package:recharge_manager_dz/services/smart_card/smart_card_protocol.dart';

void main() {
  group('WindowsPcscCardConnection Scripted Transport Tests', () {
    test('Should handle ISO 7816-4 T=0 SW1=0x61 by issuing GET RESPONSE', () async {
      final transmittedApdus = <List<int>>[];

      final conn = WindowsPcscCardConnection(
        readerName: 'Test SmartCard Reader',
        hContext: 1234,
        hCard: 5678,
        activeProtocol: 1, // SCARD_PROTOCOL_T0
        activeCla: SmartCardProtocol.claGsm,
        rawTransmit: ({required int hCard, required int activeProtocol, required List<int> apdu}) {
          transmittedApdus.add(List.from(apdu));

          // First command: SELECT FILE -> returns 61 16 (22 bytes available)
          if (apdu[1] == 0xA4) {
            return {
              'isSuccess': true,
              'sw1': 0x61,
              'sw2': 0x16,
              'data': <int>[],
              'returnCode': 0,
            };
          }

          // Second command: GET RESPONSE (INS = 0xC0) -> returns the requested data + 90 00
          if (apdu[1] == 0xC0) {
            return {
              'isSuccess': true,
              'sw1': 0x90,
              'sw2': 0x00,
              'data': List.filled(0x16, 0xAA),
              'returnCode': 0,
            };
          }

          return {'isSuccess': false, 'sw1': 0x6F, 'sw2': 0x00, 'data': <int>[], 'returnCode': -1};
        },
      );

      final resp = await conn.selectFile([0x2F, 0xE2], isGsm: true);

      // Verify two APDUs were sent: SELECT then GET RESPONSE
      expect(transmittedApdus.length, 2);
      expect(transmittedApdus[0], [0xA0, 0xA4, 0x00, 0x00, 0x02, 0x2F, 0xE2]);
      expect(transmittedApdus[1], [0xA0, 0xC0, 0x00, 0x00, 0x16]);

      // Verify the final response contains the data and 90 00
      expect(resp.isOk, true);
      expect(resp.data.length, 0x16);
      expect(resp.sw1, 0x90);
      expect(resp.sw2, 0x00);
    });

    test('Should handle ISO 7816-4 T=0 SW1=0x6C by resending with corrected Le', () async {
      final transmittedApdus = <List<int>>[];

      final conn = WindowsPcscCardConnection(
        readerName: 'Test SmartCard Reader',
        hContext: 1234,
        hCard: 5678,
        activeProtocol: 1, // SCARD_PROTOCOL_T0
        activeCla: SmartCardProtocol.claGsm,
        rawTransmit: ({required int hCard, required int activeProtocol, required List<int> apdu}) {
          transmittedApdus.add(List.from(apdu));

          // First command: READ BINARY with wrong Le (e.g. 15 bytes) -> returns 6C 0A (10 bytes)
          if (apdu.last == 0x0F) {
            return {
              'isSuccess': false,
              'sw1': 0x6C,
              'sw2': 0x0A,
              'data': <int>[],
              'returnCode': 0,
            };
          }

          // Resent command with corrected Le = 0x0A -> returns 10 bytes + 90 00
          if (apdu.last == 0x0A) {
            return {
              'isSuccess': true,
              'sw1': 0x90,
              'sw2': 0x00,
              'data': List.filled(10, 0x99),
              'returnCode': 0,
            };
          }

          return {'isSuccess': false, 'sw1': 0x6F, 'sw2': 0x00, 'data': <int>[], 'returnCode': -1};
        },
      );

      final resp = await conn.readBinary(0, 15, isGsm: true);

      expect(transmittedApdus.length, 2);
      expect(transmittedApdus[0].last, 0x0F);
      expect(transmittedApdus[1].last, 0x0A);
      expect(resp.isOk, true);
      expect(resp.data.length, 10);
    });

    test('Should detect PIN required when card returns 69 82', () async {
      final conn = WindowsPcscCardConnection(
        readerName: 'Test SmartCard Reader',
        hContext: 1234,
        hCard: 5678,
        activeProtocol: 1,
        activeCla: SmartCardProtocol.claGsm,
        rawTransmit: ({required int hCard, required int activeProtocol, required List<int> apdu}) {
          return {
            'isSuccess': false,
            'sw1': 0x69,
            'sw2': 0x82,
            'data': <int>[],
            'returnCode': 0,
          };
        },
      );

      final resp = await conn.readBinary(0, 9, isGsm: true);
      expect(resp.isPinRequired, true);
      expect(resp.isOk, false);
    });

    test('verifyPin should send padded PIN APDU and return success', () async {
      List<int>? sentVerifyApdu;

      final conn = WindowsPcscCardConnection(
        readerName: 'Test SmartCard Reader',
        hContext: 1234,
        hCard: 5678,
        activeProtocol: 1,
        activeCla: SmartCardProtocol.claGsm,
        rawTransmit: ({required int hCard, required int activeProtocol, required List<int> apdu}) {
          sentVerifyApdu = List.from(apdu);
          return {
            'isSuccess': true,
            'sw1': 0x90,
            'sw2': 0x00,
            'data': <int>[],
            'returnCode': 0,
          };
        },
      );

      final resp = await conn.verifyPin('11111', isGsm: true);
      expect(resp.isOk, true);
      expect(sentVerifyApdu, isNotNull);
      // CLA A0, INS 20, P1 00, P2 01, Lc 08, '11111' in ASCII + 3x 0xFF padding
      expect(sentVerifyApdu!, [0xA0, 0x20, 0x00, 0x01, 0x08, 0x31, 0x31, 0x31, 0x31, 0x31, 0xFF, 0xFF, 0xFF]);
    });

    test('Disconnected connection should immediately return error without transmitting', () async {
      int callCount = 0;
      final conn = WindowsPcscCardConnection(
        readerName: 'Test SmartCard Reader',
        hContext: 0,
        hCard: 0, // Not connected
        activeProtocol: 0,
        rawTransmit: ({required int hCard, required int activeProtocol, required List<int> apdu}) {
          callCount++;
          return {'isSuccess': false, 'sw1': 0x6F, 'sw2': 0x00, 'data': <int>[], 'returnCode': -1};
        },
      );

      expect(conn.isConnected, false);
      final resp = await conn.readBinary(0, 10);
      expect(callCount, 0);
      expect(resp.isOk, false);
      expect(resp.sw1, 0x6F);
    });
  });
}
