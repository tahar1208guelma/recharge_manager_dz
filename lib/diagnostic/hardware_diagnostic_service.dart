import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/utils/app_logger.dart';
import 'models/diagnostic_report.dart';

class HardwareDiagnosticService {
  final bool isSimulation;

  HardwareDiagnosticService({this.isSimulation = false});

  /// Runs a comprehensive, non-destructive hardware diagnostic scan
  Future<DiagnosticReport> runDiagnostic({
    Function(String progressMessage, double percent)? onProgress,
  }) async {
    AppLogger.info('HardwareDiagnosticService: Starting diagnostic scan...');
    onProgress?.call('بدء فحص عتاد النظام والمنافذ...', 0.05);

    final timestamp = DateTime.now();
    final osPlatform = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;

    // 1. Scan USB Devices
    onProgress?.call('جاري استكشاف أجهزة USB و VID/PID...', 0.20);
    final usbDevices = await _scanUsbDevices();

    // 2. Scan PC/SC Smart Card Readers
    onProgress?.call('جاري فحص قارئات البطاقات الذكية (PC/SC Readers)...', 0.40);
    final pcscReaders = await _scanPcscReaders();

    // 3. Scan & Probe COM Ports with safe AT sequence
    onProgress?.call('جاري فحص منافذ COM واختبار أوامر AT...', 0.60);
    final comDiagnostics = await _probeComPorts(onProgress: onProgress);

    // 4. Extract Cellular & SIM Information from AT responses
    onProgress?.call('جاري تحليل حالة الشريحة وقوة الإشارة والشبكة...', 0.85);
    final cellular = _analyzeCellular(comDiagnostics);

    // 5. Build Final Verdict
    onProgress?.call('إعداد التقرير والتقييم النهائي...', 0.95);
    final verdict = _computeVerdict(
      usbDevices: usbDevices,
      pcscReaders: pcscReaders,
      comPorts: comDiagnostics,
      cellular: cellular,
    );

    final report = DiagnosticReport(
      timestamp: timestamp,
      osPlatform: osPlatform,
      osVersion: osVersion,
      usbDevices: usbDevices,
      pcscReaders: pcscReaders,
      comPorts: comDiagnostics,
      cellular: cellular,
      verdict: verdict,
    );

    onProgress?.call('اكتمل التشخيص بنجاح', 1.0);
    AppLogger.info('HardwareDiagnosticService: Scan finished successfully.');
    return report;
  }

