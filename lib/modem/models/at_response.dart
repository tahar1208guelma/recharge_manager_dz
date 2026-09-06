class AtResponse {
  final bool isSuccess;
  final String rawOutput;
  final List<String> lines;
  final String? resultData;
  final String? error;
  final int? cmeError;
  final int? cmsError;
  final Duration executionDuration;
  final DateTime timestamp;

  AtResponse({
    required this.isSuccess,
    required this.rawOutput,
    this.lines = const [],
    this.resultData,
    this.error,
    this.cmeError,
    this.cmsError,
    required this.executionDuration,
  }) : timestamp = DateTime.now();

  factory AtResponse.fromRaw(String raw, Duration duration) {
    final clean = raw.trim();
    final rawLines = clean.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    bool success = clean.contains('OK') && !clean.contains('ERROR');
    String? err;
    int? cme;
    int? cms;

    if (clean.contains('ERROR')) {
      success = false;
      err = clean;

      final cmeMatch = RegExp(r'\+CME ERROR:\s*(\d+)').firstMatch(clean);
      if (cmeMatch != null) {
        cme = int.tryParse(cmeMatch.group(1) ?? '');
      }

      final cmsMatch = RegExp(r'\+CMS ERROR:\s*(\d+)').firstMatch(clean);
      if (cmsMatch != null) {
        cms = int.tryParse(cmsMatch.group(1) ?? '');
      }
    }

    // Filter out echo and OK/ERROR lines to isolate payload data
    final dataLines = rawLines.where((l) => l != 'OK' && !l.startsWith('AT') && !l.contains('ERROR')).toList();

    return AtResponse(
      isSuccess: success,
      rawOutput: clean,
      lines: rawLines,
      resultData: dataLines.isNotEmpty ? dataLines.join('\n') : null,
      error: err,
      cmeError: cme,
      cmsError: cms,
      executionDuration: duration,
    );
  }

  factory AtResponse.timeout(Duration duration) {
    return AtResponse(
      isSuccess: false,
      rawOutput: 'TIMEOUT',
      error: 'انتهت مهلة استجابة المودم (Modem Response Timeout)',
      executionDuration: duration,
    );
  }

  factory AtResponse.error(String errorMsg, Duration duration) {
    return AtResponse(
      isSuccess: false,
      rawOutput: 'ERROR: $errorMsg',
      error: errorMsg,
      executionDuration: duration,
    );
  }
}
