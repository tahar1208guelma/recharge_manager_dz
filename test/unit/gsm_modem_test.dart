import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/services/ussd/gsm_modem_service.dart';

void main() {
  group('GSM Modem & UCS2 Decoder Unit Tests', () {
    test('Should decode Arabic UCS2 hexadecimal string accurately', () {
      // "تم" -> U+062A (ت), U+0645 (م) -> 062A0645
      const hex = '062A0645';
      final decoded = GsmModemService.decodeUcs2Hex(hex);
      expect(decoded, 'تم');
    });

    test('Should decode French/Latin UCS2 hex string accurately', () {
      // "OK" -> U+004F (O), U+004B (K) -> 004F004B
      const hex = '004F004B';
      final decoded = GsmModemService.decodeUcs2Hex(hex);
      expect(decoded, 'OK');
    });

    test('Should pass through standard plain text without modification', () {
      const text = 'Solde: 5000 DA';
      final decoded = GsmModemService.decodeUcs2Hex(text);
      expect(decoded, text);
    });

    test('HardwarePortInfo should format string correctly', () {
      final info = HardwarePortInfo(
        portName: 'COM4',
        friendlyName: 'HUAWEI Mobile Connect - 3G PC UI Interface (COM4)',
        isModem: true,
      );
      expect(info.portName, 'COM4');
      expect(info.isModem, true);
      expect(info.toString(), 'HUAWEI Mobile Connect - 3G PC UI Interface (COM4)');
    });

    test('GsmModemService should parse simulation responses correctly', () async {
      final modem = GsmModemService();
      
      // Mobilis Flexy
      final mobResp = await modem.sendUssd('*630*0661123456*04*500*11111#');
      expect(mobResp.isSuccess, true);
      expect(mobResp.isSessionOpen, true);
      expect(mobResp.cleanMessage.contains('تأكيد'), true);

      // Reply 1 (Confirm)
      final replyResp = await modem.sendUssd('1');
      expect(replyResp.isSuccess, true);
      expect(replyResp.isSessionOpen, false);
      expect(replyResp.cleanMessage.contains('بنجاح'), true);
    });
  });
}
