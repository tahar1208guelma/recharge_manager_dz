import 'dart:async';
import '../core/constants/operator_constants.dart';
import '../core/utils/app_logger.dart';
import '../modem/models/at_command.dart';
import '../modem/models/unsolicited_response.dart';
import '../modem/modem_service.dart';
import 'menu_option.dart';
import 'ussd_response.dart';

enum UssdEngineState {
  idle,
  starting,
  waitingResponse,
  menuPresented,
  userInputRequired,
  processing,
  completed,
  error,
  timeout,
  cancelled,
}

class SessionEngineStep {
  final String content;
  final bool isFromNetwork;
  final DateTime timestamp;
  final List<MenuOption> detectedOptions;

  SessionEngineStep({
    required this.content,
    required this.isFromNetwork,
    this.detectedOptions = const [],
  }) : timestamp = DateTime.now();
}

class UssdSessionData {
  final String sessionId;
  final OperatorType operator;
  final String initialCommand;
  final UssdEngineState state;
  final List<SessionEngineStep> history;
  final String? currentPrompt;
  final List<MenuOption> currentOptions;
  final String? transactionRef;
  final String? errorMessage;
  final DateTime startTime;

  UssdSessionData({
    required this.sessionId,
    required this.operator,
    required this.initialCommand,
    required this.state,
    required this.history,
    this.currentPrompt,
    this.currentOptions = const [],
    this.transactionRef,
    this.errorMessage,
    required this.startTime,
  });

  bool get isWaitingUser => state == UssdEngineState.menuPresented || state == UssdEngineState.userInputRequired;
  bool get isCompleted => state == UssdEngineState.completed;
  bool get isFailed => state == UssdEngineState.error || state == UssdEngineState.timeout;

  UssdSessionData copyWith({
    UssdEngineState? state,
    List<SessionEngineStep>? history,
    String? currentPrompt,
    List<MenuOption>? currentOptions,
    String? transactionRef,
    String? errorMessage,
  }) {
    return UssdSessionData(
      sessionId: sessionId,
      operator: operator,
      initialCommand: initialCommand,
      state: state ?? this.state,
      history: history ?? this.history,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      currentOptions: currentOptions ?? this.currentOptions,
      transactionRef: transactionRef ?? this.transactionRef,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime,
    );
  }
}

class SessionEngine {
  final ModemService modemService;
  UssdSessionData? _currentSession;
  final _stateController = StreamController<UssdSessionData>.broadcast();
  StreamSubscription<UnsolicitedResponse>? _unsolicitedSub;

  SessionEngine({required this.modemService}) {
    _unsolicitedSub = modemService.unsolicitedEvents.listen((event) {
      if (event.type == UnsolicitedType.ussdPrompt || event.type == UnsolicitedType.ussdTerminated) {
        _handleUnsolicitedUssd(event.rawLine);
      }
    });
  }

  UssdSessionData? get currentSession => _currentSession;
  Stream<UssdSessionData> get stateStream => _stateController.stream;

  void _emit(UssdSessionData session) {
    _currentSession = session;
    _stateController.add(session);
  }

