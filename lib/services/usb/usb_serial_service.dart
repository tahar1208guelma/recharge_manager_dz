import 'dart:async';
import '../../core/utils/app_logger.dart';

abstract class UsbSerialService {
  Stream<String> get serialDataStream;
  bool get isConnected;
  String? get currentPort;

  Future<List<String>> listAvailablePorts();
  Future<bool> openPort(String portName, {int baudRate = 115200});
  Future<void> closePort();
  Future<String?> sendAtCommand(String command, {Duration timeout = const Duration(seconds: 5)});

  void dispose();
}

class DefaultUsbSerialService implements UsbSerialService {
  final _controller = StreamController<String>.broadcast();
  bool _isConnected = false;
  String? _currentPort;

  @override
  Stream<String> get serialDataStream => _controller.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  String? get currentPort => _currentPort;

  @override
  Future<List<String>> listAvailablePorts() async {
    // In production on Windows, queries Win32 SetupAPI / registry for COM ports
    AppLogger.info('Scanning for USB Serial COM ports...');
    return ['COM1 (System)', 'COM3 (USB Serial Dongle)'];
  }

  @override
  Future<bool> openPort(String portName, {int baudRate = 115200}) async {
    AppLogger.info('Opening USB Serial port $portName at $baudRate baud...');
    _currentPort = portName;
    _isConnected = true;
    _controller.add('PORT_OPENED: $portName');
    return true;
  }

  @override
  Future<void> closePort() async {
    if (_isConnected) {
      AppLogger.info('Closing USB Serial port $_currentPort');
      _isConnected = false;
      _currentPort = null;
      _controller.add('PORT_CLOSED');
    }
  }

  @override
  Future<String?> sendAtCommand(String command, {Duration timeout = const Duration(seconds: 5)}) async {
    if (!_isConnected) return null;
    AppLogger.debug('USB Serial TX -> $command');
    // Simulated AT response for official modems
    if (command.startsWith('AT+CIMI')) {
      return '603010123456789\r\nOK';
    } else if (command.startsWith('AT+CSQ')) {
      return '+CSQ: 24,99\r\nOK';
    }
    return 'OK';
  }

  @override
  void dispose() {
    closePort();
    _controller.close();
  }
}
