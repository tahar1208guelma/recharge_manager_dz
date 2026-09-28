import 'dart:async';
import 'dart:io';
import '../core/utils/app_logger.dart';
import 'drivers/generic_at_modem_driver.dart';
import 'drivers/huawei_driver.dart';
import 'drivers/mock_modem_driver.dart';
import 'drivers/modem_driver.dart';
import 'drivers/zte_driver.dart';
import 'hardware_detector.dart';
import 'models/at_command.dart';
import 'models/at_response.dart';
import 'models/hardware_device_type.dart';
import 'models/serial_port_info.dart';
import 'models/unsolicited_response.dart';

class ModemService {
  final IModemDriver? _injectedDriver;
  IModemDriver _driver;
  SerialPortInfo? _activeDevice;
  final _connectionStateController = StreamController<bool>.broadcast();
  bool isSimulationMode;

  ModemService({IModemDriver? driver, this.isSimulationMode = false})
      : _injectedDriver = driver,
        _driver = driver ?? (isSimulationMode ? MockModemDriver() : GenericAtModemDriver());

  IModemDriver get driver => _driver;
  bool get isConnected => _driver.isConnected;
  SerialPortInfo? get activeDevice => _activeDevice;
  String? get activePort => _driver.activePort;
  int get activeBaudRate => _driver.activeBaudRate;

  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<UnsolicitedResponse> get unsolicitedEvents => _driver.unsolicitedEvents;

  /// Scans for all connected serial and smart card devices
  Future<List<SerialPortInfo>> scanDevices() async {
    return await HardwareDetector.scanAttachedDevices(allowMock: isSimulationMode);
  }

  /// Connects to a specific serial port, auto-selecting appropriate driver
  Future<bool> connect(SerialPortInfo device, {int? baudRate}) async {
    AppLogger.info('ModemService: Connecting to ${device.portName} (${device.friendlyName})...');

    if (_injectedDriver != null) {
      _driver = _injectedDriver;
    } else if (isSimulationMode && (device.deviceType == HardwareDeviceType.mockDevice || !Platform.isWindows)) {
      _driver = MockModemDriver();
    } else if (device.friendlyName.toLowerCase().contains('huawei')) {
      _driver = HuaweiDriver();
    } else if (device.friendlyName.toLowerCase().contains('zte')) {
      _driver = ZteDriver();
    } else {
      _driver = GenericAtModemDriver();
    }

    final success = await _driver.connect(
      device.portName,
      baudRate: baudRate ?? 115200,
    );

    if (success) {
      _activeDevice = device;
      _connectionStateController.add(true);
      AppLogger.info('ModemService: Successfully connected to ${device.portName}');
    } else {
      _activeDevice = null;
      _connectionStateController.add(false);
      AppLogger.warn('ModemService: Failed to connect to ${device.portName}');
    }

    return success;
  }

  /// Disconnects from current port
  Future<void> disconnect() async {
    await _driver.disconnect();
    _activeDevice = null;
    _connectionStateController.add(false);
  }

  /// Executes an AT command through the active driver
  Future<AtResponse> executeCommand(AtCommand command) {
    return _driver.executeCommand(command);
  }

  /// Sends raw AT command string
  Future<AtResponse> sendRaw(String command, {Duration timeout = const Duration(seconds: 5)}) {
    return _driver.sendRaw(command, timeout: timeout);
  }

  /// Injects a mock driver for unit testing
  void setDriver(IModemDriver driver) {
    _driver.dispose();
    _driver = driver;
  }

  void dispose() {
    _connectionStateController.close();
    _driver.dispose();
  }
}
