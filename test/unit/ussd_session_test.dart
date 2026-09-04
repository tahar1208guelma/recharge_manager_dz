import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/ussd/gsm_modem_service.dart';
import 'package:recharge_manager_dz/services/ussd/ussd_session_manager.dart';

void main() {
  group('Interactive USSD Session Manager Tests', () {
    test('Should start session, receive SIM prompt, and wait for user confirmation', () async {
      final sessionManager = UssdSessionManager(modemService: GsmModemService());

      final state = await sessionManager.startSession(
        operator: OperatorType.mobilis,
        ussdCode: '*630*0661123456*04*500*11111#',
      );

      expect(state.isWaitingUser, true);
      expect(state.currentPrompt != null, true);
      expect(state.currentPrompt!.contains('تأكيد') || state.currentPrompt!.contains('Confirmer'), true);
      expect(state.currentOptions.isNotEmpty, true);
    });

    test('Should reply with 1 and complete session with transaction reference', () async {
      final sessionManager = UssdSessionManager(modemService: GsmModemService());

      await sessionManager.startSession(
        operator: OperatorType.mobilis,
        ussdCode: '*630*0661123456*04*500*11111#',
      );

      final nextState = await sessionManager.sendReply('1');
      expect(nextState.isCompleted, true);
      expect(nextState.transactionRef != null, true);
      expect(nextState.currentPrompt!.contains('بنجاح') || nextState.currentPrompt!.contains('reussie'), true);
    });

    test('Should reply with 2 and cancel session cleanly', () async {
      final sessionManager = UssdSessionManager(modemService: GsmModemService());

      await sessionManager.startSession(
        operator: OperatorType.mobilis,
        ussdCode: '*630*0661123456*04*500*11111#',
      );

      final nextState = await sessionManager.sendReply('2');
      expect(nextState.status.name, 'cancelled');
    });
  });
}
