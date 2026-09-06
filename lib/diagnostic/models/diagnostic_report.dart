import 'dart:convert';

class UsbDeviceInfo {
  final String name;
  final String? vid;
  final String? pid;
  final String? manufacturer;
  final String? product;
  final String? serialNumber;
  final String? hardwareId;
  final String? deviceClass;

  const UsbDeviceInfo({
    required this.name,
    this.vid,
    this.pid,
    this.manufacturer,
    this.product,
    this.serialNumber,
    this.hardwareId,
    this.deviceClass,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'vid': vid ?? 'N/A',
        'pid': pid ?? 'N/A',
        'manufacturer': manufacturer ?? 'N/A',
        'product': product ?? 'N/A',
        'serial_number': serialNumber ?? 'N/A',
        'hardware_id': hardwareId ?? 'N/A',
        'device_class': deviceClass ?? 'N/A',
      };
}

class AtCommandTestResult {
  final String command;
  final bool isSuccess;
  final String rawOutput;
  final int durationMs;

  const AtCommandTestResult({
    required this.command,
    required this.isSuccess,
    required this.rawOutput,
    required this.durationMs,
  });

  Map<String, dynamic> toMap() => {
        'command': command,
        'is_success': isSuccess,
        'raw_output': rawOutput,
        'duration_ms': durationMs,
      };
}

class ComPortDiagnostic {
  final String portName;
  final String friendlyName;
  final bool isAtResponsive;
  final int? probedBaudRate;
  final List<AtCommandTestResult> commandResults;

  const ComPortDiagnostic({
    required this.portName,
    required this.friendlyName,
    required this.isAtResponsive,
    this.probedBaudRate,
    this.commandResults = const [],
  });

  Map<String, dynamic> toMap() => {
        'port_name': portName,
        'friendly_name': friendlyName,
        'is_at_responsive': isAtResponsive,
        'probed_baud_rate': probedBaudRate,
        'command_results': commandResults.map((c) => c.toMap()).toList(),
      };
}

class CellularDiagnostic {
  final String simStatus; // READY / PIN REQUIRED / NOT PRESENT / UNKNOWN
  final int signalRssi; // 0-31, 99
  final int signalPercent; // 0-100%
  final int? signalDbm;
  final String networkRegistration; // REGISTERED / NOT REGISTERED / ...
  final String? operatorName;
  final String? accessTechnology;
  final String? imsi;
  final String? iccid;

  const CellularDiagnostic({
    required this.simStatus,
    this.signalRssi = 99,
    this.signalPercent = 0,
    this.signalDbm,
    required this.networkRegistration,
    this.operatorName,
    this.accessTechnology,
    this.imsi,
    this.iccid,
  });

  Map<String, dynamic> toMap() => {
        'sim_status': simStatus,
        'signal_rssi': signalRssi,
        'signal_percent': signalPercent,
        'signal_dbm': signalDbm,
        'network_registration': networkRegistration,
        'operator_name': operatorName ?? 'N/A',
        'access_technology': accessTechnology ?? 'N/A',
        'imsi': imsi != null ? '${imsi!.substring(0, 6)}*********' : 'N/A',
        'iccid': iccid != null ? '${iccid!.substring(0, 7)}************' : 'N/A',
      };
}

class DiagnosticVerdict {
  final String deviceType; // PC/SC READER / GSM MODEM / UNKNOWN
  final String pcsc; // SUPPORTED / NOT SUPPORTED
  final String atModem; // SUPPORTED / NOT SUPPORTED
  final String ussd; // SUPPORTED / NOT VERIFIED / NOT SUPPORTED
  final String sms; // SUPPORTED / NOT VERIFIED / NOT SUPPORTED
  final String network; // REGISTERED / NOT REGISTERED
  final String sim; // READY / PIN REQUIRED / NOT PRESENT / UNKNOWN
  final List<String> notes;

  const DiagnosticVerdict({
    required this.deviceType,
    required this.pcsc,
    required this.atModem,
    required this.ussd,
    required this.sms,
    required this.network,
    required this.sim,
    this.notes = const [],
  });

  Map<String, dynamic> toMap() => {
        'DEVICE_TYPE': deviceType,
        'PCSC': pcsc,
        'AT_MODEM': atModem,
        'USSD': ussd,
        'SMS': sms,
        'NETWORK': network,
        'SIM': sim,
        'notes': notes,
      };
}

class DiagnosticReport {
  final DateTime timestamp;
  final String osPlatform;
  final String osVersion;
  final List<UsbDeviceInfo> usbDevices;
  final List<String> pcscReaders;
  final List<ComPortDiagnostic> comPorts;
  final CellularDiagnostic? cellular;
  final DiagnosticVerdict verdict;

  const DiagnosticReport({
    required this.timestamp,
    required this.osPlatform,
    required this.osVersion,
    required this.usbDevices,
    required this.pcscReaders,
    required this.comPorts,
    this.cellular,
    required this.verdict,
  });

  Map<String, dynamic> toMap() => {
        'diagnostic_report': {
          'generated_at': timestamp.toIso8601String(),
          'system_os': osPlatform,
          'os_version': osVersion,
          'verdict': verdict.toMap(),
          'cellular': cellular?.toMap() ?? {},
          'usb_devices': usbDevices.map((d) => d.toMap()).toList(),
          'pcsc_readers': pcscReaders,
          'com_ports': comPorts.map((p) => p.toMap()).toList(),
        }
      };

