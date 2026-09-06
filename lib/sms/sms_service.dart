import 'dart:async';
import '../core/utils/app_logger.dart';
import '../modem/models/at_command.dart';
import '../modem/models/unsolicited_response.dart';
import '../modem/modem_service.dart';
import 'sms_message.dart';

class SmsService {
  final ModemService modemService;
  final List<SmsMessage> _messages = [];
  final _incomingSmsController = StreamController<SmsMessage>.broadcast();
  StreamSubscription<UnsolicitedResponse>? _unsolicitedSub;

  SmsService({required this.modemService}) {
    _unsolicitedSub = modemService.unsolicitedEvents.listen((event) {
      if (event.type == UnsolicitedType.smsNotification) {
        _handleNewSmsNotification(event.rawLine);
      }
    });
  }

  List<SmsMessage> get messages => List.unmodifiable(_messages);
  Stream<SmsMessage> get incomingSmsStream => _incomingSmsController.stream;

  /// Sets text mode (AT+CMGF=1) and reads all stored SMS messages from SIM (AT+CMGL="ALL")
  Future<List<SmsMessage>> fetchAllMessages() async {
    AppLogger.info('SmsService: Fetching all SMS messages from modem...');

    // 1. Ensure Text Mode (AT+CMGF=1)
    await modemService.sendRaw('AT+CMGF=1', timeout: const Duration(seconds: 2));

    // 2. Read messages (AT+CMGL="ALL")
    final cmglResp = await modemService.executeCommand(
      AtCommand(command: 'AT+CMGL="ALL"', timeout: const Duration(seconds: 8)),
    );

    _messages.clear();

    if (cmglResp.isSuccess && cmglResp.resultData != null) {
      final parsed = _parseCmglOutput(cmglResp.resultData!);
      _messages.addAll(parsed);
      AppLogger.info('SmsService: Successfully fetched ${_messages.length} SMS messages.');
    }

    return _messages;
  }

  /// Sends an SMS message to a phone number
  Future<bool> sendSms(String recipient, String messageText) async {
    AppLogger.info('SmsService: Sending SMS to $recipient...');

    // 1. Set Text Mode
    await modemService.sendRaw('AT+CMGF=1', timeout: const Duration(seconds: 2));

    // 2. Send AT+CMGS="recipient" followed by text and Ctrl+Z (\x1A)
    final cmd = 'AT+CMGS="$recipient"\r$messageText\x1A';
    final resp = await modemService.executeCommand(
      AtCommand(command: cmd, timeout: const Duration(seconds: 15)),
    );

    if (resp.isSuccess || resp.rawOutput.contains('+CMGS:')) {
      final sentMsg = SmsMessage(
        senderOrRecipient: recipient,
        text: messageText,
        timestamp: DateTime.now(),
        type: SmsType.sent,
      );
      _messages.insert(0, sentMsg);
      AppLogger.info('SmsService: SMS sent successfully to $recipient.');
      return true;
    }

    AppLogger.warn('SmsService: Failed to send SMS: ${resp.error ?? resp.rawOutput}');
    return false;
  }

  /// Deletes a specific SMS by its SIM storage index (`AT+CMGD=<index>`)
  Future<bool> deleteMessage(int indexOnSim) async {
    AppLogger.info('SmsService: Deleting SMS at index $indexOnSim...');
    final resp = await modemService.sendRaw('AT+CMGD=$indexOnSim', timeout: const Duration(seconds: 3));
    if (resp.isSuccess) {
      _messages.removeWhere((m) => m.indexOnSim == indexOnSim);
      return true;
    }
    return false;
  }

  /// Handles incoming `+CMTI: "SM", <index>` notification
  Future<void> _handleNewSmsNotification(String line) async {
    AppLogger.info('SmsService: Handling new SMS notification: $line');
    final match = RegExp(r'\+CMTI:\s*"[^"]*",\s*(\d+)').firstMatch(line);
    if (match != null) {
      final index = int.tryParse(match.group(1) ?? '');
      if (index != null) {
        final readResp = await modemService.sendRaw('AT+CMGR=$index', timeout: const Duration(seconds: 4));
        if (readResp.isSuccess && readResp.resultData != null) {
          final newMessages = _parseCmglOutput(readResp.resultData!);
          for (final msg in newMessages) {
            _messages.insert(0, msg);
            _incomingSmsController.add(msg);
          }
        }
      }
    }
  }

  List<SmsMessage> _parseCmglOutput(String output) {
    final list = <SmsMessage>[];
    final lines = output.split(RegExp(r'\r?\n'));

    int? currentIndex;
    String? currentSender;
    DateTime? currentTimestamp;
    StringBuffer currentBody = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('+CMGL:') || line.startsWith('+CMGR:')) {
        // Save previous message if exists
        if (currentIndex != null && currentSender != null) {
          list.add(SmsMessage(
            indexOnSim: currentIndex,
            senderOrRecipient: currentSender,
            text: currentBody.toString().trim(),
            timestamp: currentTimestamp ?? DateTime.now(),
          ));
          currentBody.clear();
        }

        // Parse header: +CMGL: 1,"REC READ","MOBILIS","","2026/09/06 14:30:15+04"
        final headerMatch = RegExp(r'\+(?:CMGL|CMGR):\s*(\d+)?,\s*"[^"]*",\s*"([^"]*)",\s*(?:"[^"]*",\s*)?"([^"]*)"').firstMatch(line);
        if (headerMatch != null) {
          currentIndex = int.tryParse(headerMatch.group(1) ?? '0');
          currentSender = headerMatch.group(2) ?? 'Unknown';
          final tsStr = headerMatch.group(3);
          if (tsStr != null) {
            currentTimestamp = _parseSmsTimestamp(tsStr);
          }
        }
      } else if (line != 'OK' && !line.startsWith('AT')) {
        if (currentBody.isNotEmpty) currentBody.write('\n');
        currentBody.write(line);
      }
    }

    if (currentIndex != null && currentSender != null && currentBody.isNotEmpty) {
      list.add(SmsMessage(
        indexOnSim: currentIndex,
        senderOrRecipient: currentSender,
        text: currentBody.toString().trim(),
        timestamp: currentTimestamp ?? DateTime.now(),
      ));
    }

    return list;
  }

  DateTime _parseSmsTimestamp(String raw) {
    try {
      // Format: "26/09/06,14:30:15+04" or "2026/09/06 14:30:15"
      final clean = raw.replaceAll('/', '-').replaceAll(',', ' ').replaceAll(RegExp(r'\+\d+$'), '');
      return DateTime.tryParse(clean) ?? DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  void dispose() {
    _unsolicitedSub?.cancel();
    _incomingSmsController.close();
  }
}
