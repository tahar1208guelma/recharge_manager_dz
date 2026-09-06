import 'dart:async';
import '../core/constants/operator_constants.dart';
import '../modem/modem_service.dart';
import 'session_engine.dart';

class UssdService {
  final ModemService modemService;
  late final SessionEngine sessionEngine;

  UssdService({required this.modemService}) {
    sessionEngine = SessionEngine(modemService: modemService);
  }

  Stream<UssdSessionData> get sessionStateStream => sessionEngine.stateStream;
  UssdSessionData? get currentSession => sessionEngine.currentSession;

  /// Starts a USSD interaction (e.g. Flexy, Balance query, Internet offer)
  Future<UssdSessionData> executeSession({
    required OperatorType operator,
    required String ussdCode,
  }) {
    return sessionEngine.startSession(operator: operator, ussdCode: ussdCode);
  }

  /// Sends user selection or input
  Future<UssdSessionData> reply(String input) {
    return sessionEngine.sendReply(input);
  }

  /// Cancels active session
  void cancel() {
    sessionEngine.cancelSession();
  }

  void dispose() {
    sessionEngine.dispose();
  }
}