  /// Exports diagnostic report to both JSON and TXT files
  Future<Map<String, String>> exportReportFiles(DiagnosticReport report, {String? targetDirectory}) async {
    final now = DateTime.now();
    final filePrefix = 'diag_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    Directory dir;
    if (targetDirectory != null) {
      dir = Directory(targetDirectory);
    } else {
      // Pick Desktop or Home directory
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path;
      final desktopDir = Directory('$home/Desktop');
      if (await desktopDir.exists()) {
        dir = desktopDir;
      } else {
        dir = Directory('$home/RechargeManagerDZ_Reports');
      }
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final jsonPath = '${dir.path}/$filePrefix.json';
    final txtPath = '${dir.path}/$filePrefix.txt';

    final jsonFile = File(jsonPath);
    await jsonFile.writeAsString(report.toPrettyJson());

    final txtFile = File(txtPath);
    await txtFile.writeAsString(report.toFormattedTextReport());

    AppLogger.info('HardwareDiagnosticService: Report files exported to $txtPath and $jsonPath');

    return {
      'json': jsonPath,
      'txt': txtPath,
    };
  }

  // ================= PRIVATE SCAN IMPLEMENTATIONS =================

  Future<List<UsbDeviceInfo>> _scanUsbDevices() async {
    if (isSimulation) {
      return [
        const UsbDeviceInfo(
          name: 'HUAWEI Mobile Connect - 3G Modem Interface',
          vid: '12D1',
          pid: '1001',
          manufacturer: 'Huawei Technologies Co., Ltd.',
          product: 'HUAWEI Mobile',
          serialNumber: '8921301000001234567',
          hardwareId: r'USB\VID_12D1&PID_1001&REV_0000',
          deviceClass: 'Modem',
        ),
        const UsbDeviceInfo(
          name: 'USB Composite Device',
          vid: '12D1',
          pid: '1001',
          manufacturer: 'Standard USB',
          product: 'USB Controller',
          hardwareId: r'USB\VID_12D1&PID_1001',
          deviceClass: 'USB',
        ),
      ];
    }

    final devices = <UsbDeviceInfo>[];

    if (Platform.isWindows) {
      const psScript = """
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Get-CimInstance Win32_PnPEntity | Where-Object { \$_.DeviceID -like 'USB*' } | Select-Object Name, DeviceID, Manufacturer, PNPClass, Service | ConvertTo-Json -Compress
""";
      try {
        final result = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
        if (result.exitCode == 0 && result.stdout != null) {
          final raw = result.stdout.toString().trim();
          if (raw.isNotEmpty) {
            final parsed = _parseJsonArrayOrSingle(raw);
            for (final item in parsed) {
              final name = item['Name']?.toString() ?? 'USB Device';
              final devId = item['DeviceID']?.toString() ?? '';
              final mfg = item['Manufacturer']?.toString();
              final pnpClass = item['PNPClass']?.toString();

              String? vid;
              String? pid;
              final vidMatch = RegExp(r'VID_([0-9A-Fa-f]{4})', caseSensitive: false).firstMatch(devId);
              final pidMatch = RegExp(r'PID_([0-9A-Fa-f]{4})', caseSensitive: false).firstMatch(devId);
              vid = vidMatch?.group(1)?.toUpperCase();
              pid = pidMatch?.group(1)?.toUpperCase();

              devices.add(UsbDeviceInfo(
                name: name,
                vid: vid,
                pid: pid,
                manufacturer: mfg,
                product: name,
                hardwareId: devId,
                deviceClass: pnpClass,
              ));
            }
          }
        }
      } catch (e) {
        AppLogger.warn('USB scan error: $e');
      }
    }

    return devices;
  }

  Future<List<String>> _scanPcscReaders() async {
    if (isSimulation) {
      return ['HID Global OMNIKEY 3x21 Smart Card Reader (076B:3021)'];
    }

    final readers = <String>[];

    if (Platform.isWindows) {
      const psScript = """
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Get-CimInstance Win32_PnPEntity | Where-Object { \$_.PNPClass -eq 'SmartCardReader' -or \$_.Name -like '*Smart Card*' -or \$_.Name -like '*ACR*' -or \$_.Name -like '*Omnikey*' } | Select-Object -ExpandProperty Name
""";
      try {
        final result = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
        if (result.exitCode == 0 && result.stdout != null) {
          final lines = result.stdout.toString().split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
          readers.addAll(lines);
        }
      } catch (_) {}
    }

    return readers;
  }

  Future<List<ComPortDiagnostic>> _probeComPorts({Function(String msg, double pct)? onProgress}) async {
    final safeCommands = [
      'AT',
      'ATE0',
      'AT+CPIN?',
      'AT+CSQ',
      'AT+CREG?',
      'AT+COPS?',
      'AT+CMGF=?',
      'AT+CUSD=?',
    ];

    if (isSimulation) {
      final cmdResults = <AtCommandTestResult>[];
      for (final cmd in safeCommands) {
        cmdResults.add(AtCommandTestResult(
          command: cmd,
          isSuccess: true,
          rawOutput: _generateMockOutput(cmd),
          durationMs: 5,
        ));
      }
      return [
        ComPortDiagnostic(
          portName: 'COM4',
          friendlyName: 'Cellular Serial Port (COM4)',
          isAtResponsive: true,
          probedBaudRate: 115200,
          commandResults: cmdResults,
        ),
      ];
    }

    final diagnostics = <ComPortDiagnostic>[];
    List<String> portNames = [];

    if (Platform.isWindows) {
      const psScript = "[System.IO.Ports.SerialPort]::GetPortNames()";
      try {
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
        if (res.exitCode == 0 && res.stdout != null) {
          portNames = res.stdout.toString().split(RegExp(r'\s+')).map((p) => p.trim()).where((p) => p.startsWith('COM')).toSet().toList();
        }
      } catch (_) {}
    }

    if (portNames.isEmpty) {
      return []; // In real mode, return empty if no hardware ports exist
    }

    for (int i = 0; i < portNames.length; i++) {
      final port = portNames[i];
      onProgress?.call('جاري فحص المنفذ $port بأوامر AT الآمنة...', 0.60 + (i / portNames.length) * 0.20);

      final cmdResults = <AtCommandTestResult>[];
      bool isResponsive = false;
      int? workingBaud;

      for (final baud in [115200, 9600]) {
        final ping = await _runPsSerialAtCommand(port, 'AT', baud: baud, timeoutMs: 1500);
        if (ping.isSuccess) {
          isResponsive = true;
          workingBaud = baud;
          break;
        }
      }

      if (isResponsive || !Platform.isWindows) {
        workingBaud ??= 115200;
        isResponsive = true;

        for (final cmd in safeCommands) {
          final res = await _runPsSerialAtCommand(port, cmd, baud: workingBaud, timeoutMs: 3000);
          cmdResults.add(res);
        }
      }

      diagnostics.add(ComPortDiagnostic(
        portName: port,
        friendlyName: 'Cellular Serial Port ($port)',
        isAtResponsive: isResponsive,
        probedBaudRate: workingBaud,
        commandResults: cmdResults,
      ));
    }

    return diagnostics;
  }

  Future<AtCommandTestResult> _runPsSerialAtCommand(String port, String command, {required int baud, required int timeoutMs}) async {
    final sw = Stopwatch()..start();

    if (!Platform.isWindows) {
      // Simulated response for cross-platform/mock tests
      await Future.delayed(const Duration(milliseconds: 60));
      sw.stop();
      final mockOutput = _generateMockOutput(command);
      return AtCommandTestResult(
        command: command,
        isSuccess: true,
        rawOutput: mockOutput,
        durationMs: sw.elapsedMilliseconds,
      );
    }

    final escapedCmd = command.replaceAll('"', '`"').replaceAll("'", "''");
    final script = """
try {
  \$port = New-Object System.IO.Ports.SerialPort '$port', $baud, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One
  \$port.DtrEnable = \$true
  \$port.RtsEnable = \$true
  \$port.ReadTimeout = $timeoutMs
  \$port.WriteTimeout = 1500
  \$port.NewLine = "`r`n"
  \$port.Open()
  
  \$port.WriteLine("$escapedCmd")
  Start-Sleep -Milliseconds 250
  
  \$buffer = ""
  \$sw = [System.Diagnostics.Stopwatch]::StartNew()
  while (\$sw.ElapsedMilliseconds -lt $timeoutMs) {
    try {
      \$chunk = \$port.ReadExisting()
      if (\$chunk -ne \$null -and \$chunk.Length -gt 0) {
        \$buffer += \$chunk
        if (\$buffer -match 'OK\\r?\\n' -or \$buffer -match 'ERROR\\r?\\n') {
          break
        }
      }
    } catch {}
    Start-Sleep -Milliseconds 100
  }
  
  \$port.Close()
  Write-Output \$buffer
} catch {
  Write-Output "ERR: \$_"
}
""";

    try {
      final res = await Process.run('powershell', ['-NoProfile', '-Command', script]).timeout(
        Duration(milliseconds: timeoutMs + 2000),
      );
      sw.stop();

      final out = (res.stdout?.toString() ?? '').trim();
      final isOk = out.contains('OK');

      return AtCommandTestResult(
        command: command,
        isSuccess: isOk,
        rawOutput: out.isNotEmpty ? out : (res.stderr?.toString() ?? 'NO_RESPONSE'),
        durationMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return AtCommandTestResult(
        command: command,
        isSuccess: false,
        rawOutput: 'EXECUTION_TIMEOUT / ERROR: $e',
        durationMs: sw.elapsedMilliseconds,
      );
    }
  }

  String _generateMockOutput(String cmd) {
    switch (cmd) {
      case 'AT':
      case 'ATE0':
        return 'OK';
      case 'AT+CPIN?':
        return '+CPIN: READY\r\n\r\nOK';
      case 'AT+CSQ':
        return '+CSQ: 24,99\r\n\r\nOK';
      case 'AT+CREG?':
        return '+CREG: 0,1\r\n\r\nOK';
      case 'AT+COPS?':
        return '+COPS: 0,0,"MOBILIS",7\r\n\r\nOK';
      case 'AT+CMGF=?':
        return '+CMGF: (0,1)\r\n\r\nOK';
      case 'AT+CUSD=?':
        return '+CUSD: (0-2)\r\n\r\nOK';
      default:
        return 'OK';
    }
  }

  CellularDiagnostic? _analyzeCellular(List<ComPortDiagnostic> ports) {
    // Find first responsive port with results
    final responsive = ports.where((p) => p.isAtResponsive && p.commandResults.isNotEmpty).toList();
    if (responsive.isEmpty) return null;

    final results = responsive.first.commandResults;

    String simStatus = 'UNKNOWN';
    int rssi = 99;
    int percent = 0;
    int? dbm;
    String netReg = 'NOT REGISTERED';
    String? opName;
    String? act;

    for (final r in results) {
      final text = r.rawOutput;

      // SIM Status (AT+CPIN?)
      if (r.command == 'AT+CPIN?') {
        if (text.contains('READY')) {
          simStatus = 'READY';
        } else if (text.contains('SIM PIN')) {
          simStatus = 'PIN REQUIRED';
        } else if (text.contains('SIM PUK')) {
          simStatus = 'PUK REQUIRED';
        } else if (text.contains('10') || text.contains('not inserted')) {
          simStatus = 'NOT PRESENT';
        }
      }

      // Signal (AT+CSQ)
      if (r.command == 'AT+CSQ') {
        final match = RegExp(r'\+CSQ:\s*(\d+)').firstMatch(text);
        if (match != null) {
          rssi = int.tryParse(match.group(1) ?? '99') ?? 99;
          if (rssi <= 31) {
            percent = ((rssi / 31) * 100).clamp(0, 100).toInt();
            dbm = -113 + (rssi * 2);
          }
        }
      }

      // Registration (AT+CREG?)
      if (r.command == 'AT+CREG?') {
        final match = RegExp(r'\+CREG:\s*\d+,(\d+)').firstMatch(text);
        if (match != null) {
          final code = match.group(1);
          if (code == '1') {
            netReg = 'REGISTERED (HOME)';
          } else if (code == '5') {
            netReg = 'REGISTERED (ROAMING)';
          } else if (code == '2') {
            netReg = 'SEARCHING';
          } else if (code == '3') {
            netReg = 'REGISTRATION DENIED';
          } else {
            netReg = 'NOT REGISTERED';
          }
        }
      }

      // Operator (AT+COPS?)
      if (r.command == 'AT+COPS?') {
        final match = RegExp(r'\+COPS:\s*\d+,\s*\d+,\s*"([^"]+)"(?:,\s*(\d+))?').firstMatch(text);
        if (match != null) {
          opName = match.group(1);
          final actCode = match.group(2);
          if (actCode == '7') act = '4G (LTE)';
          if (actCode == '2') act = '3G (UMTS)';
          if (actCode == '0') act = '2G (GSM)';

          if (opName == '60301') opName = 'MOBILIS';
          if (opName == '60302') opName = 'Djezzy';
          if (opName == '60303') opName = 'Ooredoo';
        }
      }
    }

    return CellularDiagnostic(
      simStatus: simStatus,
      signalRssi: rssi,
      signalPercent: percent,
      signalDbm: dbm,
      networkRegistration: netReg,
      operatorName: opName,
      accessTechnology: act,
    );
  }

  DiagnosticVerdict _computeVerdict({
    required List<UsbDeviceInfo> usbDevices,
    required List<String> pcscReaders,
    required List<ComPortDiagnostic> comPorts,
    required CellularDiagnostic? cellular,
  }) {
    final hasPcsc = pcscReaders.isNotEmpty || usbDevices.any((d) => d.deviceClass?.toLowerCase() == 'smartcardreader');
    final hasAtModem = comPorts.any((p) => p.isAtResponsive);

    String devType = 'UNKNOWN';
    if (hasAtModem) {
      devType = 'GSM MODEM';
    } else if (hasPcsc) {
      devType = 'PC/SC READER';
    }

    final pcscStatus = hasPcsc ? 'SUPPORTED' : 'NOT SUPPORTED';
    final atModemStatus = hasAtModem ? 'SUPPORTED' : 'NOT SUPPORTED';

    final ussdStatus = hasAtModem ? 'SUPPORTED' : 'NOT SUPPORTED';
    final smsStatus = hasAtModem ? 'SUPPORTED' : 'NOT SUPPORTED';

    final isRegistered = cellular != null && cellular.networkRegistration.startsWith('REGISTERED');
    final netStatus = isRegistered ? 'REGISTERED' : 'NOT REGISTERED';

    final simStatus = cellular?.simStatus ?? 'UNKNOWN';

    final notes = <String>[];
    if (hasAtModem && isRegistered && simStatus == 'READY') {
      notes.add('الجهاز جاهز ومؤهل تماماً لتشغيل التعبئة وتنفيذ أوامر USSD عبر الشريحة.');
    } else if (hasPcsc && !hasAtModem) {
      notes.add('تم اكتشاف قارئ بطاقات ذكية PC/SC فقط. لإرسال أوامر USSD والاتصال بالشبكة يلزم استخدام مودم USB GSM.');
    } else if (hasAtModem && simStatus == 'PIN REQUIRED') {
      notes.add('الشريحة داخل المودم تطلب رمز PIN. يرجى إلغاء قفل PIN للبدء في العمل.');
    } else if (hasAtModem && simStatus == 'NOT PRESENT') {
      notes.add('المودم متصل لكن الشريحة غير مركبة أو غير مقروءة داخل المودم.');
    }

    return DiagnosticVerdict(
      deviceType: devType,
      pcsc: pcscStatus,
      atModem: atModemStatus,
      ussd: ussdStatus,
      sms: smsStatus,
      network: netStatus,
      sim: simStatus,
      notes: notes,
    );
  }

  List<Map<String, dynamic>> _parseJsonArrayOrSingle(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      } else if (decoded is Map<String, dynamic>) {
        return [decoded];
      }
    } catch (_) {}
    return [];
  }
}
