class AppLogger {
  static const bool _isDebug = !bool.fromEnvironment('dart.vm.product');
  static final List<String> _logs = [];
  static const int _maxLogs = 500;

  static void info(String message) {
    _log('INFO', message);
  }

  static void warn(String message) {
    _log('WARN', message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    final extra = error != null ? ' | Error: $error' : '';
    _log('ERROR', '$message$extra');
    if (stackTrace != null && _isDebug) {
      // ignore: avoid_print
      print(stackTrace.toString());
    }
  }

  static void debug(String message) {
    if (_isDebug) {
      _log('DEBUG', message);
    }
  }

  static void _log(String level, String message) {
    final now = DateTime.now().toIso8601String();
    final entry = '[$now] [$level] $message';
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    if (_isDebug) {
      // ignore: avoid_print
      print(entry);
    }
  }

  static List<String> getRecentLogs() => List.unmodifiable(_logs);
  static void clear() => _logs.clear();
}
