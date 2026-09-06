import 'dart:async';
import 'dart:io';
import '../../core/utils/app_logger.dart';
import '../models/at_command.dart';
import '../models/at_response.dart';
import '../models/unsolicited_response.dart';
import 'modem_driver.dart';

class GenericAtModemDriver implements IModemDriver {
  String? _activePort;
  int _activeBaudRate = 115200;
  bool _isConnected = false;

  final _unsolicitedController = StreamController<UnsolicitedResponse>.broadcast();

  @override
  String get driverName => 'Generic AT Modem Driver (3GPP TS 27.007)';

  @override
  bool get isConnected => _isConnected;

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

    if (!Platform.isWindows) {
      _isConnected = true;
      return true;
    }

    // Ping modem with AT command
    final ping = await sendRaw('AT', timeout: const Duration(seconds: 3));
    if (ping.isSuccess) {
      _isConnected = true;
      // Initialize modem: Turn off echo, enable text mode if supported
      await sendRaw('ATE0', timeout: const Duration(seconds: 2));
      return true;
    }

    // If default baud failed, probe other rates
    final detectedBaud = await probeBaudRate(portName);
    if (detectedBaud != null) {
      _activeBaudRate = detectedBaud;
      _isConnected = true;
      await sendRaw('ATE0', timeout: const Duration(seconds: 2));
      return true;
    }

    _isConnected = false;
    return false;
  }

  @override
  Future<void> disconnect() async {
    AppLogger.info('GenericAtModemDriver: Disconnecting from $_activePort...');
    _isConnected = false;
    _activePort = null;
  }

  @override
  Future<int?> probeBaudRate(String portName, {List<int> baudRates = const [115200, 57600, 38400, 19200, 9600]}) async {
    for (final rate in baudRates) {
      try {
        final stopwatch = Stopwatch()..start();
        final raw = await _executePsSerialCommand(portName, 'AT', timeoutMs: 2000, baudRate: rate);
        stopwatch.stop();

        if (raw.contains('OK')) {
          AppLogger.info('GenericAtModemDriver: Successfully probed $portName at $rate bps');
          return rate;
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
    if (port == null || !Platform.isWindows) {
      return AtResponse.fromRaw('OK', const Duration(milliseconds: 50));
    }

    final stopwatch = Stopwatch()..start();
    for (int attempt = 1; attempt <= command.retries; attempt++) {
      try {
        final raw = await _executePsSerialCommand(
          port,
          command.command,
          timeoutMs: command.timeout.inMilliseconds,
          baudRate: _activeBaudRate,
        );
        stopwatch.stop();

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
      } catch (e) {
        if (attempt == command.retries) {
          stopwatch.stop();
          return AtResponse.error('Execution error: $e', stopwatch.elapsed);
        }
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    stopwatch.stop();
    return AtResponse.timeout(stopwatch.elapsed);
  }

  Future<String> _executePsSerialCommand(String port, String command, {required int timeoutMs, required int baudRate}) async {
    final escapedCmd = command.replaceAll('"', '`"').replaceAll("'", "''");
    final script = """
\$ErrorActionPreference = 'Stop'
try {
  \$port = New-Object System.IO.Ports.SerialPort '$port', $baudRate, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One
  \$port.DtrEnable = \$true
  \$port.RtsEnable = \$true
  \$port.ReadTimeout = $timeoutMs
  \$port.WriteTimeout = 2000
  \$port.NewLine = "`r`n"
  \$port.Open()
  
  \$port.WriteLine("$escapedCmd")
  Start-Sleep -Milliseconds 300
  
  \$sw = [System.Diagnostics.Stopwatch]::StartNew()
  \$buffer = ""
  while (\$sw.ElapsedMilliseconds -lt $timeoutMs) {
    try {
      \$chunk = \$port.ReadExisting()
      if (\$chunk -ne \$null -and \$chunk.Length -gt 0) {
        \$buffer += \$chunk
        if (\$buffer -match '\\+CUSD:' -or \$buffer -match 'OK\\r?\\n' -or \$buffer -match 'ERROR\\r?\\n') {
          if (\$buffer -match '\\+CUSD:' -or "$escapedCmd" -notmatch 'AT\\+CUSD') {
            break
          }
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

    final res = await Process.run(
      'powershell',
      ['-NoProfile', '-Command', script],
    ).timeout(Duration(milliseconds: timeoutMs + 2500));

    if (res.exitCode == 0 && res.stdout != null) {
      return res.stdout.toString().trim();
    } else {
      return 'ERR: ${res.stderr ?? "Execution failed"}';
    }
  }

  @override
  void dispose() {
    _unsolicitedController.close();
  }
}
