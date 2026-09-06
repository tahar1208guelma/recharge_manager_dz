import 'dart:async';
import 'debug_log_entry.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final List<DebugLogEntry> _logs = [];
  final _logStreamController = StreamController<DebugLogEntry>.broadcast();
  static const int maxLogs = 500;

  List<DebugLogEntry> get logs => List.unmodifiable(_logs);
  Stream<DebugLogEntry> get logStream => _logStreamController.stream;

  /// Records Transmitted AT Command (TX →) with PIN and secret sanitization
  void logTx(String port, String command) {
    final sanitized = _sanitizeSensitiveData(command);
    final entry = DebugLogEntry(
      direction: DebugDirection.tx,
      port: port,
      content: sanitized,
    );
    _addEntry(entry);
  }

  /// Records Received Response (RX ←)
  void logRx(String port, String response) {
    final entry = DebugLogEntry(
      direction: DebugDirection.rx,
      port: port,
      content: response,
    );
    _addEntry(entry);
  }

  /// Records System / HAL hardware events
  void logSystem(String port, String message) {
    final entry = DebugLogEntry(
      direction: DebugDirection.system,
      port: port,
      content: message,
    );
    _addEntry(entry);
  }

  void _addEntry(DebugLogEntry entry) {
    _logs.add(entry);
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
    _logStreamController.add(entry);
  }

  /// Sanitizes PINs in AT+CPIN="1234" or *630*...*PIN# so secrets are never logged
  static String _sanitizeSensitiveData(String raw) {
    var clean = raw;
    // Sanitize AT+CPIN="1234" -> AT+CPIN="****"
    clean = clean.replaceAllMapped(RegExp(r'AT\+CPIN="([^"]+)"', caseSensitive: false), (m) => 'AT+CPIN="****"');
    // Sanitize PIN at end of USSD e.g. *630*0661123456*04*500*11111# -> *630*0661123456*04*500*#
    clean = clean.replaceAllMapped(RegExp(r'\*(\d{4,8})#$'), (m) => '*#');
    return clean;
  }

  void clearLogs() {
    _logs.clear();
  }

  void dispose() {
    _logStreamController.close();
  }
}
