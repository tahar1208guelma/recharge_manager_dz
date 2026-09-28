import 'dart:convert';
import 'dart:io';
import '../core/utils/app_logger.dart';
import 'models/hardware_device_type.dart';
import 'models/serial_port_info.dart';

class HardwareDetector {
  /// Scans Windows for all attached serial hardware and smart card devices
  static Future<List<SerialPortInfo>> scanAttachedDevices({bool allowMock = false}) async {
    if (!Platform.isWindows) {
      if (allowMock) {
        return [
          const SerialPortInfo(
            portName: 'MOCK_MODEM',
            friendlyName: 'محاكي مودم الاتصالات (Mock GSM Modem Simulator)',
            description: 'Software Simulation Modem for POS Testing',
            deviceType: HardwareDeviceType.mockDevice,
          ),
        ];
      }
      return [];
    }

    final portsMap = <String, SerialPortInfo>{};

    try {
      // 1. Scan Win32_PnPEntity with HardwareID and PNPClass
      const scriptPnp = """
Get-CimInstance Win32_PnPEntity | Where-Object { 
  \$_.PNPClass -in @('Modem', 'Ports', 'SmartCardReader') -or 
  \$_.Name -match '\\(COM\\d+\\)' -or 
  \$_.Name -match 'Smart|Card|ACR|Omnikey|Huawei|ZTE|SIMCOM|Quectel'
} | Select-Object Name, Caption, Description, Manufacturer, DeviceID, PNPClass, HardWareID | ConvertTo-Json -Compress
""";

      final resPnp = await Process.run('powershell', ['-NoProfile', '-Command', scriptPnp]);

      if (resPnp.exitCode == 0 && resPnp.stdout != null) {
        final out = resPnp.stdout.toString().trim();
        if (out.isNotEmpty) {
          try {
            dynamic parsed = jsonDecode(out);
            List<dynamic> items = parsed is List ? parsed : [parsed];
            for (final item in items) {
              final name = (item['Name'] ?? item['Caption'] ?? '').toString();
              final desc = (item['Description'] ?? '').toString();
              final mfg = (item['Manufacturer'] ?? '').toString();
              final pnpClass = (item['PNPClass'] ?? '').toString();
              final hwIds = item['HardWareID'];
              String? hwIdStr;
              if (hwIds is List && hwIds.isNotEmpty) {
                hwIdStr = hwIds.first.toString();
              } else if (hwIds != null) {
                hwIdStr = hwIds.toString();
              }

              final comMatch = RegExp(r'\((COM\d+)\)', caseSensitive: false).firstMatch(name);
              if (comMatch != null) {
                final comPort = comMatch.group(1)!.toUpperCase();
                portsMap[comPort] = SerialPortInfo.fromPnp(
                  portName: comPort,
                  name: name,
                  description: desc,
                  manufacturer: mfg,
                  pnpClass: pnpClass,
                  hardwareId: hwIdStr,
                );
              } else if (pnpClass.toLowerCase() == 'smartcardreader' || name.toLowerCase().contains('smart card')) {
                // PC/SC Reader without COM port
                final readerKey = 'PCSC_${name.hashCode.abs()}';
                portsMap[readerKey] = SerialPortInfo(
                  portName: readerKey,
                  friendlyName: name,
                  description: desc,
                  manufacturer: mfg,
                  deviceType: HardwareDeviceType.smartCardReader,
                );
              }
            }
          } catch (e) {
            AppLogger.warn('HardwareDetector PNP JSON parse error: $e');
          }
        }
      }

      // 2. Win32_SerialPort fallback
      const scriptSerial = "Get-CimInstance Win32_SerialPort | Select-Object DeviceID, Name, Description, ProviderType | ConvertTo-Json -Compress";
      final resSerial = await Process.run('powershell', ['-NoProfile', '-Command', scriptSerial]);
      if (resSerial.exitCode == 0 && resSerial.stdout != null) {
        final out = resSerial.stdout.toString().trim();
        if (out.isNotEmpty) {
          try {
            dynamic parsed = jsonDecode(out);
            List<dynamic> items = parsed is List ? parsed : [parsed];
            for (final item in items) {
              final id = (item['DeviceID'] ?? '').toString().toUpperCase();
              final name = (item['Name'] ?? id).toString();
              final desc = (item['Description'] ?? '').toString();
              if (id.isNotEmpty && !portsMap.containsKey(id)) {
                portsMap[id] = SerialPortInfo(
                  portName: id,
                  friendlyName: name,
                  description: desc,
                  deviceType: HardwareDeviceType.gsmModem,
                );
              }
            }
          } catch (_) {}
        }
      }

      // 3. Fallback to [System.IO.Ports.SerialPort]::GetPortNames()
      const scriptNames = "[System.IO.Ports.SerialPort]::GetPortNames()";
      final resNames = await Process.run('powershell', ['-NoProfile', '-Command', scriptNames]);
      if (resNames.exitCode == 0 && resNames.stdout != null) {
        final lines = LineSplitter.split(resNames.stdout.toString());
        for (final line in lines) {
          final p = line.trim().toUpperCase();
          if (p.isNotEmpty && !portsMap.containsKey(p)) {
            portsMap[p] = SerialPortInfo(
              portName: p,
              friendlyName: 'منفذ تسلسلي ($p)',
              deviceType: HardwareDeviceType.gsmModem,
            );
          }
        }
      }
    } catch (e) {
      AppLogger.warn('HardwareDetector scan error: $e');
    }

    if (portsMap.isEmpty && allowMock) {
      return [
        const SerialPortInfo(
          portName: 'MOCK_MODEM',
          friendlyName: 'محاكي مودم الاتصالات (Mock GSM Modem Simulator)',
          description: 'Software Simulation Modem for POS Testing',
          deviceType: HardwareDeviceType.mockDevice,
        ),
      ];
    }

    return portsMap.values.toList();
  }
}
