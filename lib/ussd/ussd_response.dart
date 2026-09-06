import 'menu_option.dart';
import 'menu_parser.dart';

enum UssdResponseType {
  noActionRequired, // Mode 0 (Session ended by network with result)
  userResponseRequired, // Mode 1 (Session is waiting for user reply)
  terminatedByNetwork, // Mode 2 (Network aborted or timed out)
  otherResponse, // Mode 3
  operationNotSupported, // Mode 4
  error,
}

class UssdResponse {
  final UssdResponseType type;
  final String rawText;
  final String cleanText;
  final List<MenuOption> options;
  final String? transactionRef;
  final bool isSuccess;
  final String? error;

  const UssdResponse({
    required this.type,
    required this.rawText,
    required this.cleanText,
    this.options = const [],
    this.transactionRef,
    this.isSuccess = true,
    this.error,
  });

  bool get isWaitingUser => type == UssdResponseType.userResponseRequired;
  bool get isCompleted => type == UssdResponseType.noActionRequired && isSuccess;
  bool get hasOptions => options.isNotEmpty;

  factory UssdResponse.fromRaw(String raw) {
    final clean = raw.trim();

    // Parse +CUSD: <mode>, "<text>", <dcs>
    final cusdRegex = RegExp(r'\+CUSD:\s*(\d+)\s*(?:,\s*"([^"]*)"\s*(?:,\s*(\d+))?)?');
    final match = cusdRegex.firstMatch(clean);

    UssdResponseType type = UssdResponseType.noActionRequired;
    String rawStr = clean;

    if (match != null) {
      final mode = match.group(1);
      rawStr = match.group(2) ?? '';

      switch (mode) {
        case '0':
          type = UssdResponseType.noActionRequired;
          break;
        case '1':
          type = UssdResponseType.userResponseRequired;
          break;
        case '2':
          type = UssdResponseType.terminatedByNetwork;
          break;
        default:
          type = UssdResponseType.noActionRequired;
      }
    } else if (clean.contains('ERROR')) {
      return UssdResponse(
        type: UssdResponseType.error,
        rawText: clean,
        cleanText: 'خطأ في تنفيذ الطلب (USSD Network Error)',
        isSuccess: false,
        error: clean,
      );
    }

    // Decode UCS2 hex if present
    final decodedText = _decodeUcs2Hex(rawStr);
    final parsedOptions = MenuParser.parseMenu(decodedText);
    final ref = _extractTransactionRef(decodedText);

    return UssdResponse(
      type: type,
      rawText: raw,
      cleanText: decodedText.isNotEmpty ? decodedText : clean,
      options: parsedOptions,
      transactionRef: ref,
      isSuccess: type != UssdResponseType.terminatedByNetwork && type != UssdResponseType.error,
    );
  }

  static String _decodeUcs2Hex(String input) {
    final clean = input.replaceAll(RegExp(r'\s+'), '').trim();
    if (clean.length >= 4 && clean.length % 4 == 0 && RegExp(r'^[0-9A-Fa-f]+$').hasMatch(clean)) {
      try {
        final buffer = StringBuffer();
        for (int i = 0; i < clean.length; i += 4) {
          final hexChunk = clean.substring(i, i + 4);
          final codeUnit = int.parse(hexChunk, radix: 16);
          if (codeUnit != 0) {
            buffer.writeCharCode(codeUnit);
          }
        }
        final decoded = buffer.toString();
        if (decoded.trim().isNotEmpty) {
          return decoded;
        }
      } catch (_) {}
    }
    return input.replaceAll('\\n', '\n').replaceAll('\\r', '');
  }

  static String? _extractTransactionRef(String text) {
    final match = RegExp(r'(TXN-\d+|Ref:\s*(\S+)|مرجع:\s*(\S+)|Trans ID:\s*(\S+))', caseSensitive: false).firstMatch(text);
    return match?.group(0);
  }
}
