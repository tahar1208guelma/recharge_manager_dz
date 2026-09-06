enum DebugDirection {
  tx, // Transmit (App -> Modem)
  rx, // Receive (Modem -> App)
  system, // System event / hardware state
}

class DebugLogEntry {
  final DebugDirection direction;
  final String port;
  final String content;
  final DateTime timestamp;

  DebugLogEntry({
    required this.direction,
    required this.port,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get directionSymbol {
    switch (direction) {
      case DebugDirection.tx:
        return 'TX →';
      case DebugDirection.rx:
        return 'RX ←';
      case DebugDirection.system:
        return 'SYS ⚙';
    }
  }

  @override
  String toString() => '[$formattedTime] [$port] $directionSymbol $content';
}
