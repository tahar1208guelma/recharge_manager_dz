import 'dart:async';
import '../../core/constants/operator_constants.dart';
import '../../domain/entities/ussd_session_state.dart';
import 'gsm_modem_service.dart';

class UssdSessionManager {
  final GsmModemService modemService;
  final _stateController = StreamController<UssdSessionState>.broadcast();
  UssdSessionState? _currentState;

  UssdSessionManager({GsmModemService? modemService})
      : modemService = modemService ?? GsmModemService();

  Stream<UssdSessionState> get stateStream => _stateController.stream;
  UssdSessionState? get currentState => _currentState;

  void _emit(UssdSessionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Starts a new interactive USSD session with the inserted SIM card
  Future<UssdSessionState> startSession({
    required OperatorType operator,
    required String ussdCode,
    String? portName,
  }) async {
    final sessionId = 'USSD-${DateTime.now().millisecondsSinceEpoch}';
    final initialMessage = UssdSessionMessage(
      content: ussdCode,
      isFromSim: false,
    );

    var state = UssdSessionState(
      sessionId: sessionId,
      operator: operator,
      initialCommand: ussdCode,
      status: UssdSessionStatus.sending,
      messages: [initialMessage],
    );
    _emit(state);

    try {
      // Send to hardware modem / telecom network
      final resp = await modemService.sendUssd(ussdCode, portName: portName);

      if (!resp.isSuccess) {
        state = state.copyWith(
          status: UssdSessionStatus.failed,
          errorMessage: resp.error ?? resp.cleanMessage,
        );
        _emit(state);
        return state;
      }

      final simMessage = UssdSessionMessage(
        content: resp.cleanMessage,
        isFromSim: true,
        detectedOptions: _extractOptionsFromText(resp.cleanMessage),
      );

      final updatedMessages = List<UssdSessionMessage>.from(state.messages)..add(simMessage);

      if (resp.isSessionOpen) {
        // Session is waiting for seller's input/choice
        state = state.copyWith(
          status: UssdSessionStatus.waitingUserResponse,
          messages: updatedMessages,
          currentPrompt: resp.cleanMessage,
          currentOptions: simMessage.detectedOptions,
        );
      } else {
        // Session completed in 1 step
        state = state.copyWith(
          status: UssdSessionStatus.completed,
          messages: updatedMessages,
          currentPrompt: resp.cleanMessage,
          transactionRef: _extractRefFromText(resp.cleanMessage),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: UssdSessionStatus.failed,
        errorMessage: 'خطأ في الاتصال بالشريحة: $e',
      );
    }

    _emit(state);
    return state;
  }

  /// Sends the seller's choice or reply to the SIM card
  Future<UssdSessionState> sendReply(String replyText, {String? portName}) async {
    if (_currentState == null) {
      throw StateError('No active USSD session to reply to.');
    }

    var state = _currentState!;
    final userMessage = UssdSessionMessage(
      content: replyText,
      isFromSim: false,
    );

    final messagesWithUser = List<UssdSessionMessage>.from(state.messages)..add(userMessage);
    state = state.copyWith(
      status: UssdSessionStatus.sending,
      messages: messagesWithUser,
    );
    _emit(state);

    try {
      final resp = await modemService.sendUssd(replyText, portName: portName);

      if (!resp.isSuccess) {
        state = state.copyWith(
          status: UssdSessionStatus.failed,
          errorMessage: resp.error ?? resp.cleanMessage,
        );
        _emit(state);
        return state;
      }

      final simMessage = UssdSessionMessage(
        content: resp.cleanMessage,
        isFromSim: true,
        detectedOptions: _extractOptionsFromText(resp.cleanMessage),
      );

      final updatedMessages = List<UssdSessionMessage>.from(state.messages)..add(simMessage);

      if (resp.isSessionOpen) {
        state = state.copyWith(
          status: UssdSessionStatus.waitingUserResponse,
          messages: updatedMessages,
          currentPrompt: resp.cleanMessage,
          currentOptions: simMessage.detectedOptions,
        );
      } else {
        final isCancel = replyText == '2' || resp.cleanMessage.contains('annul') || resp.cleanMessage.contains('إلغاء');
        state = state.copyWith(
          status: isCancel ? UssdSessionStatus.cancelled : UssdSessionStatus.completed,
          messages: updatedMessages,
          currentPrompt: resp.cleanMessage,
          transactionRef: _extractRefFromText(resp.cleanMessage),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: UssdSessionStatus.failed,
        errorMessage: 'فشل إرسال الرد للشريحة: $e',
      );
    }

    _emit(state);
    return state;
  }

  /// Cancels the current interactive USSD session
  void cancelSession() {
    if (_currentState != null) {
      _emit(_currentState!.copyWith(status: UssdSessionStatus.cancelled));
    }
  }

  List<String> _extractOptionsFromText(String text) {
    final options = <String>[];
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (RegExp(r'^\d+[\s:.-]').hasMatch(trimmed)) {
        options.add(trimmed);
      }
    }
    if (options.isEmpty && (text.contains('1:') || text.contains('2:'))) {
      options.addAll(['1: تأكيد (Confirmer)', '2: إلغاء (Annuler)']);
    }
    return options;
  }

  String? _extractRefFromText(String text) {
    final match = RegExp(r'(TXN-\d+|Ref:\s*(\S+)|مرجع:\s*(\S+))', caseSensitive: false).firstMatch(text);
    return match?.group(0);
  }

  void dispose() {
    _stateController.close();
  }
}
