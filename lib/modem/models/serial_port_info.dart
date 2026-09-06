import 'hardware_device_type.dart';

class SerialPortInfo {
  final String portName; // e.g. COM4
  final String friendlyName; // e.g. HUAWEI Mobile Connect - 3G PC UI Interface (COM4)
  final String description;
  final String? manufacturer;
  final String? hardwareId;
  final String? vid;
  final String? pid;
  final HardwareDeviceType deviceType;
  final bool isAvailable;

  const SerialPortInfo({
    required this.portName,
    required this.friendlyName,
    this.description = '',
    this.manufacturer,
    this.hardwareId,
    this.vid,
    this.pid,
    this.deviceType = HardwareDeviceType.gsmModem,
    this.isAvailable = true,
  });

  factory SerialPortInfo.fromPnp({
    required String portName,
    required String name,
    String description = '',
    String? manufacturer,
    String? pnpClass,
    String? hardwareId,
  }) {
    final lowerName = name.toLowerCase();
    final lowerDesc = description.toLowerCase();
    final lowerClass = (pnpClass ?? '').toLowerCase();

    // Extract VID & PID if present in hardwareId (e.g. USB\VID_12D1&PID_1001)
    String? vid;
    String? pid;
    if (hardwareId != null) {
      final vidMatch = RegExp(r'VID_([0-9A-Fa-f]{4})', caseSensitive: false).firstMatch(hardwareId);
      final pidMatch = RegExp(r'PID_([0-9A-Fa-f]{4})', caseSensitive: false).firstMatch(hardwareId);
      vid = vidMatch?.group(1)?.toUpperCase();
      pid = pidMatch?.group(1)?.toUpperCase();
    }

    HardwareDeviceType type = HardwareDeviceType.unknown;
    if (lowerClass == 'smartcardreader' || lowerName.contains('smart card') || lowerDesc.contains('smart card') || lowerName.contains('acr38') || lowerName.contains('acr39') || lowerName.contains('omnikey')) {
      type = HardwareDeviceType.smartCardReader;
    } else if (lowerClass == 'modem' || lowerName.contains('modem') || lowerDesc.contains('modem') || lowerName.contains('huawei') || lowerName.contains('zte') || lowerName.contains('pc ui') || lowerName.contains('3g') || lowerName.contains('4g') || lowerName.contains('simcom') || lowerName.contains('quectel')) {
      type = HardwareDeviceType.gsmModem;
    } else if (lowerName.contains('ch340') || lowerName.contains('ftdi') || lowerName.contains('prolific') || lowerName.contains('pl2303') || lowerName.contains('cp210') || lowerName.contains('serial')) {
      type = HardwareDeviceType.usbSerialAdapter;
    } else {
      type = HardwareDeviceType.gsmModem; // Default serial port
    }

    return SerialPortInfo(
      portName: portName.toUpperCase(),
      friendlyName: name,
      description: description,
      manufacturer: manufacturer,
      hardwareId: hardwareId,
      vid: vid,
      pid: pid,
      deviceType: type,
    );
  }

  @override
  String toString() => friendlyName.isNotEmpty ? friendlyName : portName;
}
