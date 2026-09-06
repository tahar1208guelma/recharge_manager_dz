class AtCommand {
  final String command;
  final Duration timeout;
  final int retries;
  final String? expectedPrefix; // e.g. "+CPIN:", "+CSQ:", "+COPS:"
  final bool expectImmediateOk;
  final DateTime timestamp;

  AtCommand({
    required this.command,
    this.timeout = const Duration(seconds: 5),
    this.retries = 1,
    this.expectedPrefix,
    this.expectImmediateOk = true,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'AtCommand($command, timeout: ${timeout.inSeconds}s)';
}
