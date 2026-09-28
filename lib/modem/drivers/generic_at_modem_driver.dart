import 'dart:async';
import 'dart:io';
import '../../core/utils/app_logger.dart';
import '../models/at_command.dart';
import '../models/at_response.dart';
import '../models/unsolicited_response.dart';
import '../native/windows_serial_port.dart';
import 'modem_driver.dart';

class GenericAtModemDriver implements IModemDriver {
  String? _activePort;
  int _activeBaudRate = 115200;
  bool _isConnected = false;

  final ISerialPort _serialPort;
  final _unsolicitedController = StreamController<UnsolicitedResponse>.broadcast();

  GenericAtModemDriver({ISerialPort? serialPort})
      : _serialPort = serialPort ?? WindowsSerialPort();

  @override
  String get driverName => 'Generic AT Modem Driver (3GPP TS 27.007)';

  @override
  bool get isConnected => _isConnected && (_serialPort is! WindowsSerialPort || !Platform.isWindows || _serialPort.isOpen);

  @override
  String? get activePort => _activePort;

  @override
  int get activeBaudRate => _activeBaudRate;

  @override
  Stream<UnsolicitedResponse> get unsolicitedEvents => _unsolicitedController.stream;

  @override
  Future<bool> connect(String portName, {int baudRate = 115200}) async {
    AppLogger.info('GenericAtModemDriver: Connecting to $portName at $baudRate bps...');
    _activePort = portName.toUpperCase();
    _activeBaudRate = baudRate;

    if (!Platform.isWindows && _serialPort is WindowsSerialPort) {
      _isConnected = true;
      return true;
    }

    // 1. Try opening port with requested baud rate
    bool opened = _serialPort.open(portName, baudRate: baudRate);
    if (opened) {
      final ping = await sendRaw('AT', timeout: const Duration(seconds: 2));
      if (ping.isSuccess) {
        _isConnected = true;
        await sendRaw('ATE0', timeout: const Duration(seconds: 1));
        return true;
      }
    }

    // 2. Auto-baud probe across standard baud rates (115200, 57600, 38400, 9600)
    final detectedBaud = await probeBaudRate(portName);
    if (detectedBaud != null) {
      _activeBaudRate = detectedBaud;
      _isConnected = true;
      await sendRaw('ATE0', timeout: const Duration(seconds: 1));
      return true;
    }

    _serialPort.close();
    _isConnected = false;
    return false;
  }

  @override
  Future<void> disconnect() async {
    AppLogger.info('GenericAtModemDriver: Disconnecting from $_activePort...');
    _serialPort.close();
    _isConnected = false;
    _activePort = null;
  }

  @override
  Future<int?> probeBaudRate(String portName, {List<int> baudRates = const [115200, 57600, 38400, 19200, 9600]}) async {
    for (final rate in baudRates) {
      try {
        _serialPort.close();
        final ok = _serialPort.open(portName, baudRate: rate);
        if (ok) {
          final ping = await _serialPort.sendCommand('AT', timeout: const Duration(milliseconds: 1500));
          if (ping.contains('OK')) {
            AppLogger.info('GenericAtModemDriver: Successfully probed $portName at $rate bps');
            return rate;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<AtResponse> sendRaw(String commandString, {Duration timeout = const Duration(seconds: 5)}) {
    return executeCommand(AtCommand(command: commandString, timeout: timeout));
  }

  @override
  Future<AtResponse> executeCommand(AtCommand command) async {
    final port = _activePort;
    if (port == null || (!Platform.isWindows && _serialPort is WindowsSerialPort)) {
      return AtResponse.fromRaw('OK', const Duration(milliseconds: 50));
    }

    final stopwatch = Stopwatch()..start();
    for (int attempt = 1; attempt <= command.retries; attempt++) {
      try {
        final raw = await _serialPort.sendCommand(
          command.command,
          timeout: command.timeout,
        );
        stopwatch.stop();

        // Check if device was disconnected or write failed
        if (raw.contains('ERR: Port not open') || raw.contains('ERR: Write failed')) {
          _isConnected = false;
          _serialPort.close();
          _unsolicitedController.add(UnsolicitedResponse(
            type: UnsolicitedType.noCarrier,
            rawLine: '+DISCONNECTED: Port connection lost',
          ));
          return AtResponse.fromRaw('ERROR\r\nConnection lost', stopwatch.elapsed);
        }

        final response = AtResponse.fromRaw(raw, stopwatch.elapsed);

        // Check for unsolicited lines inside the buffer (+CUSD:, +CMTI:, etc.)
        for (final line in response.lines) {
          if (line.startsWith('+CUSD:') || line.startsWith('+CMTI:') || line.startsWith('+CREG:')) {
            _unsolicitedController.add(UnsolicitedResponse.parse(line));
          }
        }

        if (response.isSuccess || attempt == command.retries) {
          return response;
        }

        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        if (attempt == command.retries) {
          return AtResponse.fromRaw('ERROR\r\n$e', stopwatch.elapsed);
        }
      }
    }

    return AtResponse.fromRaw('ERROR\r\nTimeout', stopwatch.elapsed);
  }

  @override
  void dispose() {
    _serialPort.close();
    _unsolicitedController.close();
  }
}