  String toPrettyJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toMap());
  }

  String toFormattedTextReport() {
    final buffer = StringBuffer();
    const divider = '================================================================================';
    const subDivider = '--------------------------------------------------------------------------------';

    buffer.writeln(divider);
    buffer.writeln('          RECHARGE MANAGER DZ - HARDWARE DIAGNOSTIC REPORT (DZ-POS)            ');
    buffer.writeln('                      Developed by VAST SOLUTIONS DZ                           ');
    buffer.writeln(divider);
    buffer.writeln('Date & Time : ${timestamp.toLocal()}');
    buffer.writeln('Platform    : $osPlatform ($osVersion)');
    buffer.writeln('Scan Mode   : READ-ONLY HARDWARE PROBE (No Recharge / No USSD transactions)');
    buffer.writeln(divider);
    buffer.writeln();

    // 1. EXECUTIVE VERDICT SUMMARY
    buffer.writeln('=========================== [ EXECUTIVE VERDICT ] ===========================');
    buffer.writeln('  DEVICE TYPE : ${verdict.deviceType}');
    buffer.writeln('  PC/SC       : ${verdict.pcsc}');
    buffer.writeln('  AT MODEM    : ${verdict.atModem}');
    buffer.writeln('  USSD        : ${verdict.ussd}');
    buffer.writeln('  SMS         : ${verdict.sms}');
    buffer.writeln('  NETWORK     : ${verdict.network}');
    buffer.writeln('  SIM         : ${verdict.sim}');
    if (verdict.notes.isNotEmpty) {
      buffer.writeln('  NOTES       :');
      for (final n in verdict.notes) {
        buffer.writeln('    • $n');
      }
    }
    buffer.writeln(subDivider);
    buffer.writeln();

    // 2. CELLULAR & SIM METRICS
    if (cellular != null) {
      buffer.writeln('======================= [ CELLULAR & SIM DIAGNOSTICS ] ======================');
      buffer.writeln('  SIM Status           : ${cellular!.simStatus}');
      buffer.writeln('  Signal RSSI          : ${cellular!.signalRssi} / 31 (${cellular!.signalPercent}%) ${cellular!.signalDbm != null ? "${cellular!.signalDbm} dBm" : ""}');
      buffer.writeln('  Network Registration : ${cellular!.networkRegistration}');
      buffer.writeln('  Detected Operator    : ${cellular!.operatorName ?? "N/A"}');
      buffer.writeln('  Access Technology    : ${cellular!.accessTechnology ?? "N/A"}');
      if (cellular!.imsi != null) {
        buffer.writeln('  IMSI (Masked)        : ${cellular!.imsi!.substring(0, 6)}*********');
      }
      if (cellular!.iccid != null) {
        buffer.writeln('  ICCID (Masked)       : ${cellular!.iccid!.substring(0, 7)}************');
      }
      buffer.writeln(subDivider);
      buffer.writeln();
    }

    // 3. PC/SC SMART CARD READERS
    buffer.writeln('========================= [ PC/SC SMART CARD READERS ] =======================');
    if (pcscReaders.isEmpty) {
      buffer.writeln('  No PC/SC Smart Card readers detected.');
    } else {
      for (int i = 0; i < pcscReaders.length; i++) {
        buffer.writeln('  [Reader ${i + 1}] ${pcscReaders[i]}');
      }
    }
    buffer.writeln(subDivider);
    buffer.writeln();

    // 4. USB DEVICES DETECTED
    buffer.writeln('============================ [ USB DEVICES LIST ] ============================');
    if (usbDevices.isEmpty) {
      buffer.writeln('  No USB devices enumerated.');
    } else {
      for (int i = 0; i < usbDevices.length; i++) {
        final d = usbDevices[i];
        buffer.writeln('  Device #${i + 1}: ${d.name}');
        buffer.writeln('    VID: ${d.vid ?? "N/A"}  |  PID: ${d.pid ?? "N/A"}');
        buffer.writeln('    Manufacturer: ${d.manufacturer ?? "N/A"}  |  Product: ${d.product ?? "N/A"}');
        buffer.writeln('    Class: ${d.deviceClass ?? "N/A"}  |  Serial: ${d.serialNumber ?? "N/A"}');
        buffer.writeln('    Hardware ID : ${d.hardwareId ?? "N/A"}');
        buffer.writeln();
      }
    }
    buffer.writeln(subDivider);
    buffer.writeln();

    // 5. AT SERIAL PROBE RESULTS
    buffer.writeln('========================= [ AT PORT PROBE RESULTS ] ==========================');
    if (comPorts.isEmpty) {
      buffer.writeln('  No COM / Serial ports available.');
    } else {
      for (final port in comPorts) {
        buffer.writeln('  Port: ${port.portName} (${port.friendlyName})');
        buffer.writeln('  AT Responsive : ${port.isAtResponsive ? "YES (Baud: ${port.probedBaudRate ?? 115200})" : "NO"}');
        if (port.commandResults.isNotEmpty) {
          buffer.writeln('  Command Tests :');
          for (final cmd in port.commandResults) {
            final statusStr = cmd.isSuccess ? 'OK' : 'ERR/TIMEOUT';
            buffer.writeln('    [${cmd.durationMs}ms] TX: ${cmd.command} --> [$statusStr]');
            final cleanLines = cmd.rawOutput.replaceAll('\r', '').split('\n').where((l) => l.trim().isNotEmpty).toList();
            for (final line in cleanLines) {
              buffer.writeln('      RX: $line');
            }
          }
        }
        buffer.writeln();
      }
    }
    buffer.writeln(divider);
    buffer.writeln('                     End of Diagnostic Report                                 ');
    buffer.writeln(divider);

    return buffer.toString();
  }
}