  /// Starts a new USSD session with initial command (e.g. *630*0661123456*04*500*11111# or *600#)
  Future<UssdSessionData> startSession({
    required OperatorType operator,
    required String ussdCode,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final sessionId = 'USSD-${DateTime.now().millisecondsSinceEpoch}';
    AppLogger.info('SessionEngine: Starting USSD session $sessionId ("$ussdCode")...');

    final initialStep = SessionEngineStep(content: ussdCode, isFromNetwork: false);
    var session = UssdSessionData(
      sessionId: sessionId,
      operator: operator,
      initialCommand: ussdCode,
      state: UssdEngineState.starting,
      history: [initialStep],
      startTime: DateTime.now(),
    );
    _emit(session);

    // Send AT+CUSD=1,"<ussdCode>",15
    final cmdStr = 'AT+CUSD=1,"$ussdCode",15';
    session = session.copyWith(state: UssdEngineState.waitingResponse);
    _emit(session);

    try {
      final atResp = await modemService.executeCommand(
        AtCommand(command: cmdStr, timeout: timeout),
      );

      if (atResp.rawOutput.contains('+CUSD:')) {
        final parsed = UssdResponse.fromRaw(atResp.rawOutput);
        session = _processUssdResponse(session, parsed);
      } else if (!atResp.isSuccess) {
        session = session.copyWith(
          state: UssdEngineState.error,
          errorMessage: atResp.error ?? 'فشل الاتصال بالشبكة عبر الشريحة',
        );
      }
    } catch (e) {
      session = session.copyWith(
        state: UssdEngineState.error,
        errorMessage: 'خطأ في معالجة الجلسة: $e',
      );
    }

    _emit(session);
    return session;
  }

  /// Sends a reply choice or input to the open USSD session
  Future<UssdSessionData> sendReply(String replyText, {Duration timeout = const Duration(seconds: 12)}) async {
    if (_currentSession == null) {
      throw StateError('No active USSD session to send reply to.');
    }

    final cleanReply = replyText.trim();
    AppLogger.info('SessionEngine: Sending reply "$cleanReply" to session ${_currentSession!.sessionId}...');

    var session = _currentSession!;
    final userStep = SessionEngineStep(content: cleanReply, isFromNetwork: false);
    final newHistory = List<SessionEngineStep>.from(session.history)..add(userStep);

    session = session.copyWith(
      state: UssdEngineState.processing,
      history: newHistory,
    );
    _emit(session);

    final cmdStr = 'AT+CUSD=1,"$cleanReply",15';

    try {
      final atResp = await modemService.executeCommand(
        AtCommand(command: cmdStr, timeout: timeout),
      );

      if (atResp.rawOutput.contains('+CUSD:')) {
        final parsed = UssdResponse.fromRaw(atResp.rawOutput);
        session = _processUssdResponse(session, parsed);
      } else if (!atResp.isSuccess) {
        session = session.copyWith(
          state: UssdEngineState.error,
          errorMessage: atResp.error ?? 'فشل إرسال الرد للشريحة',
        );
      }
    } catch (e) {
      session = session.copyWith(
        state: UssdEngineState.error,
        errorMessage: 'خطأ في إرسال الرد: $e',
      );
    }

    _emit(session);
    return session;
  }

  /// Handles incoming unsolicited +CUSD lines from modem driver
  void _handleUnsolicitedUssd(String rawLine) {
    if (_currentSession == null) return;
    AppLogger.info('SessionEngine: Processing unsolicited CUSD line: $rawLine');
    final parsed = UssdResponse.fromRaw(rawLine);
    final updated = _processUssdResponse(_currentSession!, parsed);
    _emit(updated);
  }

  UssdSessionData _processUssdResponse(UssdSessionData session, UssdResponse response) {
    final netStep = SessionEngineStep(
      content: response.cleanText,
      isFromNetwork: true,
      detectedOptions: response.options,
    );
    final updatedHistory = List<SessionEngineStep>.from(session.history)..add(netStep);

    if (response.isWaitingUser) {
      final hasMenuOptions = response.options.isNotEmpty;
      return session.copyWith(
        state: hasMenuOptions ? UssdEngineState.menuPresented : UssdEngineState.userInputRequired,
        history: updatedHistory,
        currentPrompt: response.cleanText,
        currentOptions: response.options,
      );
    } else {
      return session.copyWith(
        state: response.isSuccess ? UssdEngineState.completed : UssdEngineState.error,
        history: updatedHistory,
        currentPrompt: response.cleanText,
        currentOptions: [],
        transactionRef: response.transactionRef,
        errorMessage: response.error,
      );
    }
  }

  /// Cancels active session
  void cancelSession() {
    if (_currentSession != null) {
      // Send AT+CUSD=2 to terminate on modem
      modemService.sendRaw('AT+CUSD=2', timeout: const Duration(seconds: 2));
      _emit(_currentSession!.copyWith(state: UssdEngineState.cancelled));
    }
  }

  void dispose() {
    _unsolicitedSub?.cancel();
    _stateController.close();
  }
}
