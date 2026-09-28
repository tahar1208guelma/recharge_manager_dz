import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/modem/drivers/generic_at_modem_driver.dart';
import 'package:recharge_manager_dz/modem/models/at_command.dart';
import 'package:recharge_manager_dz/modem/models/unsolicited_response.dart';
import 'package:recharge_manager_dz/modem/native/windows_serial_port.dart';

class FakeSerialPort implements ISerialPort {
  bool _open = false;
  String? _port;
  int _baud = 115200;

  final Map<String, String> commandResponses = {};
  final List<String> commandHistory = [];

  @override
  bool get isOpen => _open;

  @override
  String? get portName => _port;

  @override
  int get baudRate => _baud;

  @override
  bool open(String portName, {int baudRate = 115200}) {
    _open = true;
    _port = portName;
    _baud = baudRate;
    return true;
  }

  @override
  void close() {
    _open = false;
    _port = null;
  }

  @override
  bool write(String text) => true;

  @override
  List<int> readChunk({int maxBytes = 256}) => [];

  @override
  Future<String> sendCommand(String command, {Duration timeout = const Duration(seconds: 5)}) async {
    if (!_open) return 'ERR: Port not open';
    final trimmed = command.trim();
    commandHistory.add(trimmed);
    if (commandResponses.containsKey(trimmed)) {
      return commandResponses[trimmed]!;
    }
    return 'OK\r\n';
  }
}

void main() {
  group('GenericAtModemDriver Unit Tests with Scripted Serial Port', () {
    late FakeSerialPort fakePort;
    late GenericAtModemDriver driver;

    setUp(() {
      fakePort = FakeSerialPort();
      driver = GenericAtModemDriver(serialPort: fakePort);
    });

    tearDown(() async {
      await driver.disconnect();
    });

    test('Should successfully connect and initialize modem with AT and ATE0', () async {
      fakePort.commandResponses['AT'] = 'OK\r\n';
      fakePort.commandResponses['ATE0'] = 'OK\r\n';

      final success = await driver.connect('COM3', baudRate: 115200);
      expect(success, true);
      expect(driver.isConnected, true);
      expect(driver.activePort, 'COM3');
      expect(fakePort.commandHistory.contains('AT'), true);
      expect(fakePort.commandHistory.contains('ATE0'), true);
    });

    test('Should execute command and parse successful AT response', () async {
      await driver.connect('COM3');
      fakePort.commandResponses['AT+CPIN?'] = '+CPIN: READY\r\n\r\nOK\r\n';

      final resp = await driver.executeCommand(AtCommand(command: 'AT+CPIN?'));
      expect(resp.isSuccess, true);
      expect(resp.rawOutput.contains('+CPIN: READY'), true);
    });

    test('Should parse unsolicited events (+CUSD: 1 prompt)', () async {
      await driver.connect('COM3');
      fakePort.commandResponses['AT+CUSD=1,"*630#",15'] =
          '+CUSD: 1,"1: Solde\n2: Flexy",15\r\n\r\nOK\r\n';

      final eventFuture = driver.unsolicitedEvents.firstWhere(
        (ev) => ev.type == UnsolicitedType.ussdPrompt,
      );

      await driver.executeCommand(AtCommand(command: 'AT+CUSD=1,"*630#",15'));
      final ev = await eventFuture.timeout(const Duration(seconds: 2));

      expect(ev.type, UnsolicitedType.ussdPrompt);
      expect(ev.rawLine.contains('+CUSD: 1'), true);
    });

    test('Should emit noCarrier on connection loss / port failure', () async {
      await driver.connect('COM3');
      fakePort.close(); // Abruptly disconnects COM port

      final disconnectEventFuture = driver.unsolicitedEvents.firstWhere(
        (ev) => ev.type == UnsolicitedType.noCarrier,
      );

      final resp = await driver.executeCommand(AtCommand(command: 'AT+CSQ'));
      expect(resp.isSuccess, false);
      expect(driver.isConnected, false);

      final ev = await disconnectEventFuture.timeout(const Duration(seconds: 2));
      expect(ev.type, UnsolicitedType.noCarrier);
    });
  });
}
