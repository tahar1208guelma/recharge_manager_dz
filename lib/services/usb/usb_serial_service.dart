import 'dart:async';
import 'dart:io';
import '../../core/utils/app_logger.dart';
import '../../modem/native/windows_serial_port.dart';

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
  final WindowsSerialPort _serialPort = WindowsSerialPort();

  @override
  Stream<String> get serialDataStream => _controller.stream;

  @override
  bool get isConnected => _serialPort.isOpen;

  @override
  String? get currentPort => _serialPort.portName;

  @override
  Future<List<String>> listAvailablePorts() async {
    return WindowsSerialPort.listComPorts();
  }

  @override
  Future<bool> openPort(String portName, {int baudRate = 115200}) async {
    if (!Platform.isWindows) {
      AppLogger.warn('DefaultUsbSerialService: Serial hardware communication only supported on Windows');
      return false;
    }
    final opened = _serialPort.open(portName, baudRate: baudRate);
    if (opened) {
      _controller.add('PORT_OPENED: $portName');
    }
    return opened;
  }

  @override
  Future<void> closePort() async {
    if (_serialPort.isOpen) {
      final port = _serialPort.portName;
      _serialPort.close();
      _controller.add('PORT_CLOSED: $port');
    }
  }

  @override
  Future<String?> sendAtCommand(String command, {Duration timeout = const Duration(seconds: 5)}) async {
    if (!_serialPort.isOpen) return null;
    return await _serialPort.sendCommand(command, timeout: timeout);
  }

  @override
  void dispose() {
    closePort();
    _controller.close();
  }
}
