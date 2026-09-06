import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/modem/drivers/huawei_driver.dart';
import 'package:recharge_manager_dz/modem/drivers/mock_modem_driver.dart';
import 'package:recharge_manager_dz/modem/drivers/quectel_driver.dart';
import 'package:recharge_manager_dz/modem/drivers/simcom_driver.dart';
import 'package:recharge_manager_dz/modem/drivers/zte_driver.dart';
import 'package:recharge_manager_dz/modem/models/at_command.dart';
import 'package:recharge_manager_dz/modem/models/unsolicited_response.dart';

void main() {
  group('Modem Drivers Unit Tests', () {
    late MockModemDriver mockDriver;

    setUp(() {
      mockDriver = MockModemDriver();
    });

    tearDown(() {
      mockDriver.dispose();
    });

    test('MockModemDriver should connect and disconnect properly', () async {
      expect(mockDriver.isConnected, false);
      final connected = await mockDriver.connect('COM3', baudRate: 115200);
      expect(connected, true);
      expect(mockDriver.isConnected, true);
      expect(mockDriver.activePort, 'COM3');
      expect(mockDriver.activeBaudRate, 115200);

      await mockDriver.disconnect();
      expect(mockDriver.isConnected, false);
      expect(mockDriver.activePort, isNull);
    });

    test('MockModemDriver should answer AT ping and SIM queries', () async {
      await mockDriver.connect('COM4');

      final atResp = await mockDriver.executeCommand(AtCommand(command: 'AT'));
      expect(atResp.isSuccess, true);

      final cpinResp = await mockDriver.executeCommand(AtCommand(command: 'AT+CPIN?'));
      expect(cpinResp.isSuccess, true);
      expect(cpinResp.rawOutput.contains('READY'), true);

      final csqResp = await mockDriver.executeCommand(AtCommand(command: 'AT+CSQ'));
      expect(csqResp.isSuccess, true);
      expect(csqResp.rawOutput.contains('+CSQ: 25,99'), true);

      final cimiResp = await mockDriver.executeCommand(AtCommand(command: 'AT+CIMI'));
      expect(cimiResp.isSuccess, true);
      expect(cimiResp.rawOutput.contains('603011234567890'), true);
    });

    test('MockModemDriver should emit unsolicited response on USSD execution', () async {
      await mockDriver.connect('COM4');

      final futureEvent = mockDriver.unsolicitedEvents.firstWhere(
        (e) => e.type == UnsolicitedType.ussdPrompt,
      );

      final ussdResp = await mockDriver.executeCommand(
        AtCommand(command: 'AT+CUSD=1,"*630*0661123456*04*500*11111#",15'),
      );
      expect(ussdResp.isSuccess, true);

      final event = await futureEvent;
      expect(event.type, UnsolicitedType.ussdPrompt);
      expect(event.rawLine.contains('Confirmer') || event.rawLine.contains('transferer'), true);
    });

    test('MockModemDriver should return SMS list in text mode', () async {
      await mockDriver.connect('COM4');
      final smsResp = await mockDriver.executeCommand(AtCommand(command: 'AT+CMGL="ALL"'));
      expect(smsResp.isSuccess, true);
      expect(smsResp.rawOutput.contains('Votre solde Flexy a ete credite'), true);
    });

    test('Specific OEM modem drivers should instantiate with proper driver names', () {
      final huawei = HuaweiDriver();
      final zte = ZteDriver();
      final simcom = SimComDriver();
      final quectel = QuectelDriver();

      expect(huawei.driverName.contains('Huawei'), true);
      expect(zte.driverName.contains('ZTE'), true);
      expect(simcom.driverName.contains('SIMCom'), true);
      expect(quectel.driverName.contains('Quectel'), true);
    });
  });
}
